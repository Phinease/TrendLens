#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ROUNDS="${ROUNDS:-10}"
SLEEP_SECONDS="${SLEEP_SECONDS:-1800}"
MAX_BATCHES="${MAX_BATCHES:-20}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${ROOT_DIR}/logs/runs/trend_backfill_loop_${TIMESTAMP}.log"

mkdir -p "${ROOT_DIR}/logs/runs"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "trend_backfill_loop.start rounds=${ROUNDS} sleep_seconds=${SLEEP_SECONDS} max_batches=${MAX_BATCHES} log_file=${LOG_FILE}"

for ((round = 1; round <= ROUNDS; round++)); do
  echo "trend_backfill_loop.round_start round=${round} started_at=$(date '+%Y-%m-%d %H:%M:%S')"
  PYTHONPATH=src .venv/bin/python -m trendlens collect-trends --max-batches "${MAX_BATCHES}"
  echo "trend_backfill_loop.round_end round=${round} finished_at=$(date '+%Y-%m-%d %H:%M:%S')"

  if [[ "${round}" -lt "${ROUNDS}" ]]; then
    echo "trend_backfill_loop.sleep round=${round} seconds=${SLEEP_SECONDS}"
    sleep "${SLEEP_SECONDS}"
  fi
done

echo "trend_backfill_loop.done finished_at=$(date '+%Y-%m-%d %H:%M:%S')"
