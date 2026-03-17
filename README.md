<div align="center">

# agentping

```
    ___                    __  ____  _
   /   | ____ ____  ____  / /_/ __ \(_)___  ____ _
  / /| |/ __ `/ _ \/ __ \/ __/ /_/ / / __ \/ __ `/
 / ___ / /_/ /  __/ / / / /_/ ____/ / / / / /_/ /
/_/  |_\__, /\___/_/ /_/\__/_/   /_/_/ /_/\__, /
      /____/                             /____/
```

**Daily health check ping for AI coding CLI tools**

[![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)](#supported-platforms)
[![Shell: Bash](https://img.shields.io/badge/shell-bash-green)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

[![CLI: Claude](https://img.shields.io/badge/cli-claude-blueviolet)](https://docs.anthropic.com)
[![CLI: Codex](https://img.shields.io/badge/cli-codex-black)](https://github.com/openai/codex)
[![CLI: OpenCode](https://img.shields.io/badge/cli-opencode-orange)](https://github.com/opencode-ai/opencode)
[![CLI: Gemini](https://img.shields.io/badge/cli-gemini-4285F4)](https://github.com/google-gemini/gemini-cli)

</div>

---

## What it does

Sends a `ping` to your AI coding CLI (Claude, Codex, OpenCode, or Gemini) on a daily schedule. If the call fails, it retries up to 10 times with increasing backoff. Each run produces a timestamped log file.

## Supported CLIs

| CLI | Default Model | Tested |
|-----|---------------|--------|
| `claude` | `claude-opus-4-6` | Yes |
| `codex` | `gpt-5.4` | Yes |
| `opencode` | `claude-opus-4-6` | Yes |
| `gemini` | `gemini-3.1-pro-preview` | Yes |

## Supported Platforms

| Target | Scheduler | Status |
|--------|-----------|--------|
| macOS  | launchd   | Supported |
| Linux  | systemd   | Supported |

Tested on: Ubuntu, Debian, Alpine, Fedora, openSUSE, Kali, Rocky, CentOS, Amazon Linux, Oracle Linux, AlmaLinux, Gentoo

## Quickstart (for agents)

```bash
git clone https://github.com/hletrd/agentping.git && cd agentping && ./install.sh
```

That's it. Runs daily at 07:00 KST with Claude Opus by default. Edit `config.sh` to change CLI, model, or schedule.

## Slowstart (for humans)

### Prerequisites

- One of: [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Codex](https://github.com/openai/codex), [OpenCode](https://github.com/opencode-ai/opencode), or [Gemini CLI](https://github.com/google-gemini/gemini-cli) — installed and authenticated
- Bash 4+
- macOS (launchd) or Linux (systemd)

### 1. Clone

```bash
git clone https://github.com/hletrd/agentping.git
cd agentping
```

### 2. Configure (optional)

Edit `config.sh`:

```bash
# CLI tool: claude | codex | opencode | gemini
CLI="claude"

# Model
MODEL="claude-opus-4-6"

# Schedule (24h)
SCHEDULE_HOUR=7
SCHEDULE_MINUTE=0
SCHEDULE_TZ="Asia/Seoul"
```

### 3. Test manually

```bash
./agentping.sh
```

Check the output — you should see `OK:` followed by a response. A log file is created in `./logs/`.

### 4. Install the daily schedule

```bash
./install.sh
```

This registers a daily job using:
- **macOS**: `launchd` (via `~/Library/LaunchAgents/com.agentping.daily.plist`)
- **Linux**: `systemd` user timer (via `~/.config/systemd/user/agentping.timer`)

### 5. Check logs

```bash
ls logs/
# 20260314-070000.log

cat logs/20260314-070000.log
# [2026-03-14 07:00:00 KST] agentping: starting health check (cli=claude model=claude-opus-4-6)
# [2026-03-14 07:00:02 KST] attempt 1/10
# [2026-03-14 07:00:05 KST] OK: Pong!
```

### Uninstall

**macOS:**
```bash
launchctl bootout gui/$(id -u)/com.agentping.daily
rm ~/Library/LaunchAgents/com.agentping.daily.plist
```

**Linux:**
```bash
systemctl --user disable --now agentping.timer
rm ~/.config/systemd/user/agentping.{service,timer}
```

## Configuration

All settings in `config.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLI` | `claude` | CLI tool (`claude`, `codex`, `opencode`, `gemini`) |
| `MODEL` | `claude-opus-4-6` | Model name passed via `--model` |
| `SCHEDULE_HOUR` | `7` | Hour to run (24h) |
| `SCHEDULE_MINUTE` | `0` | Minute to run |
| `SCHEDULE_TZ` | `Asia/Seoul` | Timezone |
| `MAX_RETRIES` | `10` | Max retry attempts |
| `RETRY_DELAY` | `30` | Base delay between retries (seconds, multiplied by attempt) |
| `TIMEOUT` | `120` | Timeout per CLI call (seconds) |

## Testing

Run the cross-distro Docker test suite:

```bash
./test.sh
```

## License

MIT
