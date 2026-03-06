"""Pipeline orchestrator — fetch → normalise → embed → match → store."""

from __future__ import annotations

import asyncio
import time

import structlog

from trendlens.config import AppConfig
from trendlens.constants import FETCH_CONCURRENCY_LIMIT
from trendlens.fetchers.base import BaseFetcher, get_fetchers
from trendlens.matching.matcher import match_and_cluster
from trendlens.models import FetchResult, NormalizedTopic
from trendlens.processing.embedder import embed_topics
from trendlens.processing.entity_extractor import enrich_entities
from trendlens.processing.normalizer import normalize_topics
from trendlens.storage.client import close_client, get_client
from trendlens.storage.cluster_store import create_or_update_clusters
from trendlens.storage.embedding_store import get_existing_keys, store_embeddings
from trendlens.storage.snapshot_store import record_snapshot
from trendlens.scraping.scraper_manager import scrape_content
from trendlens.storage.topic_store import batch_update_tags, mark_offlist, upsert_topics
from trendlens.storage.trend_store import upsert_keywords, upsert_topic_trend_links

log = structlog.get_logger()


async def _fetch_one(sem: asyncio.Semaphore, fetcher: BaseFetcher) -> FetchResult:
    async with sem:
        return await fetcher.fetch()


async def run_cycle(cfg: AppConfig, run_id: str, priorities: list[str]) -> None:
    """Execute one full pipeline cycle."""
    t0 = time.monotonic()
    log.info("cycle.start", run_id=run_id, priorities=priorities)

    # Import all fetcher modules to trigger registration
    import trendlens.fetchers.baidu  # noqa: F401
    import trendlens.fetchers.bilibili_hs  # noqa: F401
    import trendlens.fetchers.bilibili_hv  # noqa: F401
    import trendlens.fetchers.douyin  # noqa: F401
    import trendlens.fetchers.toutiao  # noqa: F401
    import trendlens.fetchers.weibo  # noqa: F401
    import trendlens.fetchers.zhihu  # noqa: F401

    fetchers = get_fetchers(priorities)
    if not fetchers:
        log.warning("cycle.no_fetchers", priorities=priorities)
        return

    log.info("cycle.fetchers", count=len(fetchers), platforms=[f.platform_id for f in fetchers])

    # ── Step 1: Concurrent fetch ─────────────────────────────────────
    sem = asyncio.Semaphore(FETCH_CONCURRENCY_LIMIT)
    results: list[FetchResult] = await asyncio.gather(
        *[_fetch_one(sem, f) for f in fetchers],
        return_exceptions=False,
    )

    ok_results = [r for r in results if r.ok]
    err_results = [r for r in results if not r.ok]
    log.info("cycle.fetch_done", ok=len(ok_results), errors=len(err_results))

    if not ok_results:
        log.warning("cycle.all_fetches_failed")
        return

    # ── Step 2: Normalise ────────────────────────────────────────────
    all_topics: list[NormalizedTopic] = []
    for result in ok_results:
        normalised = normalize_topics(result.topics)
        all_topics.extend(normalised)

    log.info("cycle.normalised", count=len(all_topics))

    # ── Step 2.5: LLM content quality filtering ──────────────────────
    if cfg.llm.api_key:
        from trendlens.processing.quality_filter import filter_topics_by_quality

        pre_count = len(all_topics)
        all_topics = await filter_topics_by_quality(all_topics, cfg)
        filtered_count = pre_count - len(all_topics)
        log.info("cycle.quality_filter", before=pre_count, after=len(all_topics), filtered=filtered_count)

    # ── Step 3: Entity extraction ────────────────────────────────────
    enrich_entities(all_topics)

    # ── Step 4: Connect to Supabase ──────────────────────────────────
    client = await get_client(cfg)

    try:
        # ── Step 5: Embedding ────────────────────────────────────────
        existing_emb_keys = await get_existing_keys(client)
        await embed_topics(all_topics, existing_emb_keys, cfg)

        # ── Step 6: UPSERT topics + heat_history ─────────────────────
        upserted = await upsert_topics(client, all_topics)

        # ── Step 6.3: Trend keyword extraction + storage ────────────
        extraction_map: dict[str, dict] = {}
        if cfg.trend.enabled:
            from trendlens.processing.keyword_extractor import extract_keywords_for_topics, merge_tags

            extraction_map = await extract_keywords_for_topics(client, all_topics, cfg)
            if extraction_map:
                # Collect new keywords to upsert
                kw_rows = []
                link_rows = []
                seen_kw_ids: set[str] = set()
                for topic_key, result in extraction_map.items():
                    for kw in result.get("keywords", []):
                        if kw["keyword_id"] not in seen_kw_ids and kw.get("is_new", True):
                            kw_rows.append({
                                "keyword_id": kw["keyword_id"],
                                "keyword": kw["keyword"],
                                "source": kw["source"],
                            })
                            seen_kw_ids.add(kw["keyword_id"])
                        link_rows.append({
                            "topic_key": topic_key,
                            "keyword_id": kw["keyword_id"],
                            "relevance": kw["relevance"],
                            "source": kw["source"],
                        })
                if kw_rows:
                    await upsert_keywords(client, kw_rows)
                if link_rows:
                    await upsert_topic_trend_links(client, link_rows)
                log.info("cycle.keywords", topics_linked=len(extraction_map), keywords=len(kw_rows))

        # ── Step 6.4: Merge + write tags ───────────────────────────
        if cfg.trend.enabled:
            from trendlens.processing.keyword_extractor import merge_tags

            tag_updates: dict[str, list[str]] = {}
            for t in all_topics:
                extraction = extraction_map.get(t.topic_key)
                merged = merge_tags(t, extraction)
                if merged:
                    tag_updates[t.topic_key] = merged
            if tag_updates:
                tag_count = await batch_update_tags(client, tag_updates)
                log.info("cycle.tags", topics_updated=tag_count, total=len(tag_updates))

        # ── Step 6.5: Scrape content for new topics ──────────────────
        platform_ids = list({r.platform_id for r in ok_results})
        scraped = await scrape_content(client, platform_ids)
        log.info("cycle.scraped", content_updated=scraped)

        # ── Step 7: Mark off-list topics ─────────────────────────────
        for result in ok_results:
            keys = [t.topic_key for t in normalize_topics(result.topics)]
            await mark_offlist(client, result.platform_id, keys)

        # ── Step 8: Store embeddings ─────────────────────────────────
        await store_embeddings(client, all_topics, cfg.jina.model)

        # ── Step 9: Match + cluster ──────────────────────────────────
        new_keys = [t.topic_key for t in all_topics]
        clusters = await match_and_cluster(client, new_keys)
        if clusters:
            await create_or_update_clusters(client, clusters)

        # ── Step 10: Record snapshots ────────────────────────────────
        for result in ok_results:
            await record_snapshot(client, result)

    finally:
        await close_client()

    elapsed = int((time.monotonic() - t0) * 1000)
    log.info(
        "cycle.done",
        run_id=run_id,
        topics=len(all_topics),
        upserted=upserted,
        clusters=len(clusters) if clusters else 0,
        duration_ms=elapsed,
    )
