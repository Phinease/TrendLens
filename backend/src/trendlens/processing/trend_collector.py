"""Google Trends data collection using pytrends."""

from __future__ import annotations

import asyncio

import structlog

from trendlens.config import AppConfig
from trendlens.constants import (
    TREND_GOOGLE_MAX_KW_PER_REQUEST,
    TREND_GOOGLE_RATE_LIMIT_SECONDS,
    TREND_GOOGLE_TIMEFRAME,
)
from trendlens.storage.client import SupabaseClient
from trendlens.storage.trend_store import (
    get_keywords_needing_query,
    update_keyword_query_stats,
    upsert_trend_data,
)

log = structlog.get_logger()


async def _query_google_trends(
    keywords: list[str],
    timeframe: str,
    geo: str,
    language: str,
) -> dict[str, list[dict]]:
    """Fallback: use sync pytrends via asyncio.to_thread."""
    try:
        from pytrends.request import TrendReq
    except ImportError:
        log.error("trend_collector.no_pytrends_library")
        return {}

    def _sync_query() -> dict[str, list[dict]]:
        pytrends = TrendReq(hl=language)
        pytrends.build_payload(keywords, timeframe=timeframe, geo=geo)
        df = pytrends.interest_over_time()
        if df is None or df.empty:
            return {}
        result: dict[str, list[dict]] = {}
        for kw in keywords:
            if kw not in df.columns:
                continue
            points = []
            for ts, row in df.iterrows():
                val = int(row[kw])
                if val > 0:
                    points.append({"timestamp": ts.isoformat(), "value": val})
            if points:
                result[kw] = points
        return result

    try:
        return await asyncio.to_thread(_sync_query)
    except Exception as exc:
        log.error("trend_collector.sync_query_error", error=str(exc))
        return {}


def _determine_timeframe(last_queried_at: str | None) -> tuple[str, str]:
    """Choose timeframe and resolution based on whether keyword was queried before."""
    if last_queried_at is None:
        # New keyword: get 7 days of hourly data
        return TREND_GOOGLE_TIMEFRAME, "hourly"
    # Existing keyword: still use 7-day window to get fresh data
    return TREND_GOOGLE_TIMEFRAME, "hourly"


async def collect_trend_data(
    client: SupabaseClient,
    cfg: AppConfig,
    *,
    max_batches: int = 20,
) -> int:
    """Query Google Trends for pending keywords. Returns count of data points stored."""
    keywords = await get_keywords_needing_query(
        client,
        since_hours=1,
        limit=max_batches * TREND_GOOGLE_MAX_KW_PER_REQUEST,
    )

    if not keywords:
        log.info("trend_collector.no_keywords_pending")
        return 0

    geo = cfg.trend.google_geo
    language = cfg.trend.google_language
    total_stored = 0
    batches_run = 0

    for i in range(0, len(keywords), TREND_GOOGLE_MAX_KW_PER_REQUEST):
        if batches_run >= max_batches:
            break

        batch = keywords[i : i + TREND_GOOGLE_MAX_KW_PER_REQUEST]
        kw_texts = [kw["keyword"] for kw in batch]
        timeframe, resolution = _determine_timeframe(batch[0].get("last_queried_at"))

        log.info("trend_collector.batch_start", batch=batches_run + 1, keywords=kw_texts)

        results = await _query_google_trends(kw_texts, timeframe, geo, language)

        # Store results (one row per keyword with array columns) and update stats
        upsert_rows = []
        for kw_row in batch:
            kid = kw_row["keyword_id"]
            kw_text = kw_row["keyword"]
            points = results.get(kw_text, [])

            hit_rate = 1.0 if points else 0.0
            old_rate = kw_row.get("query_hit_rate", 0.0) or 0.0
            new_rate = old_rate * 0.7 + hit_rate * 0.3

            await update_keyword_query_stats(client, kid, new_rate)

            if points:
                upsert_rows.append({
                    "keyword_id": kid,
                    "timestamps": [pt["timestamp"] for pt in points],
                    "trend_values": [pt["value"] for pt in points],
                    "data_source": "google_trends",
                    "resolution": resolution,
                    "geo": geo,
                })

        if upsert_rows:
            stored = await upsert_trend_data(client, upsert_rows)
            total_stored += stored

        batches_run += 1

        # Rate limit: wait between batches
        if batches_run < max_batches and i + TREND_GOOGLE_MAX_KW_PER_REQUEST < len(keywords):
            log.debug("trend_collector.rate_limit_wait", seconds=TREND_GOOGLE_RATE_LIMIT_SECONDS)
            await asyncio.sleep(TREND_GOOGLE_RATE_LIMIT_SECONDS)

    log.info(
        "trend_collector.done",
        batches=batches_run,
        keywords_queried=min(len(keywords), max_batches * TREND_GOOGLE_MAX_KW_PER_REQUEST),
        keywords_stored=total_stored,
    )
    return total_stored
