"""HTML processing utilities for content scraping."""

from __future__ import annotations

import json
import re

from trendlens.constants import SCRAPE_CONTENT_MAX_LENGTH


def html_to_text(html: str) -> str:
    """Convert HTML to plain text — strip tags, collapse whitespace."""
    # Remove script and style blocks
    text = re.sub(r"<(script|style)[^>]*>.*?</\1>", "", html, flags=re.DOTALL | re.IGNORECASE)
    # Replace <br>, <p>, <div> with newlines
    text = re.sub(r"<(?:br|/p|/div|/li|/h[1-6])[^>]*>", "\n", text, flags=re.IGNORECASE)
    # Strip remaining tags
    text = re.sub(r"<[^>]+>", "", text)
    # Decode common HTML entities
    text = text.replace("&nbsp;", " ").replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"')
    # Collapse whitespace
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def extract_json_from_html(html: str, pattern: str) -> dict | None:
    """Extract a JSON object from HTML using a regex pattern.

    The *pattern* must contain a capture group for the JSON string.
    Returns the parsed dict, or None if not found / parse error.
    """
    m = re.search(pattern, html, re.DOTALL)
    if not m:
        return None
    try:
        return json.loads(m.group(1))
    except (json.JSONDecodeError, IndexError):
        return None


def truncate(text: str, max_length: int = SCRAPE_CONTENT_MAX_LENGTH) -> str:
    """Truncate text to *max_length* characters, appending '…' if truncated."""
    if len(text) <= max_length:
        return text
    return text[:max_length - 1] + "…"


def clean_content(text: str | None) -> str | None:
    """Normalize whitespace and truncate. Returns None for empty input."""
    if not text:
        return None
    text = text.strip()
    if not text:
        return None
    return truncate(text)
