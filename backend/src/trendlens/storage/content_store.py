"""Content storage — query topics without content + batch update content."""

from __future__ import annotations

from urllib.parse import quote

import structlog

from trendlens.constants import SCRAPE_TOP_N_PER_PLATFORM
from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


async def get_topics_without_content(
    client: SupabaseClient,
    platform_id: str,
    limit: int = SCRAPE_TOP_N_PER_PLATFORM,
) -> list[dict]:
    """Return on-list topics for *platform_id* that have no content yet.

    Results are ordered by rank (lowest = most popular) and capped at *limit*.
    Each dict contains at least: topic_key, title, source_id, link, description.
    """
    filters = (
        f"platform_id=eq.{quote(platform_id)}"
        "&is_on_list=eq.true"
        "&content=is.null"
        f"&order=rank.asc"
        f"&limit={limit}"
    )
    try:
        rows = await client.select(
            "topics",
            columns="topic_key,title,source_id,link,description,rank",
            filters=filters,
        )
        log.info(
            "content_store.query",
            platform=platform_id,
            without_content=len(rows),
        )
        return rows
    except Exception as exc:
        log.error("content_store.query_error", platform=platform_id, error=str(exc))
        return []


async def update_content(
    client: SupabaseClient,
    topic_key: str,
    content: str,
) -> bool:
    """Set the content column for a single topic. Returns True on success."""
    filters = f"topic_key=eq.{quote(topic_key)}"
    try:
        await client.update("topics", {"content": content}, filters)
        return True
    except Exception as exc:
        log.error("content_store.update_error", topic_key=topic_key, error=str(exc))
        return False


async def batch_update_content(
    client: SupabaseClient,
    updates: list[tuple[str, str]],
) -> int:
    """Update content for multiple topics. Returns count of successful updates.

    *updates* is a list of (topic_key, content) tuples.
    """
    success = 0
    for topic_key, content in updates:
        if await update_content(client, topic_key, content):
            success += 1
    if updates:
        log.info("content_store.batch_done", total=len(updates), success=success)
    return success
