"""Structured logging with per-run log files."""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone
from pathlib import Path

import structlog

_LOGS_DIR = Path(__file__).resolve().parents[2] / "logs"


def setup_logging(run_id: str | None = None) -> str:
    """Configure structlog + stdlib logging. Returns the run_id."""
    if run_id is None:
        run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S") + "_" + uuid.uuid4().hex[:6]

    runs_dir = _LOGS_DIR / "runs"
    errors_dir = _LOGS_DIR / "errors"
    runs_dir.mkdir(parents=True, exist_ok=True)
    errors_dir.mkdir(parents=True, exist_ok=True)

    run_log_path = runs_dir / f"run_{run_id}.log"
    error_log_path = errors_dir / f"errors_{datetime.now(timezone.utc).strftime('%Y%m%d')}.log"

    # stdlib root logger
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)
    root.handlers.clear()

    fmt = logging.Formatter("%(asctime)s %(levelname)-8s %(message)s")

    # Console handler — INFO+
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(fmt)
    root.addHandler(console)

    # Run file handler — DEBUG+
    run_fh = logging.FileHandler(run_log_path, encoding="utf-8")
    run_fh.setLevel(logging.DEBUG)
    run_fh.setFormatter(fmt)
    root.addHandler(run_fh)

    # Error file handler — WARNING+
    err_fh = logging.FileHandler(error_log_path, encoding="utf-8")
    err_fh.setLevel(logging.WARNING)
    err_fh.setFormatter(fmt)
    root.addHandler(err_fh)

    # structlog configuration
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.stdlib.add_log_level,
            structlog.stdlib.add_logger_name,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    return run_id
