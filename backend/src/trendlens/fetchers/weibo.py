"""Weibo (微博) hot search fetcher — via xxapi.cn free API."""

from __future__ import annotations

import re
import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_API_URL = "https://v2.xxapi.cn/api/weibohot"


def _parse_heat(hot_str: str) -> int | None:
    """Parse '110万' -> 1100000, '8543' -> 8543."""
    if not hot_str:
        return None
    m = re.match(r"([\d.]+)\s*万", hot_str)
    if m:
        return int(float(m.group(1)) * 10_000)
    m = re.match(r"(\d+)", hot_str)
    return int(m.group(1)) if m else None


@register_fetcher
class WeiboFetcher(BaseFetcher):
    platform_id = "weibo"
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
                title = item.get("title", "")
                if not title:
                    continue

                hot_str = item.get("hot", "")
                url = item.get("url", "")
                rank = item.get("index", len(topics) + 1)

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=title,
                        rank=rank,
                        source_id=None,  # title hash fallback
                        link=url or None,
                        raw_heat=hot_str or None,
                        heat_value=_parse_heat(hot_str),
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
