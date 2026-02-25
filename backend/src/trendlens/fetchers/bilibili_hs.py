"""Bilibili hot search (B站热搜) fetcher."""

from __future__ import annotations

import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_API_URL = "https://app.bilibili.com/x/v2/search/trending/ranking"


@register_fetcher
class BilibiliHotSearchFetcher(BaseFetcher):
    platform_id = "bilibili-hs"
    priority = "P0"

    async def fetch(self) -> FetchResult:
        t0 = time.monotonic()
        try:
            async with create_client() as client:
                resp = await fetch_with_retry(client, "GET", _API_URL)
                data = resp.json()

            items = data.get("data", {}).get("list", [])
            topics: list[RawTopic] = []
            for i, item in enumerate(items):
                keyword = item.get("keyword") or item.get("show_name", "")
                if not keyword:
                    continue

                show_name = item.get("show_name", keyword)
                hot_id = item.get("hot_id")
                icon = item.get("icon", "")
                heat_score = item.get("heat_score") or item.get("score", 0)

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=show_name,
                        rank=item.get("position", i + 1),
                        source_id=str(hot_id) if hot_id else None,
                        link=f"https://search.bilibili.com/all?keyword={keyword}",
                        image_urls=[icon] if icon else [],
                        raw_heat=str(heat_score) if heat_score else None,
                        heat_value=int(heat_score) if heat_score else None,
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
