"""CLI entry point — run / serve / cleanup."""

from __future__ import annotations

import asyncio

import click
import structlog

from trendlens.config import load_config
from trendlens.log_setup import setup_logging


@click.group()
def cli() -> None:
    """TrendLens data pipeline."""


@cli.command()
@click.option("-p", "--priority", multiple=True, default=["P0"], help="Priority tiers to fetch (P0, P1, P2)")
def run(priority: tuple[str, ...]) -> None:
    """Single pipeline run for the given priority tiers."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    priorities = [p.upper() for p in priority]
    log.info("pipeline.start", run_id=run_id, priorities=priorities)

    from trendlens.pipeline import run_cycle

    asyncio.run(run_cycle(cfg, run_id, priorities))
    log.info("pipeline.done", run_id=run_id)


@cli.command()
def serve() -> None:
    """Continuous mode — run pipeline every 15 minutes."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    log.info("scheduler.start", run_id=run_id)

    from trendlens.scheduler import start_scheduler

    start_scheduler(cfg)


@cli.command()
@click.option("-p", "--platform", multiple=True, default=[], help="Platform IDs to scrape (default: all)")
def scrape(platform: tuple[str, ...]) -> None:
    """Scrape content for topics that lack it."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    platform_ids = list(platform) if platform else None
    log.info("scrape.start", run_id=run_id, platforms=platform_ids)

    async def _run() -> None:
        from trendlens.scraping.scraper_manager import scrape_content
        from trendlens.storage.client import close_client, get_client

        client = await get_client(cfg)
        try:
            updated = await scrape_content(client, platform_ids)
            log.info("scrape.done", run_id=run_id, updated=updated)
        finally:
            await close_client()

    asyncio.run(_run())


@cli.command()
def cleanup() -> None:
    """Run database maintenance (cleanup old data)."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    log.info("cleanup.start", run_id=run_id)

    from trendlens.storage.maintenance import run_cleanup

    asyncio.run(run_cleanup(cfg))
    log.info("cleanup.done")
