"""Baidu content scraper — use description if sufficient, else fetch rawUrl."""

from __future__ import annotations

import structlog

from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper
from trendlens.scraping.html_utils import clean_content, html_to_text

log = structlog.get_logger()

_DESC_MIN_LENGTH = 50


@register_scraper
class BaiduScraper(BaseScraper):
    platform_id = "baidu"

    async def scrape(self, topic: dict) -> ScrapeResult:
        key = topic["topic_key"]
        desc = topic.get("description") or ""

        # If description is long enough, use it directly
        if len(desc) >= _DESC_MIN_LENGTH:
            content = clean_content(desc)
            if content:
                return ScrapeResult(topic_key=key, content=content)

        # Otherwise try fetching the linked page
        link = topic.get("link")
        if not link:
            # Fall back to whatever description we have
            content = clean_content(desc)
            if content:
                return ScrapeResult(topic_key=key, content=content)
            return ScrapeResult(topic_key=key, error="no link and short description")

        try:
            async with create_client() as client:
                resp = await fetch_with_retry(
                    client, "GET", link,
                    headers={"Accept": "text/html"},
                )
                html = resp.text

            # Try to extract meaningful text from the page
            text = html_to_text(html)
            # Take a reasonable chunk — skip very short extracts
            if len(text) < _DESC_MIN_LENGTH:
                # Fall back to original description
                content = clean_content(desc) if desc else None
                if content:
                    return ScrapeResult(topic_key=key, content=content)
                return ScrapeResult(topic_key=key, error="page content too short")

            content = clean_content(text)
            if content:
                return ScrapeResult(topic_key=key, content=content)
            return ScrapeResult(topic_key=key, error="empty after cleaning")

        except Exception as exc:
            log.warning("scrape.baidu.error", topic_key=key, error=str(exc))
            # Fall back to description on network error
            content = clean_content(desc) if desc else None
            if content:
                return ScrapeResult(topic_key=key, content=content)
            return ScrapeResult(topic_key=key, error=str(exc))
