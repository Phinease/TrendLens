"""Bilibili hot videos — content from existing API description field."""

from __future__ import annotations

import structlog

from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper
from trendlens.scraping.html_utils import clean_content

log = structlog.get_logger()


@register_scraper
class BilibiliHvScraper(BaseScraper):
    """bilibili-hv topics already have description from the API — use it directly."""

    platform_id = "bilibili-hv"

    async def scrape(self, topic: dict) -> ScrapeResult:
        key = topic["topic_key"]
        desc = topic.get("description")
        content = clean_content(desc)
        if not content:
            return ScrapeResult(topic_key=key, error="no description available")
        return ScrapeResult(topic_key=key, content=content)
