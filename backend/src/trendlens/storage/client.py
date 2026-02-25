"""Supabase PostgREST client — uses httpx so it works through HTTP/SOCKS proxies."""

from __future__ import annotations

from typing import Any

import httpx
import structlog

from trendlens.config import AppConfig

log = structlog.get_logger()

_client: SupabaseClient | None = None


class SupabaseClient:
    """Thin wrapper around Supabase PostgREST API via httpx."""

    def __init__(self, url: str, service_key: str) -> None:
        self.base_url = url.rstrip("/")
        self.rest_url = f"{self.base_url}/rest/v1"
        self._headers = {
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
            "Content-Type": "application/json",
        }
        self._http = httpx.AsyncClient(
            timeout=httpx.Timeout(30, connect=10),
            follow_redirects=True,
            headers=self._headers,
        )

    async def insert(
        self,
        table: str,
        rows: list[dict[str, Any]],
        *,
        upsert: bool = False,
        on_conflict: str | None = None,
        ignore_duplicates: bool = False,
    ) -> list[dict]:
        """Insert or upsert rows. Returns inserted rows."""
        headers = dict(self._headers)
        headers["Prefer"] = "return=representation"
        if upsert:
            resolution = "resolution=ignore-duplicates" if ignore_duplicates else "resolution=merge-duplicates"
            headers["Prefer"] = f"{resolution},return=representation"

        params = {}
        if on_conflict:
            params["on_conflict"] = on_conflict

        resp = await self._http.post(
            f"{self.rest_url}/{table}",
            json=rows,
            headers=headers,
            params=params,
        )
        if resp.status_code >= 400:
            log.error("postgrest.insert_error", table=table, status=resp.status_code, body=resp.text[:500])
        resp.raise_for_status()
        return resp.json()

    async def update(
        self,
        table: str,
        data: dict[str, Any],
        filters: str,
    ) -> list[dict]:
        """Update rows matching filters. filters is PostgREST query string."""
        headers = dict(self._headers)
        headers["Prefer"] = "return=representation"
        resp = await self._http.patch(
            f"{self.rest_url}/{table}?{filters}",
            json=data,
            headers=headers,
        )
        if resp.status_code >= 400:
            log.error("postgrest.update_error", table=table, status=resp.status_code, body=resp.text[:500])
        resp.raise_for_status()
        return resp.json()

    async def select(
        self,
        table: str,
        columns: str = "*",
        filters: str = "",
    ) -> list[dict]:
        """Select rows with optional filters."""
        url = f"{self.rest_url}/{table}?select={columns}"
        if filters:
            url += f"&{filters}"
        resp = await self._http.get(url, headers=self._headers)
        resp.raise_for_status()
        return resp.json()

    async def rpc(self, fn_name: str, params: dict[str, Any] | None = None) -> Any:
        """Call a Supabase RPC (database function)."""
        resp = await self._http.post(
            f"{self.rest_url}/rpc/{fn_name}",
            json=params or {},
            headers=self._headers,
        )
        resp.raise_for_status()
        return resp.json()

    async def close(self) -> None:
        await self._http.aclose()


async def get_client(cfg: AppConfig) -> SupabaseClient:
    """Get or create the shared Supabase client."""
    global _client
    if _client is not None:
        return _client

    log.info("supabase.connect", url=cfg.supabase_url)
    _client = SupabaseClient(cfg.supabase_url, cfg.service_role_key)
    return _client


async def close_client() -> None:
    """Close the shared client."""
    global _client
    if _client is not None:
        await _client.close()
        _client = None
        log.info("supabase.closed")
