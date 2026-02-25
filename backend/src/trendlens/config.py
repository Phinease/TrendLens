"""Configuration loader — YAML + environment variable overrides."""

from __future__ import annotations

import os
from pathlib import Path

import yaml
from pydantic import BaseModel, Field

_CONFIG_DIR = Path(__file__).resolve().parents[2] / "config"


class DatabaseConfig(BaseModel):
    host: str = "localhost"
    port: int = 5432
    name: str = "postgres"
    user: str = "postgres"
    password: str = ""
    direct_url: str = ""


class JinaConfig(BaseModel):
    api_key: str = ""
    model: str = "jina-embeddings-v3"
    dimensions: int = 512
    task: str = "text-matching"
    endpoint: str = "https://api.jina.ai/v1/embeddings"


class AppConfig(BaseModel):
    supabase_url: str = ""
    service_role_key: str = ""
    database: DatabaseConfig = Field(default_factory=DatabaseConfig)
    jina: JinaConfig = Field(default_factory=JinaConfig)


def load_config(config_path: Path | None = None) -> AppConfig:
    """Load config from YAML then apply TRENDLENS_* env overrides."""
    path = config_path or _CONFIG_DIR / "supabase.yaml"
    raw: dict = {}
    if path.exists():
        with open(path) as f:
            raw = yaml.safe_load(f) or {}

    project = raw.get("project", {})
    keys = raw.get("keys", {})
    db_raw = raw.get("database", {})
    jina_raw = raw.get("jina", {})

    db = DatabaseConfig(
        host=os.getenv("TRENDLENS_DB_HOST", db_raw.get("host", "")),
        port=int(os.getenv("TRENDLENS_DB_PORT", db_raw.get("port", 5432))),
        name=os.getenv("TRENDLENS_DB_NAME", db_raw.get("name", "postgres")),
        user=os.getenv("TRENDLENS_DB_USER", db_raw.get("user", "postgres")),
        password=os.getenv("TRENDLENS_DB_PASSWORD", db_raw.get("password", "")),
        direct_url=os.getenv("TRENDLENS_DB_URL", db_raw.get("direct_url", "")),
    )

    jina = JinaConfig(
        api_key=os.getenv("TRENDLENS_JINA_KEY", jina_raw.get("api_key", "")),
        model=jina_raw.get("model", "jina-embeddings-v3"),
        dimensions=int(jina_raw.get("dimensions", 512)),
        task=jina_raw.get("task", "text-matching"),
        endpoint=jina_raw.get("endpoint", "https://api.jina.ai/v1/embeddings"),
    )

    return AppConfig(
        supabase_url=os.getenv("TRENDLENS_SUPABASE_URL", project.get("url", "")),
        service_role_key=os.getenv("TRENDLENS_SERVICE_KEY", keys.get("service_role", "")),
        database=db,
        jina=jina,
    )
