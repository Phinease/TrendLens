"""BaseFetcher ABC and auto-registration decorator."""

from __future__ import annotations

import abc
from typing import ClassVar

from trendlens.models import FetchResult

# Global registry: platform_id -> fetcher class
_REGISTRY: dict[str, type[BaseFetcher]] = {}


class BaseFetcher(abc.ABC):
    """Abstract base for all platform fetchers."""

    platform_id: ClassVar[str]
    priority: ClassVar[str] = "P0"

    @abc.abstractmethod
    async def fetch(self) -> FetchResult:
        """Fetch trending topics from this platform.

        Implementations must catch all exceptions internally and return
        a FetchResult with an error field on failure.
        """


def register_fetcher(cls: type[BaseFetcher]) -> type[BaseFetcher]:
    """Class decorator that registers a fetcher in the global registry."""
    _REGISTRY[cls.platform_id] = cls
    return cls


def get_fetchers(priorities: list[str] | None = None) -> list[BaseFetcher]:
    """Instantiate fetchers, optionally filtered by priority tier."""
    instances: list[BaseFetcher] = []
    for cls in _REGISTRY.values():
        if priorities is None or cls.priority in priorities:
            instances.append(cls())
    return instances


def get_registry() -> dict[str, type[BaseFetcher]]:
    return dict(_REGISTRY)
