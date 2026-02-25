"""Toutiao content scraper — mobile info API for article content.

The hot-board links are trending topic pages (JS-rendered, no content in HTML).
Strategy: use source_id (cluster_id) to call the mobile info API. If that returns
no content (it's a topic hub, not an article), return error — toutiao topic hubs
have no scrapable article text without a browser.
"""

from __future__ import annotations

import structlog

from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper
from trendlens.scraping.html_utils import clean_content, html_to_text

log = structlog.get_logger()

_MOBILE_INFO_URL = "https://m.toutiao.com/i{gid}/info/"


@register_scraper
class ToutiaoScraper(BaseScraper):
    platform_id = "toutiao"

    async def scrape(self, topic: dict) -> ScrapeResult:
        key = topic["topic_key"]
        source_id = topic.get("source_id")
        if not source_id:
            return ScrapeResult(topic_key=key, error="no source_id")

        try:
            async with create_client() as client:
                resp = await fetch_with_retry(
                    client, "GET", _MOBILE_INFO_URL.format(gid=source_id),
                )
                data = resp.json()

            article = data.get("data", {})
            html_content = article.get("content", "")
            if not html_content:
                # Trending topic hub — no article content
                return ScrapeResult(topic_key=key, error="topic hub, no article content")

            text = html_to_text(html_content)
            content = clean_content(text)
            if not content:
                return ScrapeResult(topic_key=key, error="empty after cleaning")

            return ScrapeResult(topic_key=key, content=content)

        except Exception as exc:
            log.warning("scrape.toutiao.error", topic_key=key, error=str(exc))
            return ScrapeResult(topic_key=key, error=str(exc))
