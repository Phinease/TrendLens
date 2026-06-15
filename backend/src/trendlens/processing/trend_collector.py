"""Google Trends data collection using pytrends-modern with Clash proxy rotation."""

from __future__ import annotations

import asyncio
import random
from typing import Literal

import structlog

from trendlens.config import AppConfig
from trendlens.constants import (
    TREND_GOOGLE_MAX_KW_PER_REQUEST,
    TREND_GOOGLE_RATE_LIMIT_SECONDS,
    TREND_GOOGLE_TIMEFRAME,
    TREND_GOOGLE_SPARSE_THRESHOLD,
    TREND_GOOGLE_MISS_STREAK_RETIRE,
)
from trendlens.storage.client import SupabaseClient
from trendlens.storage.trend_store import (
    get_keywords_needing_query,
    mark_keyword_no_trend_data,
    update_keyword_query_stats,
    upsert_trend_data,
)

log = structlog.get_logger()

# --------------- Clash proxy rotation ---------------

_CLASH_SOCKET = "/tmp/verge/verge-mihomo.sock"
_CLASH_SELECTOR = "Proxies"  # the selector group that routes Google traffic


async def _get_clash_nodes() -> list[str]:
    """Fetch usable proxy node names from Clash API."""
    import os
    if not os.path.exists(_CLASH_SOCKET):
        return []
    try:
        import httpx
        async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=_CLASH_SOCKET)) as c:
            resp = await c.get(f"http://localhost/proxies/{_CLASH_SELECTOR}", timeout=3)
            data = resp.json()
            nodes = [
                n for n in data.get("all", [])
                if not any(n.startswith(p) for p in ("🎯", "♻", "⏳", "DIRECT", "REJECT"))
                and "Panel" not in n
            ]
            return nodes
    except Exception as exc:
        log.warning("clash.list_nodes_error", error=str(exc))
        return []


async def _switch_clash_node(node: str) -> bool:
    """Switch the Clash selector to a specific node. Returns success."""
    try:
        import httpx
        async with httpx.AsyncClient(transport=httpx.AsyncHTTPTransport(uds=_CLASH_SOCKET)) as c:
            resp = await c.put(
                f"http://localhost/proxies/{_CLASH_SELECTOR}",
                json={"name": node},
                timeout=3,
            )
            return resp.status_code == 204
    except Exception as exc:
        log.warning("clash.switch_error", node=node, error=str(exc))
        return False


# --------------- Google Trends query ---------------

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


def _resolve_resolution(timeframe: str) -> str:
    """Map timeframe string to resolution label for storage."""
    if timeframe.startswith("now") and "7-d" in timeframe:
        return "hourly"
    if timeframe.startswith("now") and "1-H" in timeframe:
        return "minute"
    return "daily"


async def _query_google_trends(
    keywords: list[str],
    timeframe: str,
    geo: str,
    language: str,
    proxy_url: str | None = None,
) -> tuple[dict[str, list[dict]], TrendQueryErrorKind | None]:
    """Query Google Trends via optional proxy."""
    TrendReq = None
    try:
        from pytrends_modern import TrendReq as ModernTrendReq
        TrendReq = ModernTrendReq
    except ImportError:
        pass

    if TrendReq is None:
        try:
            from pytrends.request import TrendReq as ClassicTrendReq
            TrendReq = ClassicTrendReq
        except ImportError:
            log.error("trend_collector.no_pytrends_library")
            return {}, "unknown"

    _TrendReq = TrendReq

    def _sync_query() -> dict[str, list[dict]]:
        kwargs: dict = {
            "hl": language,
            "geo": geo,
            "timeout": (10, 25),
            "retries": 3,
            "backoff_factor": 0.5,
        }
        if proxy_url:
            kwargs["proxies"] = {"https": proxy_url}

        pytrends = _TrendReq(**kwargs)
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


# --------------- Main collection loop ---------------

