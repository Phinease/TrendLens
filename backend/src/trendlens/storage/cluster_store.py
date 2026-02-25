"""Event cluster creation and update via PostgREST."""

from __future__ import annotations

import uuid
from collections import Counter
from datetime import datetime, timezone

import structlog

from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


def _generate_cluster_id() -> str:
    return f"evt_{uuid.uuid4().hex[:12]}"


async def create_or_update_clusters(
    client: SupabaseClient,
    clusters: dict[str, list[dict]],
) -> int:
    """Create or update event clusters.

    clusters: mapping of cluster_id (or 'new') -> list of topic dicts
    Each topic dict has: topic_key, platform_id, title, heat_value, entities
    """
    now = datetime.now(timezone.utc).isoformat()
    count = 0

    for raw_id, members in clusters.items():
        if not members:
            continue

        cluster_id = raw_id if raw_id.startswith("evt_") else _generate_cluster_id()

        # Pick title from highest-heat member
        best = max(members, key=lambda m: m.get("heat_value", 0))
        title = best.get("title", "")

        # Keywords: entities appearing >= 2 times
        entity_counts: Counter[str] = Counter()
        for m in members:
            for e in m.get("entities", []):
                entity_counts[e] += 1
        keywords = [e for e, c in entity_counts.most_common() if c >= 2]

        platforms = set(m["platform_id"] for m in members)
        max_heat = max(m.get("heat_value", 0) for m in members)

        try:
            await client.insert(
                "event_clusters",
                [{
                    "cluster_id": cluster_id,
                    "title": title,
                    "keywords": keywords,
                    "platform_count": len(platforms),
                    "topic_count": len(members),
                    "max_heat": max_heat,
                    "first_seen_at": now,
                    "last_updated_at": now,
                    "is_active": True,
                }],
                upsert=True,
                on_conflict="cluster_id",
            )
        except Exception as exc:
            log.error("cluster_store.upsert_error", cluster_id=cluster_id, error=str(exc))
            continue

        # Assign topics to this cluster
        for m in members:
            try:
                await client.update(
                    "topics",
                    {"cluster_id": cluster_id},
                    f"topic_key=eq.{m['topic_key']}",
                )
            except Exception as exc:
                log.error("cluster_store.assign_error", topic_key=m["topic_key"], error=str(exc))

        count += 1

    log.info("cluster_store.done", clusters=count)
    return count
