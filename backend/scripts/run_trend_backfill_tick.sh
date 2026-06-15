#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

STATE_FILE="${ROOT_DIR}/logs/runs/trend_backfill_schedule.state"
LOCK_DIR="${ROOT_DIR}/logs/runs/trend_backfill_schedule.lock"
LOG_FILE="${ROOT_DIR}/logs/runs/trend_backfill_schedule.log"
ROUNDS="${ROUNDS:-10}"
MAX_BATCHES="${MAX_BATCHES:-20}"

mkdir -p "${ROOT_DIR}/logs/runs"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "trend_backfill_tick.skip reason=lock_exists at=$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
  exit 0
fi

cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

if [[ ! -f "$STATE_FILE" ]]; then
  echo "$ROUNDS" > "$STATE_FILE"
fi

remaining="$(tr -d '[:space:]' < "$STATE_FILE")"
if [[ -z "$remaining" ]]; then
  remaining="$ROUNDS"
fi

if (( remaining <= 0 )); then
  echo "trend_backfill_tick.done remaining=${remaining} at=$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
  exit 0
fi

current_round=$((ROUNDS - remaining + 1))
echo "trend_backfill_tick.start round=${current_round} remaining_before=${remaining} at=$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"

PYTHONPATH=src .venv/bin/python -m trendlens collect-trends --max-batches "${MAX_BATCHES}" >> "$LOG_FILE" 2>&1

remaining=$((remaining - 1))
echo "$remaining" > "$STATE_FILE"
echo "trend_backfill_tick.end round=${current_round} remaining_after=${remaining} at=$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
