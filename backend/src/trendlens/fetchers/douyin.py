"""Douyin (抖音) hot search fetcher — via xxapi.cn free API."""

from __future__ import annotations

import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_API_URL = "https://v2.xxapi.cn/api/douyinhot"

# Label code mapping
_LABELS = {0: "", 1: "新", 2: "推荐", 3: "热", 4: "爆", 5: "首映"}


@register_fetcher
class DouyinFetcher(BaseFetcher):
    platform_id = "douyin"
    priority = "P0"

    async def fetch(self) -> FetchResult:
        t0 = time.monotonic()
        try:
            async with create_client() as client:
                resp = await fetch_with_retry(client, "GET", _API_URL)
                body = resp.json()

            items = body.get("data", [])
            topics: list[RawTopic] = []
            for item in items:
                word = item.get("word", "")
                if not word:
                    continue

                hot_value = item.get("hot_value", 0)
                sentence_id = item.get("sentence_id")
                group_id = item.get("group_id")
                position = item.get("position", len(topics) + 1)
                label_code = item.get("label", 0)

                # Use sentence_id or group_id as source_id
                source_id = str(sentence_id) if sentence_id else (str(group_id) if group_id else None)

                tags: list[str] = []
                label_text = _LABELS.get(label_code, "")
                if label_text:
                    tags.append(label_text)

                # Extract cover image
                image_urls: list[str] = []
                cover = item.get("word_cover", {})
                if cover and isinstance(cover, dict):
                    url_list = cover.get("url_list", [])
                    if url_list:
                        image_urls.append(url_list[0])

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=word,
                        rank=position,
                        source_id=source_id,
                        link=f"https://www.douyin.com/search/{word}",
                        image_urls=image_urls,
                        tags=tags,
                        raw_heat=str(hot_value),
                        heat_value=int(hot_value) if hot_value else None,
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
