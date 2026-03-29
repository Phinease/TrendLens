"""AI-driven keyword extraction: jieba pre-processing → LLM expansion → dedup."""

from __future__ import annotations

import json
import re
import unicodedata

import structlog

from trendlens.config import AppConfig
from trendlens.constants import (
    CONTENT_CATEGORIES,
    DOUYIN_STATUS_LABELS,
    TREND_KEYWORD_BATCH_SIZE,
    TREND_KEYWORD_MAX_PER_TOPIC,
    TREND_KEYWORD_STOPWORDS,
    TREND_LLM_TEMPERATURE,
)
from trendlens.models import NormalizedTopic
from trendlens.processing.llm_client import call_llm
from trendlens.storage.client import SupabaseClient

log = structlog.get_logger()


# ── LLM keyword extraction ────────────────────────────────────────────

_CATEGORIES_LIST = ", ".join(CONTENT_CATEGORIES)

_LLM_SYSTEM = (
    "You are a keyword extraction and content classification assistant for a trending topic aggregation system. "
    "You have two jobs: (1) extract specific, searchable keywords that produce meaningful Google Trends or Baidu Index results; "
    "(2) classify each topic into 1-3 predefined content categories. "
    "Keywords must be specific enough to reflect THIS particular event, not generic everyday concepts."
)

_LLM_PROMPT_TEMPLATE = """Given the following trending topic titles, extract search keywords and classify each topic.

Keyword requirements:
- Extract specific named entities: person names, organization names, product names, event names
- Infer related background concepts that are SPECIFIC and time-bound
  GOOD: "特朗普关税" "中美贸易战" "苹果发布会" "巴黎奥运会" "SpaceX星舰"
  BAD (too generic, DO NOT extract): "影视行业" "社会现象" "群众演员" "影视作品" "娱乐圈" "经济发展"
- Do NOT extract:
  × Generic industry/field terms (影视行业, 互联网, 科技)
  × Common concept words (社会现象, 社会问题, 文化)
  × Sentiment or opinion phrases (太难吃了, 真的好看)
  × Generic role nouns (网友, 观众, 群众演员)
- Each keyword should be 2-15 characters
- Keywords must be specific enough to show a meaningful, distinct trend curve on Google Trends
- Assign a relevance score 0.0-1.0 for each keyword
- Maximum {max_per_topic} keywords per topic
- Avoid duplicating these existing keywords: {existing_keywords}

Classification requirements:
- Assign 1-3 categories from this EXACT list (no other values allowed):
  {categories}
- Pick the most relevant categories; fewer is better than forcing a poor fit

Topics:
{topics_block}

IMPORTANT: Use the numeric ID (the number in brackets) as "topic_key", NOT the title text.
Respond with ONLY valid JSON (no markdown fences):
{{"extractions": [{{"topic_key": "0", "keywords": [{{"keyword": "...", "relevance": 0.9}}], "categories": ["科技数码"]}}]}}"""


_CATEGORIES_SET = frozenset(CONTENT_CATEGORIES)


def _try_repair_json(raw: str) -> dict | None:
    """Try to salvage partial JSON by truncating to the last complete extraction item."""
    # Find the last complete object boundary: "}, {" pattern for extraction items
    # Then close the array and outer object
    last_complete = raw.rfind('"categories"')
    if last_complete < 0:
        return None
    # Find the closing of that categories array: "]}"
    close_pos = raw.find("]}", last_complete)
    if close_pos < 0:
        return None
    truncated = raw[: close_pos + 2] + "]}"
    try:
        data = json.loads(truncated)
        log.info("keyword_extractor.json_repaired", salvaged_len=len(truncated), original_len=len(raw))
        return data
    except json.JSONDecodeError:
        return None


