"""Zhihu (知乎) hot list fetcher."""

from __future__ import annotations

import re
import time

import structlog

from trendlens.fetchers.base import BaseFetcher, register_fetcher
from trendlens.fetchers.http_client import create_client, fetch_with_retry
from trendlens.models import FetchResult, RawTopic

log = structlog.get_logger()

_API_URL = "https://www.zhihu.com/api/v3/feed/topstory/hot-list-web?limit=50&desktop=true"


def _parse_heat(text: str) -> int | None:
    """Parse '654 万热度' -> 6540000."""
    if not text:
        return None
    m = re.search(r"([\d.]+)\s*万", text)
    if m:
        return int(float(m.group(1)) * 10_000)
    m = re.search(r"([\d]+)", text)
    return int(m.group(1)) if m else None


def _extract_question_id(url: str) -> str | None:
    """Extract question ID from zhihu URL."""
    m = re.search(r"/question/(\d+)", url)
    return m.group(1) if m else None


@register_fetcher
class ZhihuFetcher(BaseFetcher):
    platform_id = "zhihu"
    priority = "P0"

    async def fetch(self) -> FetchResult:
        t0 = time.monotonic()
        try:
            async with create_client() as client:
                resp = await fetch_with_retry(client, "GET", _API_URL)
                data = resp.json()

            topics: list[RawTopic] = []
            for i, item in enumerate(data.get("data", [])):
                target = item.get("target", {})
                title = target.get("title_area", {}).get("text", "")
                if not title:
                    continue

                heat_text = target.get("metrics_area", {}).get("text", "")
                link = target.get("link", {}).get("url", "")
                qid = _extract_question_id(link)
                image = target.get("image_area", {}).get("url")
                desc = target.get("excerpt_area", {}).get("text")

                topics.append(
                    RawTopic(
                        platform_id=self.platform_id,
                        title=title,
                        rank=i + 1,
                        source_id=qid,
                        description=desc,
                        link=link,
                        image_urls=[image] if image else [],
                        raw_heat=heat_text,
                        heat_value=_parse_heat(heat_text),
                    )
                )

            elapsed = int((time.monotonic() - t0) * 1000)
            log.info("fetch.done", platform=self.platform_id, count=len(topics), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, topics=topics, duration_ms=elapsed)

        except Exception as exc:
            elapsed = int((time.monotonic() - t0) * 1000)
            log.error("fetch.error", platform=self.platform_id, error=str(exc), duration_ms=elapsed)
            return FetchResult(platform_id=self.platform_id, duration_ms=elapsed, error=str(exc))
