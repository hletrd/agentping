#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# load config
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
fi

# defaults
CLI="${CLI:-claude}"
MODEL="${MODEL:-claude-opus-4-6}"
MAX_RETRIES="${MAX_RETRIES:-10}"
RETRY_DELAY="${RETRY_DELAY:-30}"
TIMEOUT="${TIMEOUT:-120}"
SCHEDULE_TZ="${SCHEDULE_TZ:-Asia/Seoul}"

LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/$(TZ="$SCHEDULE_TZ" date '+%Y%m%d-%H%M%S').log"

mkdir -p "$LOG_DIR"

# cross-platform timeout
if command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
else
  TIMEOUT_CMD=""
fi

run_ping() {
  local cmd
  case "$CLI" in
    claude)
      cmd="claude -p ping --model $MODEL" ;;
    codex)
      cmd="codex -q ping --model $MODEL" ;;
    opencode)
      cmd="opencode -p ping --model $MODEL" ;;
    gemini)
      cmd="gemini -p ping --model $MODEL" ;;
    *)
      cmd="$CLI -p ping --model $MODEL" ;;
  esac

  if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD "$TIMEOUT" $cmd 2>&1
  else
    $cmd 2>&1
  fi
}

log() {
  echo "[$(TZ="$SCHEDULE_TZ" date '+%Y-%m-%d %H:%M:%S %Z')] $*" | tee -a "$LOG_FILE"
}

main() {
  log "agentping: starting health check (cli=$CLI model=$MODEL)"

  for attempt in $(seq 1 "$MAX_RETRIES"); do
    log "attempt $attempt/$MAX_RETRIES"

    if response=$(run_ping); then
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
