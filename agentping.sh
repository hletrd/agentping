#!/usr/bin/env bash
set -euo pipefail

MAX_RETRIES=10
RETRY_DELAY=30
TIMEOUT=120
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/$(TZ=Asia/Seoul date '+%Y%m%d-%H%M%S').log"

mkdir -p "$LOG_DIR"

# cross-platform timeout
if command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
else
  TIMEOUT_CMD=""
fi

run_claude() {
  if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD "$TIMEOUT" claude -p "ping" --model claude-opus-4-6 2>&1
  else
    claude -p "ping" --model claude-opus-4-6 2>&1
  fi
}

log() {
  echo "[$(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M:%S KST')] $*" | tee -a "$LOG_FILE"
}

main() {
  log "agentping: starting health check"

  for attempt in $(seq 1 "$MAX_RETRIES"); do
    log "attempt $attempt/$MAX_RETRIES"

    if response=$(run_claude); then
      log "OK: ${response:0:200}"
      exit 0
    else
      rc=$?
      log "FAIL (exit=$rc): ${response:0:200}"
      if [ "$attempt" -lt "$MAX_RETRIES" ]; then
        delay=$((RETRY_DELAY * attempt))
        log "retrying in ${delay}s..."
        sleep "$delay"
      fi
    fi
  done

  log "FAIL: all $MAX_RETRIES attempts exhausted"
  exit 1
}

main
