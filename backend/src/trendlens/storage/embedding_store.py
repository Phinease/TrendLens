"""Topic embedding storage via PostgREST."""

from __future__ import annotations

import structlog

from trendlens.models import NormalizedTopic
from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


async def get_existing_keys(client: SupabaseClient) -> set[str]:
    """Return set of topic_keys that already have embeddings."""
    rows = await client.select("topic_embeddings", columns="topic_key")
    return {r["topic_key"] for r in rows}


async def store_embeddings(
    client: SupabaseClient,
    topics: list[NormalizedTopic],
    model_version: str = "jina-embeddings-v3",
) -> int:
    """Store embeddings for topics that have them. Returns count stored."""
    to_store = [t for t in topics if t.embedding is not None]
    if not to_store:
        return 0

    rows = []
    for t in to_store:
        # pgvector via PostgREST: pass as string '[0.1, 0.2, ...]'
        vec_str = "[" + ",".join(str(v) for v in t.embedding) + "]"
        rows.append({
            "topic_key": t.topic_key,
            "embedding": vec_str,
            "model_version": model_version,
        })

    stored = 0
    for i in range(0, len(rows), 20):
        batch = rows[i : i + 20]
        try:
            result = await client.insert(
                "topic_embeddings", batch, upsert=True, on_conflict="topic_key"
            )
            stored += len(result)
        except Exception as exc:
            log.error("embedding_store.error", batch_start=i, error=str(exc))

    log.info("embedding_store.done", stored=stored, total=len(to_store))
    return stored
