"""Snapshot metadata recording via PostgREST."""

from __future__ import annotations

import hashlib
import uuid

import structlog

from trendlens.models import FetchResult
from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


async def record_snapshot(
    client: SupabaseClient,
    result: FetchResult,
    new_count: int = 0,
) -> None:
    """Write a snapshot metadata record for an individual fetch."""
    if not result.ok:
        return

    titles = sorted(t.title for t in result.topics)
    content_hash = hashlib.md5("|".join(titles).encode()).hexdigest()[:16]
    snapshot_id = f"snap_{result.platform_id}_{uuid.uuid4().hex[:8]}"

    try:
        await client.insert("snapshots_meta", [{
            "id": snapshot_id,
            "platform_id": result.platform_id,
            "fetched_at": result.fetched_at.isoformat(),
            "topic_count": len(result.topics),
            "new_topic_count": new_count,
            "content_hash": content_hash,
            "fetch_duration": result.duration_ms,
        }])
    except Exception as exc:
        log.error("snapshot_store.error", platform=result.platform_id, error=str(exc))
