"""Full trend collection with Clash node rotation across all working regions."""

from __future__ import annotations

import asyncio
import random
import sys
import time
from datetime import datetime, timezone

import httpx

sys.path.insert(0, "src")

CLASH_SOCKET = "/tmp/verge/verge-mihomo.sock"
SELECTOR = "Proxies"
PROXY_URL = "http://127.0.0.1:7897"

# Regions ranked by quality from probe results (exclude failed: ES, ID, NO, UA, SG)
FAILED_REGIONS = {"🇪🇸 ES", "🇮🇩 ID", "🇳🇴 NO", "🇺🇦 UA"}
BATCH_SIZE = 5
SETTLE_SECONDS = 2
INTER_BATCH_DELAY = 3


async def clash_get_nodes() -> dict[str, list[str]]:
    async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=CLASH_SOCKET)) as c:
        resp = await c.get(f"http://localhost/proxies/{SELECTOR}", timeout=5)
        data = resp.json()
    regions: dict[str, list[str]] = {}
    for n in data.get("all", []):
        if any(n.startswith(p) for p in ("🎯", "♻", "⏳", "DIRECT", "REJECT")) or "Panel" in n:
            continue
        region = n.split("|")[0].strip() if "|" in n else "Other"
        if region not in FAILED_REGIONS:
            regions.setdefault(region, []).append(n)
    return regions


async def clash_switch(node: str) -> bool:
    try:
        async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=CLASH_SOCKET)) as c:
            resp = await c.put(f"http://localhost/proxies/{SELECTOR}", json={"name": node}, timeout=5)
            return resp.status_code == 204
    except Exception:
        return False


def query_and_process(keywords: list[str]) -> tuple[dict[str, list[dict]], str | None]:
    """Query Google Trends, return {keyword: [points]} and error."""
    try:
        from pytrends.request import TrendReq
    except ImportError:
        from pytrends_modern import TrendReq

    try:
        pt = TrendReq(
            hl="zh-CN", geo="", timeout=(10, 20),
            retries=1, backoff_factor=0.1,
            proxies={"https": PROXY_URL},
        )
        pt.build_payload(keywords, timeframe="today 3-m", geo="")
        df = pt.interest_over_time()
        if df is None or df.empty:
            return {}, None
        result = {}
        for kw in keywords:
            if kw not in df.columns:
                continue
            points = []
            for ts, row in df.iterrows():
                val = int(row[kw])
                if val > 0:
                    points.append({"timestamp": ts.isoformat(), "value": val})
            if len(points) >= 5:  # sparse threshold
                result[kw] = points
        return result, None
    except Exception as exc:
        raw = str(exc).lower()
        if "429" in raw or "too many" in raw:
            return {}, "429"
        if "ssl" in raw or "eof" in raw:
            return {}, "ssl"
        if "timeout" in raw:
            return {}, "timeout"
        return {}, str(exc)[:60]


async def fetch_pending_keywords(cfg, limit: int = 5000) -> list[dict]:
    async with httpx.AsyncClient(proxy=PROXY_URL) as hc:
        resp = await hc.get(
            f"{cfg.supabase_url}/rest/v1/trend_keywords",
            params={
                "select": "keyword_id,keyword,query_miss_streak",
                "is_active": "eq.true",
                "no_trend_data": "eq.false",
                "or": "(last_queried_at.is.null,last_queried_at.lt." +
                      (datetime.now(timezone.utc)).strftime("%Y-%m-%dT%H:%M:%S") + ")",
                "order": "last_queried_at.asc.nullsfirst",
                "limit": str(limit),
            },
            headers={
                "apikey": cfg.service_role_key,
                "Authorization": f"Bearer {cfg.service_role_key}",
            },
            timeout=15,
        )
        return resp.json()


def _supa_headers(cfg) -> dict:
    return {
        "apikey": cfg.service_role_key,
        "Authorization": f"Bearer {cfg.service_role_key}",
        "Content-Type": "application/json",
    }


async def _supa_request(method: str, url: str, cfg, retries: int = 3, **kwargs):
    """Make a Supabase request with retry on proxy connection errors."""
    for attempt in range(retries):
        try:
            async with httpx.AsyncClient(proxy=PROXY_URL, timeout=15) as hc:
                resp = await getattr(hc, method)(url, headers=_supa_headers(cfg), **kwargs)
                return resp
        except (httpx.ConnectError, httpx.ReadError, httpx.WriteError) as exc:
            if attempt < retries - 1:
                await asyncio.sleep(2)
            else:
                print(f"  [WARN] Supabase request failed after {retries} retries: {exc}")
                return None


async def store_results(cfg, upsert_rows: list[dict]) -> int:
    if not upsert_rows:
        return 0
    now = datetime.now(timezone.utc).isoformat()
    data_rows = [{
        "keyword_id": r["keyword_id"],
        "data_source": "google_trends",
        "resolution": "daily",
        "geo": "",
        "timestamps": r["timestamps"],
        "trend_values": r["trend_values"],
        "queried_at": now,
    } for r in upsert_rows]

    resp = await _supa_request(
        "post",
        f"{cfg.supabase_url}/rest/v1/trend_data",
        cfg,
        params={"on_conflict": "keyword_id,data_source,resolution,geo"},
        json=data_rows,
    )
    if resp and resp.status_code in (200, 201):
        return len(data_rows)
    return 0


