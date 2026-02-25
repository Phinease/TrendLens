"""Weibo content scraper — stub (search API requires login).

The weibo mobile search API (m.weibo.cn) returns 432/requires login for content
queries. The xxapi.cn hot list only provides title + heat value, no description.
Content scraping is deferred until a cookie-based auth strategy is implemented.
"""

from __future__ import annotations

from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper


@register_scraper
class WeiboScraper(BaseScraper):
    platform_id = "weibo"

    async def scrape(self, topic: dict) -> ScrapeResult:
        return ScrapeResult(
            topic_key=topic["topic_key"],
            error="weibo search requires login — deferred",
        )
