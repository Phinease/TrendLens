"""Named entity extraction using jieba POS tagging."""

from __future__ import annotations

import jieba.posseg as pseg

from trendlens.constants import ENTITY_MIN_LENGTH, ENTITY_POS_TAGS
from trendlens.models import NormalizedTopic


def extract_entities(title: str) -> list[str]:
    """Extract named entities from a Chinese title using jieba POS tagging."""
    entities: set[str] = set()
    for word, flag in pseg.cut(title):
        if flag in ENTITY_POS_TAGS and len(word) >= ENTITY_MIN_LENGTH:
            entities.add(word)
    return sorted(entities)


def enrich_entities(topics: list[NormalizedTopic]) -> None:
    """Add entities to each topic in-place."""
    for topic in topics:
        topic.entities = extract_entities(topic.title)
