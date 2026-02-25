"""Baidu (百度) hot search fetcher — HTML with embedded JSON."""

from __future__ import annotations

import json
import re
import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_URL = "https://top.baidu.com/board?tab=realtime"


def _extract_embedded_json(html: str) -> dict:
    """Extract the JSON object from <!--s-data:{...}-->."""
    m = re.search(r"<!--s-data:(.*?)-->", html, re.DOTALL)
    if not m:
        raise ValueError("Cannot find <!--s-data:--> block in Baidu HTML")
    return json.loads(m.group(1))


@register_fetcher
class BaiduFetcher(BaseFetcher):
    platform_id = "baidu"
    priority = "P0"

    async def fetch(self) -> FetchResult:
        t0 = time.monotonic()
        try:
            async with create_client() as client:
                resp = await fetch_with_retry(
                    client,
                    "GET",
                    _URL,
                    headers={"Accept": "text/html"},
                )
                html = resp.text

            data = _extract_embedded_json(html)
            cards = data.get("data", {}).get("cards", [])
            items: list[dict] = []
            for card in cards:
                items.extend(card.get("content", []))

            topics: list[RawTopic] = []
            for i, item in enumerate(items):
                word = item.get("word") or item.get("query", "")
                if not word:
                    continue

                hot_score = item.get("hotScore", "")
                desc = item.get("desc", "")
                img = item.get("img", "")
                url = item.get("rawUrl") or item.get("url", "")

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=word,
                        rank=i + 1,
                        source_id=word,
                        description=desc or None,
                        link=url or None,
                        image_urls=[img] if img else [],
                        raw_heat=str(hot_score),
                        heat_value=int(hot_score) if str(hot_score).isdigit() else None,
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
