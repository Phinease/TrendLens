"""Bilibili hot search content scraper — WBI search API to get related video descriptions."""

from __future__ import annotations

from urllib.parse import quote

import structlog

from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.scraping.base import BaseScraper, ScrapeResult, register_scraper
from trendlens.scraping.html_utils import clean_content, html_to_text

log = structlog.get_logger()

# The /wbi/ variant works without cookie authentication (unlike the non-wbi version)
_SEARCH_URL = "https://api.bilibili.com/x/web-interface/wbi/search/type?search_type=video&keyword={kw}&page=1&page_size=5"
_MAX_VIDEOS = 5


@register_scraper
class BilibiliHsScraper(BaseScraper):
    platform_id = "bilibili-hs"

    async def scrape(self, topic: dict) -> ScrapeResult:
        key = topic["topic_key"]
        title = topic.get("title", "")
        if not title:
            return ScrapeResult(topic_key=key, error="no title for search")

        try:
            async with create_client() as client:
                url = _SEARCH_URL.format(kw=quote(title))
                resp = await fetch_with_retry(
                    client, "GET", url,
                    headers={"Referer": "https://search.bilibili.com/"},
                )
                data = resp.json()

            results = data.get("data", {}).get("result", [])
            if not results:
                return ScrapeResult(topic_key=key, error="no search results")

            parts: list[str] = []
            for item in results[:_MAX_VIDEOS]:
                video_title = item.get("title", "")
                # title may contain <em> highlight tags
                video_title = html_to_text(video_title) if "<" in video_title else video_title
                desc = item.get("description", "")
                if video_title:
                    entry = f"[{video_title}]"
                    if desc and desc != "-":
                        entry += f" {desc}"
                    parts.append(entry)

            if not parts:
                return ScrapeResult(topic_key=key, error="no video descriptions")

            combined = "\n\n".join(parts)
            content = clean_content(combined)
            if not content:
                return ScrapeResult(topic_key=key, error="empty after cleaning")
            return ScrapeResult(topic_key=key, content=content)

        except Exception as exc:
            log.warning("scrape.bilibili_hs.error", topic_key=key, error=str(exc))
            return ScrapeResult(topic_key=key, error=str(exc))
