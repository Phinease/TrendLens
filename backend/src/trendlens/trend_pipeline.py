"""Independent trend data collection cycle (runs every 60 minutes)."""

from __future__ import annotations

import structlog

from trendlens.config import AppConfig
from trendlens.storage.client import close_client, get_client

log = structlog.get_logger()


async def run_trend_cycle(cfg: AppConfig, run_id: str) -> None:
    """Execute one trend data collection cycle."""
    log.info("trend_cycle.start", run_id=run_id)

    from trendlens.processing.trend_collector import collect_trend_data

    client = await get_client(cfg)
    try:
        data_points = await collect_trend_data(client, cfg)
        log.info("trend_cycle.done", run_id=run_id, data_points=data_points)
    except Exception as exc:
        log.error("trend_cycle.error", run_id=run_id, error=str(exc))
    finally:
        await close_client()
