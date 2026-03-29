"""Google Trends data collection using pytrends."""

from __future__ import annotations

import asyncio
from typing import Literal

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
    mark_keyword_no_trend_data,
    update_keyword_query_stats,
    upsert_trend_data,
)

log = structlog.get_logger()


TrendQueryErrorKind = Literal["rate_limited", "timeout", "ssl_eof", "unknown"]


def _classify_query_error(exc: Exception) -> TrendQueryErrorKind:
    """Classify pytrends/network failures into operational buckets."""
    raw = str(exc).lower()

    try:
        from pytrends import exceptions as pytrends_exceptions
        if isinstance(exc, pytrends_exceptions.TooManyRequestsError):
            return "rate_limited"
    except Exception:
        pass

    if "429" in raw or "quota limit" in raw or "too many requests" in raw:
        return "rate_limited"
    if "read timed out" in raw or "timeout" in raw:
        return "timeout"
    if "unexpected_eof_while_reading" in raw or "ssleoferror" in raw or "eof occurred in violation of protocol" in raw:
        return "ssl_eof"
    return "unknown"


async def _query_google_trends(
    keywords: list[str],
    timeframe: str,
    geo: str,
    language: str,
) -> tuple[dict[str, list[dict]], TrendQueryErrorKind | None]:
    """Query Google Trends and return results plus a classified error kind."""
    try:
        from pytrends.request import TrendReq
    except ImportError:
        log.error("trend_collector.no_pytrends_library")
        return {}, "unknown"

    def _sync_query() -> dict[str, list[dict]]:
        pytrends = TrendReq(
            hl=language,
            geo=geo,
            timeout=(10, 20),
        )
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
        return await asyncio.to_thread(_sync_query), None
    except Exception as exc:
        error_kind = _classify_query_error(exc)
        log.error("trend_collector.sync_query_error", error=str(exc), error_kind=error_kind)
        return {}, error_kind


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
    current_batch_size = TREND_GOOGLE_MAX_KW_PER_REQUEST

    i = 0
    while i < len(keywords):
        if batches_run >= max_batches:
            break

        batch = keywords[i : i + current_batch_size]
        kw_texts = [kw["keyword"] for kw in batch]
        timeframe, resolution = _determine_timeframe(batch[0].get("last_queried_at"))

        log.info(
            "trend_collector.batch_start",
            batch=batches_run + 1,
            batch_size=len(batch),
            keywords=kw_texts,
        )

        results, error_kind = await _query_google_trends(kw_texts, timeframe, geo, language)
        batches_run += 1

        if error_kind is not None:
            next_batch_size = max(1, current_batch_size - 1)
            log.warning(
                "trend_collector.batch_failed",
                batch=batches_run,
                batch_size=len(batch),
                error_kind=error_kind,
                retry_batch_size=next_batch_size,
            )
            current_batch_size = next_batch_size
            if batches_run < max_batches:
                log.debug("trend_collector.rate_limit_wait", seconds=TREND_GOOGLE_RATE_LIMIT_SECONDS)
                await asyncio.sleep(TREND_GOOGLE_RATE_LIMIT_SECONDS)
            continue

        # Store results and update stats.
        # Distinguish "confirmed no data" (successful query, keyword absent)
        # from "network error" (exception raised, cannot judge).
        upsert_rows = []
        for kw_row in batch:
            kid = kw_row["keyword_id"]
            kw_text = kw_row["keyword"]
            points = results.get(kw_text, [])

            hit_rate = 1.0 if points else 0.0
            old_rate = kw_row.get("query_hit_rate", 0.0) or 0.0
            new_rate = old_rate * 0.7 + hit_rate * 0.3

            old_streak = kw_row.get("query_miss_streak", 0) or 0
            if points:
                # Has data → reset miss streak
                new_streak = 0
            else:
                # Successful query but no data → increment miss streak
                new_streak = old_streak + 1

            await update_keyword_query_stats(client, kid, new_rate, new_streak)

            # Sparse data filter: ≤ 3 points in a 7-day window is not useful
            if points and len(points) <= 3:
                log.info(
                    "trend_collector.sparse_skip",
                    keyword=kw_text,
                    points=len(points),
                )
                # Treat as no useful data
                new_streak = old_streak + 1
                await update_keyword_query_stats(client, kid, new_rate, new_streak)
                points = []

            # Mark as permanently no-data after 2 consecutive confirmed misses
            if new_streak >= 2:
                await mark_keyword_no_trend_data(client, kid)
                log.info(
                    "trend_collector.keyword_retired",
                    keyword=kw_text,
                    miss_streak=new_streak,
                )

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

        current_batch_size = TREND_GOOGLE_MAX_KW_PER_REQUEST
        i += len(batch)

        # Rate limit: wait between batches
        if batches_run < max_batches and i < len(keywords):
            log.debug("trend_collector.rate_limit_wait", seconds=TREND_GOOGLE_RATE_LIMIT_SECONDS)
            await asyncio.sleep(TREND_GOOGLE_RATE_LIMIT_SECONDS)

    log.info(
        "trend_collector.done",
        batches=batches_run,
        keywords_queried=min(len(keywords), max_batches * TREND_GOOGLE_MAX_KW_PER_REQUEST),
        keywords_stored=total_stored,
    )
    return total_stored
