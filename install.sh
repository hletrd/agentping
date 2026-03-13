#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

install_macos() {
  local PLIST_NAME="com.agentping.daily"
  local PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME.plist"
  local PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

  mkdir -p "$HOME/Library/LaunchAgents"
  launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true
  cp "$PLIST_SRC" "$PLIST_DST"
  launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"

  echo "installed (launchd). runs daily at 07:00 KST."
  echo "uninstall: launchctl bootout gui/$(id -u)/$PLIST_NAME"
}

install_linux() {
  local SERVICE_DIR="$HOME/.config/systemd/user"
  mkdir -p "$SERVICE_DIR"

  cat > "$SERVICE_DIR/agentping.service" <<EOF
[Unit]
Description=agentping - Claude Code health check

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/agentping.sh
Environment=PATH=/usr/local/bin:/usr/bin:/bin
EOF

  cat > "$SERVICE_DIR/agentping.timer" <<EOF
[Unit]
Description=agentping daily at 07:00 KST

[Timer]
OnCalendar=*-*-* 07:00:00 Asia/Seoul
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now agentping.timer

  echo "installed (systemd). runs daily at 07:00 KST."
  echo "uninstall: systemctl --user disable --now agentping.timer"
}

echo "installing agentping..."
chmod +x "$SCRIPT_DIR/agentping.sh"
mkdir -p "$SCRIPT_DIR/logs"

case "$(uname -s)" in
  Darwin) install_macos ;;
  Linux)  install_linux ;;
  *)      echo "unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "logs: $SCRIPT_DIR/logs/"
echo "manual test: ./agentping.sh"