async def update_keyword_stats(cfg, keyword_id: str, hit: bool, miss_streak: int):
    from urllib.parse import quote
    now = datetime.now(timezone.utc).isoformat()
    body = {"last_queried_at": now, "query_miss_streak": miss_streak}
    if miss_streak >= 3:
        body["no_trend_data"] = True
    await _supa_request(
        "patch",
        f"{cfg.supabase_url}/rest/v1/trend_keywords",
        cfg,
        params={"keyword_id": f"eq.{quote(keyword_id)}"},
        json=body,
    )


async def main():
    from trendlens.config import load_config
    cfg = load_config()

    regions = await clash_get_nodes()
    region_names = sorted(regions.keys())
    print(f"Working regions: {len(region_names)} ({sum(len(v) for v in regions.values())} nodes)")

    keywords = await fetch_pending_keywords(cfg, limit=5000)
    total_pending = len(keywords)
    print(f"Pending keywords: {total_pending}")

    if not keywords or not region_names:
        return

    random.shuffle(keywords)
    t_start = time.time()
    kw_idx = 0
    rotation = 0
    total_stored = 0
    total_queried = 0
    region_stats: dict[str, dict] = {r: {"ok": 0, "fail": 0, "pts": 0} for r in region_names}

    while kw_idx < len(keywords):
        rotation += 1
        rotation_stored = 0
        rotation_queried = 0

        # Shuffle node selection within each region per rotation
        region_order = list(region_names)
        random.shuffle(region_order)

        for region in region_order:
            if kw_idx >= len(keywords):
                break

            node = random.choice(regions[region])
            batch_kws = keywords[kw_idx : kw_idx + BATCH_SIZE]

            try:
                ok = await clash_switch(node)
            except Exception:
                ok = False
            if not ok:
                continue
            await asyncio.sleep(SETTLE_SECONDS)

            t0 = time.time()
            try:
                data, err = await asyncio.to_thread(
                    query_and_process, [kw["keyword"] for kw in batch_kws]
                )
            except Exception as exc:
                data, err = {}, str(exc)[:60]
            elapsed = time.time() - t0

            if err:
                region_stats[region]["fail"] += 1
                status = f"FAIL({err})"
                # On 429: mark this region as temporarily bad, skip to next
                if err == "429":
                    print(f"  {region:<16} {node:<30} {status}")
                    await asyncio.sleep(INTER_BATCH_DELAY)
                    continue
            else:
                region_stats[region]["ok"] += 1

                # Store successful results
                upsert_rows = []
                for kw_row in batch_kws:
                    kid = kw_row["keyword_id"]
                    kw_text = kw_row["keyword"]
                    points = data.get(kw_text)

                    if points:
                        upsert_rows.append({
                            "keyword_id": kid,
                            "timestamps": [p["timestamp"] for p in points],
                            "trend_values": [p["value"] for p in points],
                        })
                        await update_keyword_stats(cfg, kid, True, 0)
                        region_stats[region]["pts"] += len(points)
                    else:
                        old_streak = kw_row.get("query_miss_streak", 0) or 0
                        await update_keyword_stats(cfg, kid, False, old_streak + 1)

                stored = await store_results(cfg, upsert_rows)
                rotation_stored += stored
                total_stored += stored
                hits = len(data)
                status = f"OK {hits}/{len(batch_kws)} kw, {sum(len(v) for v in data.values())} pts"

            rotation_queried += len(batch_kws)
            total_queried += len(batch_kws)
            kw_idx += len(batch_kws)

            elapsed_total = time.time() - t_start
            remaining = len(keywords) - kw_idx
            rate = total_queried / elapsed_total * 3600 if elapsed_total > 0 else 0

            print(
                f"  {region:<16} {node:<30} {elapsed:4.1f}s  {status:<35} "
                f"[{kw_idx}/{len(keywords)} done, +{rotation_stored} stored, "
                f"ETA {remaining/rate*60:.0f}m]" if rate > 0 else ""
            )
            await asyncio.sleep(INTER_BATCH_DELAY)

        # End of rotation summary
        elapsed_total = time.time() - t_start
        print(
            f"\n--- Rotation {rotation} done | "
            f"Queried: {total_queried}/{len(keywords)} | "
            f"Stored: {total_stored} | "
            f"Elapsed: {elapsed_total/60:.1f}m ---\n"
        )

    # Final summary
    elapsed_total = time.time() - t_start
    print(f"\n{'='*60}")
    print(f"COMPLETE")
    print(f"  Total queried:  {total_queried}")
    print(f"  Total stored:   {total_stored}")
    print(f"  Hit rate:       {total_stored/total_queried*100:.1f}%" if total_queried else "")
    print(f"  Elapsed:        {elapsed_total/60:.1f} minutes")
    print(f"\nRegion performance:")
    for r in sorted(region_stats.keys(), key=lambda x: region_stats[x]["pts"], reverse=True):
        s = region_stats[r]
        if s["ok"] + s["fail"] > 0:
            print(f"  {r:<16} OK:{s['ok']:3d}  FAIL:{s['fail']:2d}  Points:{s['pts']:5d}")


if __name__ == "__main__":
    asyncio.run(main())
