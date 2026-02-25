"""Topic normalisation — topic_key generation, heat normalisation, title cleanup."""

from __future__ import annotations

import hashlib
import re

from trendlens.constants import HEAT_EXPONENT, HEAT_MAX
from trendlens.models import NormalizedTopic, RawTopic


# ── Title normalisation (data-storage-strategy §2.4) ─────────────────────

def normalize_title(title: str) -> str:
    """Normalise title for hashing and matching."""
    text = title.strip()
    text = re.sub(r"^[#【\[「]|[#】\]」]$", "", text)
    text = re.sub(r"\s+", "", text)
    text = re.sub(r"[^\u4e00-\u9fff\u3400-\u4dbfa-zA-Z0-9]", "", text)
    return text.lower()


# ── Topic key generation (data-storage-strategy §2, three-level fallback) ─

def generate_topic_key(platform_id: str, source_id: str | None, title: str) -> str:
    """Three-level fallback: source_id → title hash."""
    if source_id:
        return f"{platform_id}:{source_id}"
    normalized = normalize_title(title)
    h = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:16]
    return f"{platform_id}:title:{h}"


# ── Heat normalisation (data-storage-strategy §8) ───────────────────────

def normalize_heat(rank: int, total: int, raw_heat: int | None = None) -> int:
    """Normalise heat to 0..10,000,000 via rank-based exponential mapping."""
    if total == 0:
        return 0
    position_ratio = (total - rank + 1) / total
    heat = int(HEAT_MAX * (position_ratio ** HEAT_EXPONENT))
    return max(heat, 1)


# ── Batch normalisation ──────────────────────────────────────────────────

def normalize_topics(raw_topics: list[RawTopic]) -> list[NormalizedTopic]:
    """Convert a list of RawTopic into NormalizedTopic with keys and heat."""
    total = len(raw_topics)
    results: list[NormalizedTopic] = []
    for rt in raw_topics:
        topic_key = generate_topic_key(rt.platform_id, rt.source_id, rt.title)
        heat = normalize_heat(rt.rank, total, rt.heat_value)
        results.append(
            NormalizedTopic(
                topic_key=topic_key,
                platform_id=rt.platform_id,
                source_id=rt.source_id,
                title=rt.title,
                description=rt.description,
                link=rt.link,
                image_urls=list(rt.image_urls),
                tags=list(rt.tags),
                heat_value=heat,
                raw_heat_value=rt.raw_heat,
                rank=rt.rank,
                fetched_at=rt.fetched_at if hasattr(rt, "fetched_at") else None,  # type: ignore[arg-type]
            )
        )
    return results
