# agentping

<div align="center">

```
    ___                    __  ____  _
   /   | ____ ____  ____  / /_/ __ \(_)___  ____ _
  / /| |/ __ `/ _ \/ __ \/ __/ /_/ / / __ \/ __ `/
 / ___ / /_/ /  __/ / / / /_/ ____/ / / / / /_/ /
/_/  |_\__, /\___/_/ /_/\__/_/   /_/_/ /_/\__, /
      /____/                             /____/
```

**Daily health check ping for Claude Code CLI**

[![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)](#installation)
[![Shell: Bash](https://img.shields.io/badge/shell-bash-green)](https://www.gnu.org/software/bash/)
[![Model: claude-opus-4-6](https://img.shields.io/badge/model-claude--opus--4--6-blueviolet)](https://docs.anthropic.com)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

</div>

---

## What it does

Sends a `ping` to the Claude Code CLI using the `claude-opus-4-6` model every day at **07:00 KST**. If the call fails, it retries up to 10 times with increasing backoff. Each run produces a timestamped log file.

## Status

| Target | Scheduler | Status |
|--------|-----------|--------|
| macOS  | launchd   | Supported |
| Linux  | systemd   | Supported |

## Quickstart (for agents)

```bash
git clone https://github.com/hletrd/agentping.git && cd agentping && ./install.sh
```

That's it. Runs daily at 07:00 KST. Logs in `./logs/`.

## Slowstart (for humans)

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Bash 4+
- macOS (launchd) or Linux (systemd)

### 1. Clone

```bash
git clone https://github.com/hletrd/agentping.git
cd agentping
```

### 2. Test manually

```bash
./agentping.sh
```

Check the output — you should see `OK:` followed by a response. A log file is created in `./logs/`.

### 3. Install the daily schedule

```bash
./install.sh
```

This registers a daily job at **07:00 KST** using:
- **macOS**: `launchd` (via `~/Library/LaunchAgents/com.agentping.daily.plist`)
- **Linux**: `systemd` user timer (via `~/.config/systemd/user/agentping.timer`)

### 4. Check logs

```bash
ls logs/
# 20260313-070001.log
# 20260314-070000.log

cat logs/20260314-070000.log
# [2026-03-14 07:00:00 KST] agentping: starting health check
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

Edit `agentping.sh` to change defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_RETRIES` | `10` | Max retry attempts |
| `RETRY_DELAY` | `30` | Base delay between retries (seconds, multiplied by attempt number) |
| `TIMEOUT` | `120` | Timeout per claude call (seconds) |

## License

MIT
