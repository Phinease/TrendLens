"""Lightweight async LLM client using httpx + Anthropic Messages API."""

from __future__ import annotations

import httpx
import structlog
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential

from trendlens.config import LLMConfig

log = structlog.get_logger()


@retry(
    stop=stop_after_attempt(2),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception_type((httpx.ConnectTimeout, httpx.ReadTimeout, httpx.ConnectError, httpx.PoolTimeout)),
    reraise=True,
)
async def _post_messages(client: httpx.AsyncClient, url: str, headers: dict, payload: dict) -> httpx.Response:
    resp = await client.post(url, json=payload, headers=headers)
    resp.raise_for_status()
    return resp


async def call_llm(
    prompt: str,
    cfg: LLMConfig,
    *,
    system: str = "",
    max_tokens: int = 0,
    temperature: float = 0.3,
) -> str:
    """Call Anthropic Messages API. Returns empty string on failure (graceful degradation)."""
    if not cfg.api_key:
        log.warning("llm_client.no_api_key")
        return ""

    url = f"{cfg.endpoint.rstrip('/')}/v1/messages"
    headers = {
        "x-api-key": cfg.api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    payload: dict = {
        "model": cfg.model,
        "max_tokens": max_tokens or cfg.max_tokens,
        "temperature": temperature,
        "messages": [{"role": "user", "content": prompt}],
    }
    if system:
        payload["system"] = system

    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(30, connect=10), verify=False) as client:
            resp = await _post_messages(client, url, headers, payload)
        data = resp.json()
        # Extract text from first content block
        content_blocks = data.get("content", [])
        if content_blocks and content_blocks[0].get("type") == "text":
            return content_blocks[0]["text"]
        log.warning("llm_client.no_text_content", response_keys=list(data.keys()))
        return ""
    except Exception as exc:
        log.error("llm_client.call_failed", error=str(exc))
        return ""
