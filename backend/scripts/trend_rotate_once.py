#!/usr/bin/env python3
"""Single rotation of trend collection across all Clash regions.

Designed to be called by launchd every 30 minutes. Each run:
- Fetches ~100 pending keywords (20 regions × 5 per batch)
- Rotates through all working Clash proxy nodes
- Stores results to Supabase
- Logs to structured log file

Exit codes: 0 = success, 1 = error, 2 = no work (all keywords done)
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

# --------------- Config ---------------

CLASH_SOCKET = "/tmp/verge/verge-mihomo.sock"
SELECTOR = "Proxies"
PROXY_URL = "http://127.0.0.1:7897"
BATCH_SIZE = 5
SETTLE_SECONDS = 2
INTER_BATCH_DELAY = 3
SPARSE_THRESHOLD = 5
MISS_STREAK_RETIRE = 3

FAILED_REGIONS = {"🇪🇸 ES", "🇮🇩 ID", "🇳🇴 NO", "🇺🇦 UA"}

LOG_DIR = Path(__file__).resolve().parents[1] / "logs" / "rotate"
LOG_DIR.mkdir(parents=True, exist_ok=True)

# --------------- Logging ---------------

logger = logging.getLogger("trend_rotate")
logger.setLevel(logging.INFO)

# File handler — append to daily log
log_file = LOG_DIR / f"rotate_{datetime.now().strftime('%Y%m%d')}.log"
fh = logging.FileHandler(log_file, encoding="utf-8")
fh.setFormatter(logging.Formatter("%(asctime)s %(levelname)-5s %(message)s", datefmt="%H:%M:%S"))
logger.addHandler(fh)

# Stdout for launchd capture
sh = logging.StreamHandler(sys.stdout)
sh.setFormatter(logging.Formatter("%(asctime)s %(levelname)-5s %(message)s", datefmt="%H:%M:%S"))
logger.addHandler(sh)

# --------------- Clash ---------------

async def clash_get_regions() -> dict[str, list[str]]:
    if not os.path.exists(CLASH_SOCKET):
        return {}
    try:
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
    except Exception as exc:
        logger.warning(f"Clash API error: {exc}")
        return {}


async def clash_switch(node: str) -> bool:
    try:
        async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=CLASH_SOCKET)) as c:
            resp = await c.put(f"http://localhost/proxies/{SELECTOR}", json={"name": node}, timeout=5)
            return resp.status_code == 204
    except Exception:
        return False


# --------------- Supabase helpers ---------------

async def supa_request(method: str, url: str, headers: dict, retries: int = 3, **kwargs):
    for attempt in range(retries):
        try:
            async with httpx.AsyncClient(proxy=PROXY_URL, timeout=15) as hc:
                return await getattr(hc, method)(url, headers=headers, **kwargs)
        except (httpx.ConnectError, httpx.ReadError, httpx.WriteError):
            if attempt < retries - 1:
                await asyncio.sleep(2)
    return None


# --------------- Google Trends query ---------------

def query_trends(keywords: list[str]) -> tuple[dict[str, list[dict]], str | None]:
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
            if len(points) >= SPARSE_THRESHOLD:
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


# --------------- Main ---------------

async def main():
    from trendlens.config import load_config
    cfg = load_config()
    headers = {
        "apikey": cfg.service_role_key,
        "Authorization": f"Bearer {cfg.service_role_key}",
        "Content-Type": "application/json",
    }

    # 1. Check Clash
    regions = await clash_get_regions()
    if not regions:
        logger.error("Clash not available — skipping this run")
        return 1

    region_names = sorted(regions.keys())
    logger.info(f"Regions: {len(region_names)}, Nodes: {sum(len(v) for v in regions.values())}")

    # 2. Fetch pending keywords
    resp = await supa_request("get", f"{cfg.supabase_url}/rest/v1/trend_keywords", headers, params={
        "select": "keyword_id,keyword,query_miss_streak",
        "is_active": "eq.true",
        "no_trend_data": "eq.false",
        "or": f"(last_queried_at.is.null,last_queried_at.lt.{datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S')})",
        "order": "last_queried_at.asc.nullsfirst",
        "limit": str(len(region_names) * BATCH_SIZE),
    })

    if not resp or resp.status_code != 200:
        logger.error("Failed to fetch keywords from Supabase")
        return 1

    keywords = resp.json()
    if not keywords:
        logger.info("No pending keywords — all done!")
        return 2

    logger.info(f"Keywords this run: {len(keywords)}")

    # 3. Single rotation
    random.shuffle(keywords)
    region_order = list(region_names)
    random.shuffle(region_order)

    kw_idx = 0
    stored = 0
    queried = 0
    ok_count = 0
    fail_count = 0
    t_start = time.time()

    for region in region_order:
        if kw_idx >= len(keywords):
            break

        node = random.choice(regions[region])
        batch = keywords[kw_idx : kw_idx + BATCH_SIZE]
        kw_texts = [kw["keyword"] for kw in batch]

        try:
            ok = await clash_switch(node)
        except Exception:
            ok = False
        if not ok:
            continue
        await asyncio.sleep(SETTLE_SECONDS)

        try:
            data, err = await asyncio.to_thread(query_trends, kw_texts)
        except Exception as exc:
            data, err = {}, str(exc)[:40]

        if err:
            fail_count += 1
            logger.debug(f"  {region:<16} {node:<30} FAIL({err})")
            if err != "429":
                kw_idx += len(batch)
                queried += len(batch)
            await asyncio.sleep(INTER_BATCH_DELAY)
            continue

        ok_count += 1
        hits = len(data)
        queried += len(batch)
        kw_idx += len(batch)

        # Store results
        upsert_rows = []
        now = datetime.now(timezone.utc).isoformat()
        for kw_row in batch:
            kid = kw_row["keyword_id"]
            points = data.get(kw_row["keyword"])
            if points:
                upsert_rows.append({
                    "keyword_id": kid,
                    "data_source": "google_trends",
                    "resolution": "daily",
                    "geo": "",
                    "timestamps": [p["timestamp"] for p in points],
                    "trend_values": [p["value"] for p in points],
                    "queried_at": now,
                })
                await supa_request("patch", f"{cfg.supabase_url}/rest/v1/trend_keywords",
                    headers, params={"keyword_id": f"eq.{quote(kid)}"},
                    json={"last_queried_at": now, "query_miss_streak": 0})
            else:
                old_streak = kw_row.get("query_miss_streak", 0) or 0
                new_streak = old_streak + 1
                body = {"last_queried_at": now, "query_miss_streak": new_streak}
                if new_streak >= MISS_STREAK_RETIRE:
                    body["no_trend_data"] = True
                await supa_request("patch", f"{cfg.supabase_url}/rest/v1/trend_keywords",
                    headers, params={"keyword_id": f"eq.{quote(kid)}"},
                    json=body)

        if upsert_rows:
            upsert_headers = {**headers, "Prefer": "resolution=merge-duplicates"}
            r = await supa_request("post", f"{cfg.supabase_url}/rest/v1/trend_data",
                upsert_headers, params={"on_conflict": "keyword_id,data_source,resolution,geo"},
                json=upsert_rows)
            if r and r.status_code in (200, 201):
                stored += len(upsert_rows)

        logger.info(f"  {region:<16} {node:<30} OK {hits}/{len(batch)} kw, stored={stored}")
        await asyncio.sleep(INTER_BATCH_DELAY)

    elapsed = time.time() - t_start
    logger.info(
        f"DONE queried={queried} stored={stored} ok={ok_count} fail={fail_count} "
        f"elapsed={elapsed:.0f}s"
    )

    # Write a summary JSON for monitoring
    summary = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "queried": queried, "stored": stored,
        "ok_regions": ok_count, "fail_regions": fail_count,
        "elapsed_seconds": round(elapsed),
    }
    summary_file = LOG_DIR / "last_run.json"
    summary_file.write_text(json.dumps(summary, indent=2))

    return 0


if __name__ == "__main__":
    code = asyncio.run(main())
    sys.exit(code or 0)
