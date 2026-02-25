"""Toutiao (今日头条) hot search fetcher."""

from __future__ import annotations

import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_API_URL = "https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc"


@register_fetcher
class ToutiaoFetcher(BaseFetcher):
    platform_id = "toutiao"
    priority = "P0"

    async def fetch(self) -> FetchResult:
        t0 = time.monotonic()
        try:
            async with create_client() as client:
                resp = await fetch_with_retry(client, "GET", _API_URL)
                body = resp.json()

            items = body.get("data", [])
            topics: list[RawTopic] = []
            for i, item in enumerate(items):
                title = item.get("Title", "")
                if not title:
                    continue

                hot_value_str = item.get("HotValue", "0")
                hot_value = int(hot_value_str) if str(hot_value_str).isdigit() else None
                cluster_id = str(item.get("ClusterIdStr") or item.get("ClusterId", ""))
                url = item.get("Url", "")
                image = item.get("Image", {})
                image_url = image.get("url", "") if isinstance(image, dict) else ""
                label = item.get("Label", "")
                label_desc = item.get("LabelDesc", "")

                tags: list[str] = []
                if label:
                    tags.append(label)
                if label_desc:
                    tags.append(label_desc)

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=title,
                        rank=i + 1,
                        source_id=cluster_id or None,
                        description=label_desc or None,
                        link=url or None,
                        image_urls=[image_url] if image_url else [],
                        tags=tags,
                        raw_heat=str(hot_value_str),
                        heat_value=hot_value,
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
