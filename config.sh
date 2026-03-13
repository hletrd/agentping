# agentping configuration

# CLI tool: claude | codex | opencode | gemini
CLI="claude"

# Model per CLI (used as --model argument)
MODEL="claude-opus-4-6"

# Schedule time (24h, used by install.sh)
SCHEDULE_HOUR=7
SCHEDULE_MINUTE=0
SCHEDULE_TZ="Asia/Seoul"

# Retry settings
MAX_RETRIES=10
RETRY_DELAY=30
TIMEOUT=120
