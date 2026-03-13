"""Pipeline constants and thresholds."""

# ---------- Scheduling ----------
DEFAULT_FETCH_INTERVAL_MINUTES = 15

# ---------- HTTP ----------
HTTP_TIMEOUT_SECONDS = 30
HTTP_MAX_RETRIES = 3
HTTP_RETRY_BASE_SECONDS = 1.0
FETCH_CONCURRENCY_LIMIT = 5

# ---------- Heat normalisation ----------
HEAT_MAX = 10_000_000
HEAT_EXPONENT = 1.5

# ---------- Embedding ----------
EMBEDDING_BATCH_SIZE = 64
EMBEDDING_DIMENSIONS = 512

# ---------- Matching ----------
MATCH_ENTITY_WEIGHT = 0.3
MATCH_VECTOR_WEIGHT = 0.7
MATCH_THRESHOLD = 0.65
MATCH_ENTITY_STRONG = 0.5
MATCH_VECTOR_STRONG = 0.85
MATCH_STRONG_FLOOR = 0.8
MATCH_TIME_WINDOW_HOURS = 24
MATCH_VECTOR_CANDIDATE_THRESHOLD = 0.5

# ---------- Entity extraction ----------
ENTITY_POS_TAGS = frozenset({"nr", "ns", "nt", "nz", "nrt", "vn"})
ENTITY_MIN_LENGTH = 2

# ---------- Maintenance ----------
OFFLIST_RETENTION_DAYS = 90
HEAT_HISTORY_DETAIL_DAYS = 7
HEAT_HISTORY_MAX_DAYS = 90
SNAPSHOT_RETENTION_DAYS = 14

# ---------- Scraping ----------
SCRAPE_CONCURRENCY_LIMIT = 10
SCRAPE_TOP_N_PER_PLATFORM = 20
SCRAPE_CONTENT_MAX_LENGTH = 5000

# ---------- Database ----------
DB_POOL_MIN = 2
DB_POOL_MAX = 10

# ---------- Trend keyword stopwords ----------
# Loaded from data files at module init:
#   stopwords_zh.txt — 标准中文停用词表（哈工大+百度+cn 合并, ~1860 词）
#   trend_stopwords.txt — 趋势关键词领域补充词（可按需追加）

def _load_stopwords() -> frozenset[str]:
    """Load stopwords from data files (standard NLP list + trend domain supplement)."""
    from pathlib import Path
    data_dir = Path(__file__).parent / "data"
    words: set[str] = set()
    for filename in ("stopwords_zh.txt", "trend_stopwords.txt"):
        path = data_dir / filename
        if path.exists():
            with open(path, encoding="utf-8") as f:
                for line in f:
                    w = line.strip()
                    if w and not w.startswith("#"):
                        words.add(w)
    return frozenset(words)

TREND_KEYWORD_STOPWORDS: frozenset[str] = _load_stopwords()

# ---------- Trend data collection ----------
TREND_FETCH_INTERVAL_MINUTES = 60
TREND_KEYWORD_BATCH_SIZE = 10
TREND_GOOGLE_RATE_LIMIT_SECONDS = 65
TREND_GOOGLE_MAX_KW_PER_REQUEST = 5
TREND_GOOGLE_TIMEFRAME = "now 7-d"
TREND_KEYWORD_DEDUP_THRESHOLD = 0.85
TREND_KEYWORD_MAX_PER_TOPIC = 8
TREND_DATA_RETENTION_DAYS = 90
TREND_DATA_DETAIL_DAYS = 7
TREND_LLM_TEMPERATURE = 0.3

# ---------- Content categories (for LLM tag generation) ----------
CONTENT_CATEGORIES: tuple[str, ...] = (
    "社会民生", "国际政治", "财经商业", "科技数码", "娱乐明星",
    "影视综艺", "体育竞技", "游戏电竞", "教育考试", "健康医疗",
    "军事国防", "法律法治", "文化艺术", "生活消费", "自然灾害",
)

# Douyin status labels — not content categories, should be excluded from tags
DOUYIN_STATUS_LABELS: frozenset[str] = frozenset({"新", "推荐", "热", "爆", "首映"})

# ---------- Content quality filtering ----------
QUALITY_FILTER_BATCH_SIZE = 50    # topics per LLM call
QUALITY_LLM_TEMPERATURE = 0.1    # low temperature for deterministic judgement
