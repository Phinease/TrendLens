"""Topic UPSERT + heat_history append + off-list detection via PostgREST."""

from __future__ import annotations

from datetime import datetime, timezone
from urllib.parse import quote

import structlog

from trendlens.models import NormalizedTopic
from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


async def upsert_topics(client: SupabaseClient, topics: list[NormalizedTopic]) -> int:
    """Batch upsert topics and append heat history. Returns count upserted."""
    if not topics:
        return 0

    now = datetime.now(timezone.utc).isoformat()

    # Build topic rows
    topic_rows = []
    for t in topics:
        ts = t.fetched_at.isoformat() if t.fetched_at else now
        row: dict[str, object] = {
            "topic_key": t.topic_key,
            "platform_id": t.platform_id,
            "source_id": t.source_id,
            "title": t.title,
            "description": t.description,
            "link": t.link,
            "image_urls": t.image_urls or [],
            "tags": t.tags or [],
            "heat_value": t.heat_value,
            "raw_heat_value": t.raw_heat_value,
            "rank": t.rank,
            "entities": t.entities or [],
            "first_seen_at": ts,
            "last_seen_at": ts,
            "fetched_at": ts,
            "is_on_list": True,
        }
        if t.content is not None:
            row["content"] = t.content
        topic_rows.append(row)

    # Upsert topics in batches of 50
    upserted = 0
    for i in range(0, len(topic_rows), 50):
        batch = topic_rows[i : i + 50]
        try:
            result = await client.insert("topics", batch, upsert=True, on_conflict="topic_key")
            upserted += len(result)
        except Exception as exc:
            log.error("topic_store.upsert_error", batch_start=i, error=str(exc))

    # Append heat_history
    heat_rows = []
    for t in topics:
        ts = t.fetched_at.isoformat() if t.fetched_at else now
        heat_rows.append({
            "topic_key": t.topic_key,
            "timestamp": ts,
            "heat_value": t.heat_value,
            "rank": t.rank,
        })

    for i in range(0, len(heat_rows), 50):
        batch = heat_rows[i : i + 50]
        try:
            await client.insert("heat_history", batch, upsert=True, on_conflict="topic_key,timestamp", ignore_duplicates=True)
        except Exception as exc:
            log.error("topic_store.heat_history_error", batch_start=i, error=str(exc))

    log.info("topic_store.upserted", count=upserted, total=len(topics))
    return upserted


async def mark_offlist(client: SupabaseClient, platform_id: str, on_list_keys: list[str]) -> int:
    """Mark topics not in the current fetch as off-list."""
    if not on_list_keys:
        return 0

    # PostgREST: PATCH topics WHERE platform_id=X AND is_on_list=true AND topic_key NOT IN (...)
    keys_csv = ",".join(quote(k) for k in on_list_keys)
    filters = f"platform_id=eq.{quote(platform_id)}&is_on_list=eq.true&topic_key=not.in.({keys_csv})"

    try:
        result = await client.update("topics", {"is_on_list": False}, filters)
        count = len(result)
        if count > 0:
            log.info("topic_store.offlist", platform=platform_id, count=count)
        return count
    except Exception as exc:
        log.error("topic_store.offlist_error", platform=platform_id, error=str(exc))
        return 0
