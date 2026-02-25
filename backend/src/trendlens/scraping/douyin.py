"""Douyin content scraper — stub (search page scraping too complex).

Per hot-news-data-sources-v2.md, Douyin content extraction is deferred to
AI summarisation in a future phase. This scraper is registered so the
framework recognises douyin as a known platform but always returns a
no-op result.
"""

from __future__ import annotations

from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper


@register_scraper
class DouyinScraper(BaseScraper):
    platform_id = "douyin"

    async def scrape(self, topic: dict) -> ScrapeResult:
        return ScrapeResult(
            topic_key=topic["topic_key"],
            error="douyin scraping not implemented — deferred to AI summarisation",
        )