async def collect_trend_data(
    client: SupabaseClient,
    cfg: AppConfig,
    *,
    max_batches: int = 20,
) -> int:
    """Query Google Trends for pending keywords with Clash node rotation."""
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
    timeframe = TREND_GOOGLE_TIMEFRAME
    resolution = _resolve_resolution(timeframe)

    # Set up proxy rotation via Clash
    clash_nodes = await _get_clash_nodes()
    use_proxy = bool(clash_nodes)
    proxy_url = "http://127.0.0.1:7897" if use_proxy else None
    if use_proxy:
        random.shuffle(clash_nodes)
        log.info("trend_collector.clash_rotation_enabled", nodes=len(clash_nodes))
    node_idx = 0

    total_stored = 0
    batches_run = 0
    current_batch_size = TREND_GOOGLE_MAX_KW_PER_REQUEST
    consecutive_429 = 0

    i = 0
    while i < len(keywords):
        if batches_run >= max_batches:
            break

        # Rotate Clash node before each batch (or on 429)
        if use_proxy:
            node = clash_nodes[node_idx % len(clash_nodes)]
            switched = await _switch_clash_node(node)
            if switched:
                log.info("trend_collector.node_switch", node=node)
                await asyncio.sleep(1)  # brief settle after switch
            node_idx += 1

        batch = keywords[i : i + current_batch_size]
        kw_texts = [kw["keyword"] for kw in batch]

        log.info(
            "trend_collector.batch_start",
            batch=batches_run + 1,
            batch_size=len(batch),
            keywords=kw_texts,
        )

        results, error_kind = await _query_google_trends(
            kw_texts, timeframe, geo, language, proxy_url=proxy_url,
        )
        batches_run += 1

        if error_kind is not None:
            if error_kind == "rate_limited":
                consecutive_429 += 1
            next_batch_size = max(1, current_batch_size - 1)
            log.warning(
                "trend_collector.batch_failed",
                batch=batches_run,
                batch_size=len(batch),
                error_kind=error_kind,
                retry_batch_size=next_batch_size,
                consecutive_429=consecutive_429,
            )
            current_batch_size = next_batch_size

            # On rate limit with proxy rotation: switch node and use shorter delay
            if use_proxy and error_kind == "rate_limited":
                wait = random.randint(5, 15)
            else:
                wait = max(30, TREND_GOOGLE_RATE_LIMIT_SECONDS + random.randint(-15, 15))

            if batches_run < max_batches:
                log.debug("trend_collector.rate_limit_wait", seconds=wait)
                await asyncio.sleep(wait)
            continue

        # Success — reset 429 counter
        consecutive_429 = 0

        # Store results and update stats.
        upsert_rows = []
        for kw_row in batch:
            kid = kw_row["keyword_id"]
            kw_text = kw_row["keyword"]
            points = results.get(kw_text, [])

            hit_rate = 1.0 if points else 0.0
            old_rate = kw_row.get("query_hit_rate", 0.0) or 0.0
            new_rate = old_rate * 0.7 + hit_rate * 0.3

            old_streak = kw_row.get("query_miss_streak", 0) or 0

            if points and len(points) < TREND_GOOGLE_SPARSE_THRESHOLD:
                log.info(
                    "trend_collector.sparse_skip",
                    keyword=kw_text,
                    points=len(points),
                )
                await update_keyword_query_stats(client, kid, new_rate, old_streak)
                continue

            if points:
                new_streak = 0
            else:
                new_streak = old_streak + 1

            await update_keyword_query_stats(client, kid, new_rate, new_streak)

            if new_streak >= TREND_GOOGLE_MISS_STREAK_RETIRE:
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

        # With proxy rotation: shorter delay between successful batches
        if batches_run < max_batches and i < len(keywords):
            if use_proxy:
                wait = random.randint(10, 25)
            else:
                wait = max(30, TREND_GOOGLE_RATE_LIMIT_SECONDS + random.randint(-15, 15))
            log.debug("trend_collector.rate_limit_wait", seconds=wait)
            await asyncio.sleep(wait)

    log.info(
        "trend_collector.done",
        batches=batches_run,
        keywords_queried=min(len(keywords), max_batches * TREND_GOOGLE_MAX_KW_PER_REQUEST),
        keywords_stored=total_stored,
        proxy_rotation=use_proxy,
    )
    return total_stored
