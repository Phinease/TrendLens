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


@cli.command("extract-keywords")
@click.option("-n", "--limit", default=0, type=int, help="Max topics to process (0=all on-list)")
def extract_keywords(limit: int) -> None:
    """Extract trend keywords for existing topics."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    log.info("extract_keywords.start", run_id=run_id, limit=limit or "all")

    async def _run() -> None:
        from trendlens.processing.keyword_extractor import extract_keywords_for_topics, merge_tags
        from trendlens.processing.normalizer import normalize_topics
        from trendlens.storage.client import close_client, get_client
        from trendlens.storage.topic_store import batch_update_tags
        from trendlens.storage.trend_store import upsert_keywords, upsert_topic_trend_links

        client = await get_client(cfg)
        try:
            # Fetch on-list topics
            filters = "is_on_list=eq.true&order=heat_value.desc"
            if limit > 0:
                filters += f"&limit={limit}"
            rows = await client.select("topics", "*", filters)

            # Convert to NormalizedTopic
            from trendlens.models import NormalizedTopic

            topics = []
            for r in rows:
                topics.append(NormalizedTopic(
                    topic_key=r["topic_key"],
                    platform_id=r["platform_id"],
                    source_id=r.get("source_id"),
                    title=r["title"],
                    description=r.get("description"),
                    link=r.get("link"),
                    image_urls=r.get("image_urls", []),
                    tags=r.get("tags", []),
                    heat_value=r.get("heat_value", 0),
                    raw_heat_value=r.get("raw_heat_value"),
                    rank=r.get("rank", 0),
                    entities=r.get("entities", []),
                ))

            extraction_map = await extract_keywords_for_topics(client, topics, cfg)
            if extraction_map:
                kw_rows = []
                link_rows = []
                seen: set[str] = set()
                for tk, result in extraction_map.items():
                    for kw in result.get("keywords", []):
                        if kw["keyword_id"] not in seen and kw.get("is_new", True):
                            kw_rows.append({
                                "keyword_id": kw["keyword_id"],
                                "keyword": kw["keyword"],
                                "source": kw["source"],
                            })
                            seen.add(kw["keyword_id"])
                        link_rows.append({
                            "topic_key": tk,
                            "keyword_id": kw["keyword_id"],
                            "relevance": kw["relevance"],
                            "source": kw["source"],
                        })
                if kw_rows:
                    await upsert_keywords(client, kw_rows)
                if link_rows:
                    await upsert_topic_trend_links(client, link_rows)

            # Merge + write tags
            tag_updates: dict[str, list[str]] = {}
            for t in topics:
                extraction = extraction_map.get(t.topic_key) if extraction_map else None
                merged = merge_tags(t, extraction)
                if merged:
                    tag_updates[t.topic_key] = merged
            if tag_updates:
                await batch_update_tags(client, tag_updates)

            log.info(
                "extract_keywords.done",
                topics=len(extraction_map) if extraction_map else 0,
                tags_updated=len(tag_updates),
            )
        finally:
            await close_client()

    asyncio.run(_run())


@cli.command("collect-trends")
@click.option("--max-batches", default=20, type=int, help="Max Google Trends batches (5 keywords each)")
def collect_trends(max_batches: int) -> None:
    """Run one round of Google Trends data collection."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    log.info("collect_trends.start", run_id=run_id, max_batches=max_batches)

    async def _run() -> None:
        from trendlens.processing.trend_collector import collect_trend_data
        from trendlens.storage.client import close_client, get_client

        client = await get_client(cfg)
        try:
            points = await collect_trend_data(client, cfg, max_batches=max_batches)
            log.info("collect_trends.done", data_points=points)
        finally:
            await close_client()

    asyncio.run(_run())


@cli.command("filter-quality")
@click.option("-n", "--limit", default=0, type=int, help="Max topics to evaluate (0=all on-list)")
def filter_quality(limit: int) -> None:
    """Dry-run quality filter on existing on-list topics (shows what would be filtered)."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    log.info("filter_quality.start", run_id=run_id, limit=limit or "all")

    async def _run() -> None:
        from trendlens.models import NormalizedTopic
        from trendlens.processing.quality_filter import filter_topics_by_quality
        from trendlens.storage.client import close_client, get_client

        client = await get_client(cfg)
        try:
            filters = "is_on_list=eq.true&order=heat_value.desc"
            if limit > 0:
                filters += f"&limit={limit}"
            rows = await client.select("topics", "*", filters)

            topics = []
            for r in rows:
                topics.append(NormalizedTopic(
                    topic_key=r["topic_key"],
                    platform_id=r["platform_id"],
                    source_id=r.get("source_id"),
                    title=r["title"],
                    description=r.get("description"),
                    link=r.get("link"),
                    image_urls=r.get("image_urls", []),
                    tags=r.get("tags", []),
                    heat_value=r.get("heat_value", 0),
                    raw_heat_value=r.get("raw_heat_value"),
                    rank=r.get("rank", 0),
                    entities=r.get("entities", []),
                ))

            accepted = await filter_topics_by_quality(topics, cfg)
            accepted_keys = {t.topic_key for t in accepted}
            rejected = [t for t in topics if t.topic_key not in accepted_keys]

            click.echo(f"\nTotal: {len(topics)}, Accepted: {len(accepted)}, Rejected: {len(rejected)}")
            if rejected:
                click.echo("\nRejected topics:")
                for t in rejected:
                    click.echo(f"  [{t.platform_id}] {t.title}")
        finally:
            await close_client()

    asyncio.run(_run())


@cli.command("truncate-all")
@click.confirmation_option(prompt="This will DELETE ALL data from the database. Are you sure?")
def truncate_all() -> None:
    """Truncate all data tables (pre-launch reset)."""
    run_id = setup_logging()
    log = structlog.get_logger()
    cfg = load_config()
    log.info("truncate.start", run_id=run_id)

    async def _run() -> None:
        from trendlens.storage.client import close_client, get_client

        client = await get_client(cfg)
        try:
            # Delete order respects FK constraints (children first)
            # PostgREST: filter "pk_col=not.is.null" matches all rows
            tables = [
                ("topic_trend_links", "topic_key=not.is.null"),
                ("trend_data", "keyword_id=not.is.null"),
                ("trend_keywords", "keyword_id=not.is.null"),
                ("event_clusters", "cluster_id=not.is.null"),
                ("topic_embeddings", "topic_key=not.is.null"),
                ("snapshots_meta", "platform_id=not.is.null"),
                ("heat_history", "topic_key=not.is.null"),
                ("topics", "topic_key=not.is.null"),
            ]
            for table, match_all in tables:
                try:
                    await client.delete(table, match_all)
                    log.info("truncate.table_done", table=table)
                except Exception as exc:
                    log.error("truncate.table_error", table=table, error=str(exc))
            click.echo("All data tables truncated.")
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
