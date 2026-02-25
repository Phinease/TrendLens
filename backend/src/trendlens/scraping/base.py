"""BaseScraper ABC and auto-registration decorator (mirrors fetchers/base.py)."""

from __future__ import annotations

import abc
from dataclasses import dataclass
from typing import ClassVar

# Global registry: platform_id -> scraper class
_REGISTRY: dict[str, type[BaseScraper]] = {}


@dataclass(frozen=True, slots=True)
class ScrapeResult:
    """Result of scraping content for a single topic."""

    topic_key: str
    content: str | None = None
    error: str | None = None

    @property
    def ok(self) -> bool:
        return self.content is not None and self.error is None


class BaseScraper(abc.ABC):
    """Abstract base for all platform content scrapers."""

    platform_id: ClassVar[str]

    @abc.abstractmethod
    async def scrape(self, topic: dict) -> ScrapeResult:
        """Scrape content for a single topic.

        *topic* is a DB row dict with keys: topic_key, title, source_id, link, description.
        Implementations must catch all exceptions internally and return
        a ScrapeResult with an error field on failure.
        """


def register_scraper(cls: type[BaseScraper]) -> type[BaseScraper]:
    """Class decorator that registers a scraper in the global registry."""
    _REGISTRY[cls.platform_id] = cls
    return cls


def get_scrapers(platform_ids: list[str] | None = None) -> list[BaseScraper]:
    """Instantiate scrapers, optionally filtered by platform ID."""
    instances: list[BaseScraper] = []
    for pid, cls in _REGISTRY.items():
        if platform_ids is None or pid in platform_ids:
            instances.append(cls())
    return instances


def get_scraper_registry() -> dict[str, type[BaseScraper]]:
    return dict(_REGISTRY)
