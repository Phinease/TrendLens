"""Jina API batch embedding — only embeds new topics, graceful degradation."""

from __future__ import annotations

import structlog

from trendlens.config import AppConfig
from trendlens.constants import EMBEDDING_BATCH_SIZE
from trendlens.fetchers.http_client import create_client
from trendlens.models import NormalizedTopic

log = structlog.get_logger()


def _build_input(topic: NormalizedTopic) -> str:
    """Construct embedding input: title + description."""
    parts = [topic.title]
    if topic.description:
        parts.append(topic.description)
    return " ".join(parts)


async def embed_topics(
    topics: list[NormalizedTopic],
    existing_keys: set[str],
    cfg: AppConfig,
) -> None:
    """Batch embed topics via Jina API. Skips already-embedded keys.

    On failure, logs error and leaves topic.embedding as None — the topic
    will still be stored and can be embedded on the next cycle.
    """
    to_embed = [t for t in topics if t.topic_key not in existing_keys]
    if not to_embed:
        log.info("embed.skip", reason="all_topics_already_embedded")
        return

    if not cfg.jina.api_key:
        log.warning("embed.skip", reason="no_jina_api_key")
        return

    log.info("embed.start", count=len(to_embed))

    try:
        async with create_client() as client:
            for batch_start in range(0, len(to_embed), EMBEDDING_BATCH_SIZE):
                batch = to_embed[batch_start : batch_start + EMBEDDING_BATCH_SIZE]
                inputs = [_build_input(t) for t in batch]

                resp = await client.post(
                    cfg.jina.endpoint,
                    json={
                        "model": cfg.jina.model,
                        "task": cfg.jina.task,
                        "dimensions": cfg.jina.dimensions,
                        "input": inputs,
                    },
                    headers={
                        "Authorization": f"Bearer {cfg.jina.api_key}",
                        "Content-Type": "application/json",
                    },
                    timeout=60,
                )
                resp.raise_for_status()
                body = resp.json()

                for item in body.get("data", []):
                    idx = item.get("index", 0)
                    if idx < len(batch):
                        batch[idx].embedding = item.get("embedding")

                log.debug(
                    "embed.batch",
                    batch_start=batch_start,
                    batch_size=len(batch),
                )

    except Exception as exc:
        log.error("embed.error", error=str(exc))
        # Graceful degradation: topics without embeddings are still stored

    embedded_count = sum(1 for t in to_embed if t.embedding is not None)
    log.info("embed.done", embedded=embedded_count, total=len(to_embed))
