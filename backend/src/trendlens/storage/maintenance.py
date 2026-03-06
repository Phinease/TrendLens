"""Database maintenance via Supabase RPC.

Note: Complex cleanup queries require a database function.
For now, we handle simple deletions via PostgREST filters.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

import structlog

from trendlens.config import AppConfig
from trendlens.constants import (
    OFFLIST_RETENTION_DAYS,
    SNAPSHOT_RETENTION_DAYS,
    TREND_DATA_RETENTION_DAYS,
)
from trendlens.storage.client import close_client, get_client

log = structlog.get_logger()


async def run_cleanup(cfg: AppConfig) -> None:
    """Execute maintenance tasks via PostgREST."""
    client = await get_client(cfg)
    now = datetime.now(timezone.utc)

    try:
        # 1. Delete old snapshots
        cutoff_snapshots = (now - timedelta(days=SNAPSHOT_RETENTION_DAYS)).isoformat()
        try:
            await client._http.delete(
                f"{client.rest_url}/snapshots_meta?fetched_at=lt.{cutoff_snapshots}",
                headers=client._headers,
            )
            log.info("maintenance.snapshots_cleaned", cutoff=cutoff_snapshots)
        except Exception as exc:
            log.error("maintenance.snapshots_error", error=str(exc))

        # 2. Deactivate clusters with no active topics
        try:
            await client.rpc("deactivate_stale_clusters", {})
        except Exception:
            log.warning("maintenance.rpc_not_available", fn="deactivate_stale_clusters")

        # 3. Delete old off-list topics
        cutoff_offlist = (now - timedelta(days=OFFLIST_RETENTION_DAYS)).isoformat()
        try:
            await client._http.delete(
                f"{client.rest_url}/topics?is_on_list=eq.false&last_seen_at=lt.{cutoff_offlist}",
                headers=client._headers,
            )
            log.info("maintenance.offlist_cleaned", cutoff=cutoff_offlist)
        except Exception as exc:
            log.error("maintenance.offlist_error", error=str(exc))

        # 4. Trend data cleanup
        try:
            from trendlens.storage.trend_store import cleanup_trend_data
            await cleanup_trend_data(client, TREND_DATA_RETENTION_DAYS)
            log.info("maintenance.trend_data_cleaned")
        except Exception as exc:
            log.error("maintenance.trend_data_error", error=str(exc))

        log.info("maintenance.done")
    finally:
        await close_client()
