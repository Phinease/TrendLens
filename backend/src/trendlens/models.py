"""Core data models for the pipeline."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass(frozen=True, slots=True)
class RawTopic:
    """A single topic as parsed from a platform API."""

    platform_id: str
    title: str
    rank: int
    source_id: str | None = None
    description: str | None = None
    link: str | None = None
    image_urls: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    raw_heat: str | None = None
    heat_value: int | None = None


@dataclass(frozen=True, slots=True)
class FetchResult:
    """Result of a single fetcher run."""

    platform_id: str
    topics: list[RawTopic] = field(default_factory=list)
    fetched_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    duration_ms: int = 0
    error: str | None = None

    @property
    def ok(self) -> bool:
        return self.error is None and len(self.topics) > 0


@dataclass(slots=True)
class NormalizedTopic:
    """A topic after normalisation — ready for DB upsert."""

    topic_key: str
    platform_id: str
    source_id: str | None
    title: str
    description: str | None
    link: str | None
    image_urls: list[str]
    tags: list[str]
    heat_value: int
    raw_heat_value: str | None
    rank: int
    content: str | None = None
    entities: list[str] = field(default_factory=list)
    embedding: list[float] | None = None
    fetched_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
