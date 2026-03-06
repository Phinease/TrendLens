"""Trend keyword and data storage via PostgREST."""

from __future__ import annotations

from datetime import datetime, timezone
from urllib.parse import quote

import structlog

from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()

_BATCH_SIZE = 50


async def upsert_keywords(client: SupabaseClient, keywords: list[dict]) -> int:
    """Upsert trend_keywords rows. Returns count upserted."""
    if not keywords:
        return 0

    rows = []
    for kw in keywords:
        row: dict = {
            "keyword_id": kw["keyword_id"],
            "keyword": kw["keyword"],
            "language": kw.get("language", "zh"),
            "source": kw.get("source", "llm"),
        }
        if "embedding" in kw and kw["embedding"]:
            row["embedding"] = "[" + ",".join(str(v) for v in kw["embedding"]) + "]"
        rows.append(row)

    upserted = 0
    for i in range(0, len(rows), _BATCH_SIZE):
        batch = rows[i : i + _BATCH_SIZE]
        try:
            result = await client.insert(
                "trend_keywords", batch, upsert=True, on_conflict="keyword_id",
            )
            upserted += len(result)
        except Exception as exc:
            log.error("trend_store.upsert_keywords_error", batch_start=i, error=str(exc))

    log.info("trend_store.keywords_upserted", count=upserted)
    return upserted


async def upsert_topic_trend_links(client: SupabaseClient, links: list[dict]) -> int:
    """Upsert topic_trend_links rows. Returns count upserted."""
    if not links:
        return 0

    rows = [
        {
            "topic_key": lnk["topic_key"],
            "keyword_id": lnk["keyword_id"],
            "relevance": lnk.get("relevance", 1.0),
            "source": lnk.get("source", "llm"),
        }
        for lnk in links
    ]

    upserted = 0
    for i in range(0, len(rows), _BATCH_SIZE):
        batch = rows[i : i + _BATCH_SIZE]
        try:
            result = await client.insert(
                "topic_trend_links", batch,
                upsert=True, on_conflict="topic_key,keyword_id",
            )
            upserted += len(result)
        except Exception as exc:
            log.error("trend_store.upsert_links_error", batch_start=i, error=str(exc))

    log.info("trend_store.links_upserted", count=upserted)
    return upserted


async def upsert_trend_data(client: SupabaseClient, rows: list[dict]) -> int:
    """Upsert trend_data rows (array format). Each row stores a full time series per keyword.

    Expected row format: {keyword_id, timestamps: [...], trend_values: [...],
                          data_source?, resolution?, geo?}
    Returns count of rows upserted.
    """
    if not rows:
        return 0

    now = datetime.now(timezone.utc).isoformat()
    data_rows = [
        {
            "keyword_id": r["keyword_id"],
            "data_source": r.get("data_source", "google_trends"),
            "resolution": r.get("resolution", "hourly"),
            "geo": r.get("geo", ""),
            "timestamps": r["timestamps"],
            "trend_values": r["trend_values"],
            "queried_at": now,
        }
        for r in rows
    ]

    upserted = 0
    for i in range(0, len(data_rows), _BATCH_SIZE):
        batch = data_rows[i : i + _BATCH_SIZE]
        try:
            result = await client.insert(
                "trend_data", batch,
                upsert=True,
                on_conflict="keyword_id,data_source,resolution,geo",
            )
            upserted += len(result)
        except Exception as exc:
            log.error("trend_store.upsert_data_error", batch_start=i, error=str(exc))

    log.info("trend_store.data_upserted", count=upserted)
    return upserted


async def get_keywords_needing_query(
    client: SupabaseClient,
    since_hours: int = 1,
    limit: int = 100,
) -> list[dict]:
    """Get active keywords that haven't been queried recently, ordered by oldest first."""
    from datetime import timedelta

    cutoff = (datetime.now(timezone.utc) - timedelta(hours=since_hours)).strftime("%Y-%m-%dT%H:%M:%S")
    try:
        # Keywords never queried or queried more than since_hours ago
        rows = await client.select(
            "trend_keywords",
            "keyword_id,keyword,last_queried_at,query_hit_rate",
            (
                f"is_active=eq.true"
                f"&or=(last_queried_at.is.null,last_queried_at.lt.{quote(cutoff)})"
                f"&order=last_queried_at.asc.nullsfirst"
                f"&limit={limit}"
            ),
        )
        return rows
    except Exception as exc:
        log.error("trend_store.get_keywords_error", error=str(exc))
        return []


async def update_keyword_query_stats(
    client: SupabaseClient,
    keyword_id: str,
    hit_rate: float,
) -> None:
    """Update keyword's last_queried_at and query_hit_rate."""
    now = datetime.now(timezone.utc).isoformat()
    try:
        await client.update(
            "trend_keywords",
            {"last_queried_at": now, "query_hit_rate": hit_rate},
            f"keyword_id=eq.{quote(keyword_id)}",
        )
    except Exception as exc:
        log.error("trend_store.update_stats_error", keyword_id=keyword_id, error=str(exc))


async def cleanup_trend_data(client: SupabaseClient, retention_days: int = 90) -> None:
    """Delete stale trend_data rows and deactivate orphaned keywords."""
    from datetime import timedelta

    now = datetime.now(timezone.utc)

    # 1. Delete trend_data rows not refreshed within retention_days
    cutoff = (now - timedelta(days=retention_days)).isoformat()
    try:
        await client._http.delete(
            f"{client.rest_url}/trend_data?queried_at=lt.{cutoff}",
            headers=client._headers,
        )
        log.info("trend_store.stale_data_cleaned", cutoff=cutoff)
    except Exception as exc:
        log.error("trend_store.cleanup_error", error=str(exc))

    # 2. Deactivate keywords with no links for 30 days
    cutoff_30d = (now - timedelta(days=30)).isoformat()
    try:
        inactive = await client.select(
            "trend_keywords",
            "keyword_id",
            f"is_active=eq.true&last_queried_at=lt.{cutoff_30d}",
        )
        for kw in inactive:
            links = await client.select(
                "topic_trend_links",
                "keyword_id",
                f"keyword_id=eq.{quote(kw['keyword_id'])}&limit=1",
            )
            if not links:
                await client.update(
                    "trend_keywords",
                    {"is_active": False},
                    f"keyword_id=eq.{quote(kw['keyword_id'])}",
                )
        log.info("trend_store.deactivated_keywords", checked=len(inactive))
    except Exception as exc:
        log.warning("trend_store.deactivate_error", error=str(exc))
