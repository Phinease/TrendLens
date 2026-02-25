"""Union-Find (Disjoint Set Union) for clustering."""

from __future__ import annotations


class UnionFind:
    """Union-Find with path compression and union by rank."""

    def __init__(self) -> None:
        self._parent: dict[str, str] = {}
        self._rank: dict[str, int] = {}

    def find(self, x: str) -> str:
        if x not in self._parent:
            self._parent[x] = x
            self._rank[x] = 0
        if self._parent[x] != x:
            self._parent[x] = self.find(self._parent[x])
        return self._parent[x]

    def union(self, x: str, y: str) -> str:
        """Union two sets. Returns the root."""
        rx, ry = self.find(x), self.find(y)
        if rx == ry:
            return rx
        if self._rank[rx] < self._rank[ry]:
            rx, ry = ry, rx
        self._parent[ry] = rx
        if self._rank[rx] == self._rank[ry]:
            self._rank[rx] += 1
        return rx

    def groups(self) -> dict[str, list[str]]:
        """Return mapping of root -> list of members."""
        result: dict[str, list[str]] = {}
        for x in self._parent:
            root = self.find(x)
            result.setdefault(root, []).append(x)
        return result
