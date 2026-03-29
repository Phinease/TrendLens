"""APScheduler-based continuous mode."""

from __future__ import annotations

import asyncio

import structlog
from apscheduler.schedulers.blocking import BlockingScheduler

from trendlens.config import AppConfig
from trendlens.constants import DEFAULT_FETCH_INTERVAL_MINUTES, TREND_FETCH_INTERVAL_MINUTES
from trendlens.log_setup import setup_logging

log = structlog.get_logger()


def _run_cycle_sync(cfg: AppConfig) -> None:
    """Wrapper to run the async pipeline cycle from the scheduler."""
    run_id = setup_logging()
    log.info("scheduler.trigger", run_id=run_id)

    from trendlens.pipeline import run_cycle

    try:
        asyncio.run(run_cycle(cfg, run_id, ["P0"]))
    except Exception as exc:
        log.error("scheduler.cycle_error", error=str(exc))


def _run_trend_cycle_sync(cfg: AppConfig) -> None:
    """Wrapper to run the async trend collection cycle from the scheduler."""
    run_id = setup_logging()
    log.info("scheduler.trend_trigger", run_id=run_id)

    from trendlens.trend_pipeline import run_trend_cycle

    try:
        asyncio.run(run_trend_cycle(cfg, run_id))
    except Exception as exc:
        log.error("scheduler.trend_cycle_error", error=str(exc))


def start_scheduler(cfg: AppConfig) -> None:
    """Start the blocking scheduler that runs the pipeline periodically."""
    scheduler = BlockingScheduler()
    scheduler.add_job(
        _run_cycle_sync,
        "interval",
        minutes=DEFAULT_FETCH_INTERVAL_MINUTES,
        args=[cfg],
        id="pipeline_cycle",
        name="TrendLens pipeline cycle",
        max_instances=1,
    )

    # Register trend collection job if enabled
    if cfg.trend.enabled:
        scheduler.add_job(
            _run_trend_cycle_sync,
            "interval",
            minutes=TREND_FETCH_INTERVAL_MINUTES,
            args=[cfg],
            id="trend_cycle",
            name="TrendLens trend data collection",
            max_instances=1,
        )
        log.info("scheduler.trend_registered", interval_minutes=TREND_FETCH_INTERVAL_MINUTES)

    # Run once immediately
    _run_cycle_sync(cfg)
    if cfg.trend.enabled:
        _run_trend_cycle_sync(cfg)

    log.info("scheduler.running", interval_minutes=DEFAULT_FETCH_INTERVAL_MINUTES)
    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        log.info("scheduler.shutdown")
        scheduler.shutdown()
