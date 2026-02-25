"""Three-signal fusion cross-platform matcher (data-storage-strategy §4).

Uses PostgREST for candidate queries. Vector similarity requires an RPC
function — if not available, falls back to entity-only matching.
"""

from __future__ import annotations

import structlog

from trendlens.constants import (
    MATCH_ENTITY_STRONG,
    MATCH_ENTITY_WEIGHT,
    MATCH_STRONG_FLOOR,
    MATCH_THRESHOLD,
    MATCH_VECTOR_STRONG,
    MATCH_VECTOR_WEIGHT,
)
from trendlens.matching.union_find import UnionFind
from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


# ── Scoring (§4.5) ─────────────────────────────────────────────────────

def _jaccard(a: list[str], b: list[str]) -> float:
    sa, sb = set(a), set(b)
    if not sa or not sb:
        return 0.0
    return len(sa & sb) / len(sa | sb)


def compute_match_score(entity_score: float, vector_score: float) -> float:
    """Fused match score per data-storage-strategy §4.5."""
    if entity_score >= MATCH_ENTITY_STRONG:
        return max(MATCH_STRONG_FLOOR, entity_score * MATCH_ENTITY_WEIGHT + vector_score * MATCH_VECTOR_WEIGHT)
    if vector_score >= MATCH_VECTOR_STRONG:
        return max(MATCH_STRONG_FLOOR, entity_score * MATCH_ENTITY_WEIGHT + vector_score * MATCH_VECTOR_WEIGHT)
    return entity_score * MATCH_ENTITY_WEIGHT + vector_score * MATCH_VECTOR_WEIGHT


# ── Main matching pipeline ──────────────────────────────────────────────

async def match_and_cluster(
    client: SupabaseClient,
    new_keys: list[str],
) -> dict[str, list[dict]]:
    """Run cross-platform matching for new/updated topics.

    Returns mapping of cluster_id -> list of member dicts.
    """
    if not new_keys:
        return {}

    uf = UnionFind()
    topic_info: dict[str, dict] = {}

    # Fetch all active topics for candidate matching
    active_topics = await client.select(
        "topics",
        columns="topic_key,platform_id,title,heat_value,entities,cluster_id",
        filters="is_on_list=eq.true",
    )

    # Index by key
    active_by_key: dict[str, dict] = {}
    for t in active_topics:
        active_by_key[t["topic_key"]] = t

    # Entity inverted index for fast lookup
    entity_index: dict[str, list[str]] = {}
    for t in active_topics:
        for entity in (t.get("entities") or []):
            entity_index.setdefault(entity, []).append(t["topic_key"])

    # Try to get vector similarity candidates via RPC
    vector_scores: dict[tuple[str, str], float] = {}
    try:
        for key in new_keys:
            similar = await client.rpc("match_topic_embedding", {
                "query_topic_key": key,
                "match_threshold": 0.5,
                "match_count": 20,
            })
            for row in similar:
                vector_scores[(key, row["topic_key"])] = row["similarity"]
    except Exception:
        log.debug("matcher.vector_rpc_unavailable", msg="falling back to entity-only matching")

    # For each new topic, find candidates and score
    for topic_key in new_keys:
        info = active_by_key.get(topic_key)
        if not info:
            continue
        topic_info[topic_key] = info
        entities = info.get("entities") or []
        platform = info["platform_id"]

        # Entity candidates: topics sharing at least one entity (different platform)
        candidate_keys: set[str] = set()
        for entity in entities:
            for cand_key in entity_index.get(entity, []):
                if cand_key != topic_key:
                    cand = active_by_key.get(cand_key)
                    if cand and cand["platform_id"] != platform:
                        candidate_keys.add(cand_key)

        # Also add vector candidates
        for (src, tgt), _ in vector_scores.items():
            if src == topic_key:
                candidate_keys.add(tgt)

        # Score each candidate
        for cand_key in candidate_keys:
            cand = active_by_key.get(cand_key)
            if not cand:
                continue

            cand_entities = cand.get("entities") or []
            entity_score = _jaccard(entities, cand_entities)
            vector_score = vector_scores.get((topic_key, cand_key), 0.0)
            score = compute_match_score(entity_score, vector_score)

            if score >= MATCH_THRESHOLD:
                uf.union(topic_key, cand_key)
                if cand_key not in topic_info:
                    topic_info[cand_key] = cand

    # Build cluster groups (only multi-platform)
    groups = uf.groups()
    clusters: dict[str, list[dict]] = {}
    for root, members in groups.items():
        if len(members) < 2:
            continue

        member_infos = [topic_info[mk] for mk in members if mk in topic_info]
        platforms = set(m["platform_id"] for m in member_infos)
        if len(platforms) < 2:
            continue

        # Use existing cluster_id if any member already has one
        existing_cluster = None
        for m in member_infos:
            if m.get("cluster_id"):
                existing_cluster = m["cluster_id"]
                break

        cluster_id = existing_cluster or "new"
        clusters[cluster_id] = member_infos

    log.info("matcher.done", new_keys=len(new_keys), clusters=len(clusters))
    return clusters
