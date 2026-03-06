"""Scraper manager — orchestrates concurrent content scraping across platforms."""

from __future__ import annotations

import asyncio

import structlog

from trendlens.constants import SCRAPE_CONCURRENCY_LIMIT, SCRAPE_TOP_N_PER_PLATFORM
from trendlens.scraping.base import BaseScraper, ScrapeResult, get_scrapers
from trendlens.storage.client import SupabaseClient
from trendlens.storage.content_store import batch_update_content, get_topics_without_content

log = structlog.get_logger()


async def _scrape_one(
    sem: asyncio.Semaphore,
    scraper: BaseScraper,
    topic: dict,
) -> ScrapeResult:
    """Scrape a single topic with semaphore rate-limiting."""
    async with sem:
        return await scraper.scrape(topic)


async def scrape_content(
    client: SupabaseClient,
    platform_ids: list[str] | None = None,
) -> int:
    """Scrape content for topics that lack it. Returns total topics updated.

    1. For each platform, query DB for on-list topics with NULL content.
    2. Dispatch scraping tasks with shared concurrency semaphore.
    3. Batch-update content back to DB.
    """
    # Import all scraper modules to trigger registration
    import trendlens.scraping.baidu  # noqa: F401
    import trendlens.scraping.bilibili_hs  # noqa: F401
    import trendlens.scraping.bilibili_hv  # noqa: F401
    import trendlens.scraping.douyin  # noqa: F401
    import trendlens.scraping.toutiao  # noqa: F401
    import trendlens.scraping.weibo  # noqa: F401
    import trendlens.scraping.zhihu  # noqa: F401

    scrapers = get_scrapers(platform_ids)
    if not scrapers:
        log.warning("scrape.no_scrapers", platform_ids=platform_ids)
        return 0

    log.info("scrape.start", platforms=[s.platform_id for s in scrapers])

    sem = asyncio.Semaphore(SCRAPE_CONCURRENCY_LIMIT)
    total_updated = 0

    for scraper in scrapers:
        # Query DB for topics needing content
        topics = await get_topics_without_content(
            client, scraper.platform_id, limit=SCRAPE_TOP_N_PER_PLATFORM,
        )
        if not topics:
            log.info("scrape.skip", platform=scraper.platform_id, reason="all topics have content")
            continue

        log.info("scrape.platform", platform=scraper.platform_id, topics=len(topics))

        # Concurrent scraping with shared semaphore
        results: list[ScrapeResult] = await asyncio.gather(
            *[_scrape_one(sem, scraper, t) for t in topics],
            return_exceptions=False,
        )

        # Collect successful results
        updates: list[tuple[str, str]] = []
        descriptions: dict[str, str] = {}
        errors = 0
        for r in results:
            if r.ok:
                updates.append((r.topic_key, r.content))  # type: ignore[arg-type]
            else:
                errors += 1

        # Build description map for content dedup
        for t in topics:
            if t.get("description"):
                descriptions[t["topic_key"]] = t["description"]

        if updates:
            updated = await batch_update_content(client, updates, descriptions)
            total_updated += updated

        log.info(
            "scrape.platform_done",
            platform=scraper.platform_id,
            scraped=len(results),
            success=len(updates),
            errors=errors,
        )

    log.info("scrape.done", total_updated=total_updated)
    return total_updated
