"""Bilibili hot videos (B站热门) fetcher."""

from __future__ import annotations

import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_API_URL = "https://api.bilibili.com/x/web-interface/popular?ps=50&pn=1"


@register_fetcher
class BilibiliHotVideoFetcher(BaseFetcher):
    platform_id = "bilibili-hv"
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
                title = item.get("title", "")
                if not title:
                    continue

                bvid = item.get("bvid", "")
                stat = item.get("stat", {})
                views = stat.get("view", 0)
                pic = item.get("pic", "")
                desc = item.get("desc", "")
                tname = item.get("tname", "")
                short_link = item.get("short_link_v2", "")
                link = short_link or (f"https://www.bilibili.com/video/{bvid}" if bvid else "")

                tags: list[str] = []
                if tname:
                    tags.append(tname)

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=title,
                        rank=i + 1,
                        source_id=bvid or None,
                        description=desc if desc and desc != "-" else None,
                        link=link or None,
                        image_urls=[pic] if pic else [],
                        tags=tags,
                        raw_heat=str(views),
                        heat_value=views,
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
