"""Zhihu content scraper — use existing description (excerpt from hot list API).

The answers API (v4) requires authentication. However, the hot list API already
provides a rich excerpt_area for ~70% of topics, often 200-800 chars of detailed
summary. We use that directly as content.
"""

from __future__ import annotations

from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper
from trendlens.scraping.html_utils import clean_content


@register_scraper
class ZhihuScraper(BaseScraper):
    platform_id = "zhihu"

    async def scrape(self, topic: dict) -> ScrapeResult:
        key = topic["topic_key"]
        desc = topic.get("description")
        content = clean_content(desc)
        if not content:
            return ScrapeResult(topic_key=key, error="no description/excerpt available")
        return ScrapeResult(topic_key=key, content=content)
