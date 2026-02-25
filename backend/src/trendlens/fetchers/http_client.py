"""Shared async HTTP client factory with retry logic."""

from __future__ import annotations

import random
from typing import Any

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from trendlens.constants import HTTP_MAX_RETRIES, HTTP_RETRY_BASE_SECONDS, HTTP_TIMEOUT_SECONDS

_USER_AGENTS = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15",
]

_RETRYABLE = (httpx.ConnectTimeout, httpx.ReadTimeout, httpx.ConnectError, httpx.PoolTimeout)


def _random_ua() -> str:
    return random.choice(_USER_AGENTS)


def create_client(**overrides: Any) -> httpx.AsyncClient:
    """Create a shared async HTTP client with sensible defaults."""
    defaults: dict[str, Any] = {
        "timeout": httpx.Timeout(HTTP_TIMEOUT_SECONDS, connect=10),
        "follow_redirects": True,
        "http2": True,
        "headers": {"User-Agent": _random_ua(), "Accept": "application/json, text/html, */*"},
    }
    defaults.update(overrides)
    return httpx.AsyncClient(**defaults)


@retry(
    stop=stop_after_attempt(HTTP_MAX_RETRIES),
    wait=wait_exponential(multiplier=HTTP_RETRY_BASE_SECONDS, min=1, max=8),
    retry=retry_if_exception_type(_RETRYABLE),
    reraise=True,
)
async def fetch_with_retry(client: httpx.AsyncClient, method: str, url: str, **kwargs: Any) -> httpx.Response:
    """Execute an HTTP request with tenacity retry on network/timeout errors."""
    resp = await client.request(method, url, **kwargs)
    resp.raise_for_status()
    return resp
