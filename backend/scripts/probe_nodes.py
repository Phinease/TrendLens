"""Probe all Clash regions: 1 batch per region, report success rates."""

from __future__ import annotations

import asyncio
import json
import random
import sys
import time

import httpx

CLASH_SOCKET = "/tmp/verge/verge-mihomo.sock"
SELECTOR = "Proxies"
PROXY_URL = "http://127.0.0.1:7897"
SETTLE_SECONDS = 2  # wait after node switch
BATCH_DELAY = 3     # wait between regions


async def clash_get_nodes() -> list[str]:
    async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=CLASH_SOCKET)) as c:
        resp = await c.get(f"http://localhost/proxies/{SELECTOR}", timeout=5)
        data = resp.json()
        return [
            n for n in data.get("all", [])
            if not any(n.startswith(p) for p in ("🎯", "♻", "⏳", "DIRECT", "REJECT"))
            and "Panel" not in n
        ]


async def clash_switch(node: str) -> bool:
    async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=CLASH_SOCKET)) as c:
        resp = await c.put(f"http://localhost/proxies/{SELECTOR}", json={"name": node}, timeout=5)
        return resp.status_code == 204


def query_trends(keywords: list[str]) -> tuple[dict, str | None]:
    """Synchronous pytrends query via Clash proxy. Returns (results, error)."""
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
            return {}, None  # success but no data
        result = {}
        for kw in keywords:
            if kw in df.columns:
                pts = [(ts.isoformat(), int(row[kw])) for ts, row in df.iterrows() if int(row[kw]) > 0]
                if pts:
                    result[kw] = len(pts)
        return result, None
    except Exception as exc:
        raw = str(exc).lower()
        if "429" in raw or "too many" in raw:
            return {}, "429"
        if "ssl" in raw or "eof" in raw:
            return {}, "ssl"
        if "timeout" in raw:
            return {}, "timeout"
        return {}, str(exc)[:80]


async def main():
    # Load keywords from DB via direct REST
    sys.path.insert(0, "src")
    from trendlens.config import load_config
    cfg = load_config()

    async with httpx.AsyncClient() as hc:
        resp = await hc.get(
            f"{cfg.supabase_url}/rest/v1/trend_keywords",
            params={
                "select": "keyword",
                "is_active": "eq.true",
                "no_trend_data": "eq.false",
                "last_queried_at": "is.null",
                "order": "keyword_id",
                "limit": "200",
            },
            headers={
                "apikey": cfg.service_role_key,
                "Authorization": f"Bearer {cfg.service_role_key}",
            },
            timeout=10,
        )
        rows = resp.json()

    if not rows:
        print("No keywords pending!")
        return

    kw_pool = [r["keyword"] for r in rows]
    random.shuffle(kw_pool)

    # Group nodes by region
    nodes = await clash_get_nodes()
    regions: dict[str, list[str]] = {}
    for n in nodes:
        if "|" in n:
            region = n.split("|")[0].strip()
        else:
            region = "Other"
        regions.setdefault(region, []).append(n)

    print(f"=== Node Probe: {len(regions)} regions, {len(nodes)} nodes, {len(kw_pool)} keywords ===\n")

    results = []
    kw_idx = 0

    for region, region_nodes in sorted(regions.items()):
        node = random.choice(region_nodes)
        batch = kw_pool[kw_idx : kw_idx + 5]
        if not batch:
            break
        kw_idx += 5

        # Switch node
        ok = await clash_switch(node)
        if not ok:
            print(f"  {region:<20} SWITCH FAILED")
            results.append({"region": region, "node": node, "status": "switch_fail"})
            continue

        await asyncio.sleep(SETTLE_SECONDS)

        # Query
        t0 = time.time()
        data, err = await asyncio.to_thread(query_trends, batch)
        elapsed = time.time() - t0

        if err:
            status = f"FAIL ({err})"
            results.append({"region": region, "node": node, "status": err, "time": elapsed})
        else:
            total_pts = sum(data.values())
            hits = len(data)
            status = f"OK  {hits}/5 keywords, {total_pts} total points"
            results.append({
                "region": region, "node": node, "status": "ok",
                "hits": hits, "points": total_pts, "time": elapsed,
            })

        print(f"  {region:<20} {node:<35} {elapsed:5.1f}s  {status}")
        await asyncio.sleep(BATCH_DELAY)

    # Summary
    print("\n=== Summary ===")
    ok_regions = [r for r in results if r["status"] == "ok"]
    fail_regions = [r for r in results if r["status"] != "ok"]
    total_points = sum(r.get("points", 0) for r in ok_regions)
    total_hits = sum(r.get("hits", 0) for r in ok_regions)

    print(f"Regions tested:  {len(results)}")
    print(f"Successful:      {len(ok_regions)}")
    print(f"Failed:          {len(fail_regions)}")
    print(f"Keywords w/data: {total_hits}")
    print(f"Total points:    {total_points}")
    print(f"Keywords tested: {kw_idx}")

    if fail_regions:
        print(f"\nFailed regions:")
        for r in fail_regions:
            print(f"  {r['region']:<20} {r['status']}")

    if ok_regions:
        print(f"\nWorking regions (by points):")
        for r in sorted(ok_regions, key=lambda x: x.get("points", 0), reverse=True):
            print(f"  {r['region']:<20} {r.get('hits',0)}/5 hits, {r.get('points',0)} pts, {r.get('time',0):.1f}s")

    # Estimate
    remaining = 4355  # pending keywords
    kw_per_region = 5
    working_regions = len(ok_regions)
    if working_regions > 0:
        kw_per_full_rotation = working_regions * kw_per_region
        rotations_needed = remaining / kw_per_full_rotation
        print(f"\n=== Estimate ===")
        print(f"Working regions:       {working_regions}")
        print(f"Keywords per rotation: {kw_per_full_rotation}")
        print(f"Remaining keywords:    {remaining}")
        print(f"Rotations needed:      {rotations_needed:.1f}")
        avg_time = sum(r.get("time", 5) for r in ok_regions) / working_regions
        time_per_rotation = working_regions * (avg_time + BATCH_DELAY + SETTLE_SECONDS)
        total_hours = rotations_needed * time_per_rotation / 3600
        print(f"Estimated time:        {total_hours:.1f} hours")


if __name__ == "__main__":
    asyncio.run(main())
