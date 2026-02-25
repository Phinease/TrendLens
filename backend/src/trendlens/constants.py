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