async def _llm_extract_batch(
    topics: list[NormalizedTopic],
    existing_keywords: set[str],
    cfg: AppConfig,
) -> dict[str, dict]:
    """Call LLM to extract keywords + categories for a batch of topics.

    Returns {topic_key: {"keywords": [{keyword, relevance}], "categories": [str]}}.
    """
    # Use numeric IDs instead of topic_keys in prompt to avoid JSON escaping issues
    idx_to_key = {str(i): t.topic_key for i, t in enumerate(topics)}
    topics_block = "\n".join(
        f"- [{i}] {t.title}" for i, t in enumerate(topics)
    )
    existing_sample = ", ".join(sorted(existing_keywords)[:50]) if existing_keywords else "(none)"

    prompt = _LLM_PROMPT_TEMPLATE.format(
        max_per_topic=TREND_KEYWORD_MAX_PER_TOPIC,
        existing_keywords=existing_sample,
        categories=_CATEGORIES_LIST,
        topics_block=topics_block,
    )

    raw = await call_llm(prompt, cfg.llm, system=_LLM_SYSTEM, temperature=TREND_LLM_TEMPERATURE)
    if not raw:
        return {}

    try:
        # Strip markdown fences and extract JSON object
        cleaned = raw.strip()
        if cleaned.startswith("```"):
            cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
            cleaned = re.sub(r"\s*```\s*$", "", cleaned)
        # Extract the outermost JSON object if there's trailing text
        brace_start = cleaned.find("{")
        if brace_start > 0:
            cleaned = cleaned[brace_start:]

        # Try parsing as-is first, then attempt repair on failure
        try:
            data = json.loads(cleaned)
        except json.JSONDecodeError:
            data = _try_repair_json(cleaned)
            if data is None:
                raise

        extractions = data.get("extractions", [])
        result: dict[str, dict] = {}
        for item in extractions:
            # Map numeric ID back to actual topic_key
            raw_tk = str(item.get("topic_key", ""))
            tk = idx_to_key.get(raw_tk)
            if tk is None:
                log.warning("keyword_extractor.invalid_topic_key", raw_topic_key=raw_tk)
                continue
            kws = item.get("keywords", [])
            valid_kws = []
            for kw in kws:
                keyword = kw.get("keyword", "").strip()
                relevance = float(kw.get("relevance", 1.0))
                if keyword and 2 <= len(keyword) <= 15 and keyword not in TREND_KEYWORD_STOPWORDS:
                    valid_kws.append({"keyword": keyword, "relevance": min(max(relevance, 0.0), 1.0)})

            # Validate categories against predefined set, max 3
            raw_cats = item.get("categories", [])
            categories = [c for c in raw_cats if c in _CATEGORIES_SET][:3]

            if valid_kws or categories:
                result[tk] = {
                    "keywords": valid_kws[:TREND_KEYWORD_MAX_PER_TOPIC],
                    "categories": categories,
                }
        return result
    except (json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
        log.warning(
            "keyword_extractor.llm_parse_error",
            error=str(exc),
            raw_len=len(raw),
            raw_start=raw[:100],
            raw_end=raw[-100:],
        )
        return {}


# ── Stage 3: Dedup ────────────────────────────────────────────────────

def _normalize_keyword_id(keyword: str) -> str:
    """Normalize keyword to a canonical ID for dedup."""
    # Strip whitespace, NFKC normalize, lowercase
    normalized = unicodedata.normalize("NFKC", keyword.strip()).lower()
    # Collapse whitespace
    normalized = re.sub(r"\s+", "", normalized)
    return normalized


async def _dedup_keywords(
    client: SupabaseClient,
    keywords: list[dict],
    cfg: AppConfig,
) -> list[dict]:
    """Deduplicate keywords against existing trend_keywords.

    Uses exact string matching only (fast). Embedding-based similarity is
    deferred to a background maintenance pass to avoid slowing the pipeline.
    """
    if not keywords:
        return []

    # Fetch existing keyword IDs for exact match
    try:
        existing = await client.select("trend_keywords", "keyword_id,keyword")
        existing_map = {row["keyword_id"]: row["keyword"] for row in existing}
    except Exception:
        existing_map = {}

    deduped: list[dict] = []
    seen_ids: set[str] = set()

    for kw in keywords:
        keyword = kw["keyword"]
        kid = _normalize_keyword_id(keyword)

        if kid in seen_ids:
            continue
        seen_ids.add(kid)

        if kid in existing_map:
            deduped.append({**kw, "keyword_id": kid, "is_new": False})
        else:
            deduped.append({**kw, "keyword_id": kid, "is_new": True})

    return deduped


# ── Public API ────────────────────────────────────────────────────────

async def extract_keywords_for_topics(
    client: SupabaseClient,
    topics: list[NormalizedTopic],
    cfg: AppConfig,
) -> dict[str, dict]:
    """Extract keywords + categories and deduplicate trend keywords for topics.

    Returns {topic_key: {"keywords": [{keyword_id, keyword, relevance, source, is_new}], "categories": [str]}}.
    """
    if not topics:
        return {}

    # Filter out topics that already have keywords (incremental extraction)
    try:
        linked_rows = await client.select("topic_trend_links", "topic_key")
        linked_keys = {row["topic_key"] for row in linked_rows}
        topics_to_extract = [t for t in topics if t.topic_key not in linked_keys]
        if len(topics_to_extract) < len(topics):
            log.info(
                "keyword_extractor.incremental_skip",
                total=len(topics),
                already_have=len(topics) - len(topics_to_extract),
                to_extract=len(topics_to_extract),
            )
        topics = topics_to_extract
    except Exception:
        pass  # On failure, process all topics as fallback

    if not topics:
        log.info("keyword_extractor.done", topics=0, total_keywords=0, new_keywords=0, categorized=0)
        return {}

    # Collect existing keywords for dedup hints
    try:
        existing_rows = await client.select("trend_keywords", "keyword_id", "is_active=eq.true")
        existing_keywords = {row["keyword_id"] for row in existing_rows}
    except Exception:
        existing_keywords = set()

    # LLM extraction (batched, with circuit breaker)
    merged_kw: dict[str, list[dict]] = {}
    merged_cat: dict[str, list[str]] = {}
    if cfg.llm.api_key:
        consecutive_failures = 0
        for i in range(0, len(topics), TREND_KEYWORD_BATCH_SIZE):
            if consecutive_failures >= 2:
                log.warning("keyword_extractor.llm_circuit_break", failures=consecutive_failures)
                break
            batch = topics[i : i + TREND_KEYWORD_BATCH_SIZE]
            batch_result = await _llm_extract_batch(batch, existing_keywords, cfg)
            if batch_result:
                consecutive_failures = 0
                for tk, extraction in batch_result.items():
                    kws = extraction.get("keywords", [])
                    merged_kw[tk] = [
                        {"keyword": kw["keyword"], "relevance": kw["relevance"], "source": "llm"}
                        for kw in kws
                    ][:TREND_KEYWORD_MAX_PER_TOPIC]
                    merged_cat[tk] = extraction.get("categories", [])
            else:
                consecutive_failures += 1
    else:
        log.warning("keyword_extractor.no_api_key")
        return {}

    # Dedup all collected keywords
    all_keywords = []
    for kws in merged_kw.values():
        all_keywords.extend(kws)

    deduped = await _dedup_keywords(client, all_keywords, cfg)
    deduped_lookup = {d["keyword"]: d for d in deduped}

    # Rebuild result with keyword_ids + categories
    result: dict[str, dict] = {}
    all_tks = set(merged_kw.keys()) | set(merged_cat.keys())
    for tk in all_tks:
        resolved: list[dict] = []
        for kw in merged_kw.get(tk, []):
            d = deduped_lookup.get(kw["keyword"])
            if d:
                resolved.append({
                    "keyword_id": d["keyword_id"],
                    "keyword": kw["keyword"],
                    "relevance": kw["relevance"],
                    "source": kw["source"],
                    "is_new": d.get("is_new", True),
                })
        categories = merged_cat.get(tk, [])
        if resolved or categories:
            result[tk] = {"keywords": resolved, "categories": categories}

    log.info(
        "keyword_extractor.done",
        topics=len(result),
        total_keywords=sum(len(v["keywords"]) for v in result.values()),
        new_keywords=sum(1 for d in deduped if d.get("is_new")),
        categorized=sum(1 for v in result.values() if v["categories"]),
    )
    return result


# ── Tag merging ──────────────────────────────────────────────────────

def merge_tags(
    topic: NormalizedTopic,
    extraction: dict | None,
) -> list[str]:
    """Merge LLM categories + keywords + platform tags into a deduplicated tag list.

    Priority order: categories → keyword texts → platform original tags (filtered).
    """
    seen: set[str] = set()
    tags: list[str] = []

    def _add(tag: str) -> None:
        if tag and tag not in seen:
            seen.add(tag)
            tags.append(tag)

    # 1. LLM categories (highest priority)
    if extraction:
        for cat in extraction.get("categories", []):
            _add(cat)

    # 2. Keyword texts
    if extraction:
        for kw in extraction.get("keywords", []):
            keyword = kw.get("keyword", "") if isinstance(kw, dict) else ""
            _add(keyword)

    # 3. Platform original tags (filter out douyin status labels)
    is_douyin = topic.platform_id == "douyin"
    for tag in topic.tags or []:
        if is_douyin and tag in DOUYIN_STATUS_LABELS:
            continue
        _add(tag)

    return tags
