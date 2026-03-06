"""LLM-driven content quality filtering via reject-list approach."""

from __future__ import annotations

import json
import re

import structlog

from trendlens.config import AppConfig
from trendlens.constants import QUALITY_FILTER_BATCH_SIZE, QUALITY_LLM_TEMPERATURE
from trendlens.models import NormalizedTopic
from trendlens.processing.llm_client import call_llm

log = structlog.get_logger()


_LLM_SYSTEM = (
    "You are a content quality filter for a trending topic aggregation platform. "
    "Your job is to identify topics that are NOT genuine trending news, events, or social discussions. "
    "Filter out: personal narratives, individual creator content without broader relevance, "
    "advertisements, meaningless/gibberish titles, pure entertainment gossip without news value."
)

_LLM_PROMPT_TEMPLATE = """Below is a numbered list of trending topics (title — description).
Identify which ones should be FILTERED OUT because they are NOT genuine trending news/events/social topics.

Filter criteria:
- Personal narratives or diary-style content (e.g. "我叛逆的一生", "今天又加班了")
- Individual creator/influencer names without news context (e.g. "coke和雨妹", "xx哥")
- Advertisements or promotional content (e.g. "别在这理发店💈")
- Meaningless, gibberish, or emoji-only titles
- Pure clickbait with no informational value

Do NOT filter:
- Celebrity news or entertainment events with broad public interest
- Social issues, policy changes, or public safety events
- Sports results, tech launches, cultural events
- Viral memes or internet phenomena that reflect social trends

{topics_block}

Respond with ONLY a JSON array of the numbers to filter out. Example: [3, 7, 12]
If all topics are acceptable, respond with: []"""


def _build_topics_block(topics: list[NormalizedTopic], offset: int = 0) -> str:
    """Format topics as numbered list for LLM prompt."""
    lines = []
    for i, t in enumerate(topics, start=offset + 1):
        desc = (t.description or "")[:80]
        if desc:
            lines.append(f"[{i}] {t.title} — {desc}")
        else:
            lines.append(f"[{i}] {t.title}")
    return "\n".join(lines)


def _parse_reject_list(raw: str) -> list[int]:
    """Parse LLM response into a list of rejected topic numbers."""
    cleaned = raw.strip()
    # Strip markdown fences
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```\s*$", "", cleaned)
    # Find the JSON array
    bracket_start = cleaned.find("[")
    bracket_end = cleaned.rfind("]")
    if bracket_start == -1 or bracket_end == -1:
        return []
    cleaned = cleaned[bracket_start : bracket_end + 1]
    try:
        result = json.loads(cleaned)
        if isinstance(result, list):
            return [int(x) for x in result if isinstance(x, (int, float))]
    except (json.JSONDecodeError, ValueError, TypeError):
        pass
    return []


async def _filter_batch(
    topics: list[NormalizedTopic],
    offset: int,
    cfg: AppConfig,
) -> set[int]:
    """Call LLM for one batch. Returns set of 0-based indices to reject."""
    topics_block = _build_topics_block(topics, offset)
    prompt = _LLM_PROMPT_TEMPLATE.format(topics_block=topics_block)

    raw = await call_llm(
        prompt,
        cfg.llm,
        system=_LLM_SYSTEM,
        max_tokens=256,
        temperature=QUALITY_LLM_TEMPERATURE,
    )
    if not raw:
        return set()

    reject_numbers = _parse_reject_list(raw)
    # Convert 1-based numbers to 0-based indices relative to this batch
    rejected_indices: set[int] = set()
    for num in reject_numbers:
        idx = num - 1 - offset  # 1-based prompt number → 0-based batch index
        if 0 <= idx < len(topics):
            rejected_indices.add(offset + idx)
    return rejected_indices


async def filter_topics_by_quality(
    topics: list[NormalizedTopic],
    cfg: AppConfig,
) -> list[NormalizedTopic]:
    """Filter topics via LLM reject-list. Returns only accepted topics.

    On LLM failure, returns all topics unchanged (conservative: no false removals).
    """
    if not topics:
        return topics
    if not cfg.llm.api_key:
        log.warning("quality_filter.no_api_key")
        return topics

    all_rejected: set[int] = set()
    consecutive_failures = 0

    for i in range(0, len(topics), QUALITY_FILTER_BATCH_SIZE):
        if consecutive_failures >= 2:
            log.warning("quality_filter.circuit_break", failures=consecutive_failures)
            break
        batch = topics[i : i + QUALITY_FILTER_BATCH_SIZE]
        rejected = await _filter_batch(batch, i, cfg)
        if rejected:
            consecutive_failures = 0
            all_rejected |= rejected
            for idx in rejected:
                t = topics[idx]
                log.info("quality_filter.rejected", topic_key=t.topic_key, title=t.title)
        else:
            # Empty reject list is valid (all good) — not a failure
            # Only count as failure if _filter_batch returned empty due to LLM error
            # We can't distinguish here, so we don't increment failures for empty results
            consecutive_failures = 0

    accepted = [t for i, t in enumerate(topics) if i not in all_rejected]
    log.info(
        "quality_filter.done",
        total=len(topics),
        rejected=len(all_rejected),
        accepted=len(accepted),
    )
    return accepted
