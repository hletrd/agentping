#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# load config
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
fi

SCHEDULE_HOUR="${SCHEDULE_HOUR:-7}"
SCHEDULE_MINUTE="${SCHEDULE_MINUTE:-0}"
SCHEDULE_TZ="${SCHEDULE_TZ:-Asia/Seoul}"

install_macos() {
  local PLIST_NAME="com.agentping.daily"
  local PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

  mkdir -p "$HOME/Library/LaunchAgents"
  launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true

  cat > "$PLIST_DST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$PLIST_NAME</string>
  <key>ProgramArguments</key>
  <array>
    <string>$SCRIPT_DIR/agentping.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$SCHEDULE_HOUR</integer>
    <key>Minute</key>
    <integer>$SCHEDULE_MINUTE</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$SCRIPT_DIR/logs/launchd.log</string>
  <key>StandardErrorPath</key>
  <string>$SCRIPT_DIR/logs/launchd.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
  </dict>
</dict>
</plist>
EOF

  launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"

  echo "installed (launchd). runs daily at $(printf '%02d:%02d' "$SCHEDULE_HOUR" "$SCHEDULE_MINUTE") $SCHEDULE_TZ."
  echo "uninstall: launchctl bootout gui/$(id -u)/$PLIST_NAME"
}

install_linux() {
  local SERVICE_DIR="$HOME/.config/systemd/user"
  mkdir -p "$SERVICE_DIR"

  cat > "$SERVICE_DIR/agentping.service" <<EOF
[Unit]
Description=agentping - AI CLI health check

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/agentping.sh
Environment=PATH=/usr/local/bin:/usr/bin:/bin
EOF

  cat > "$SERVICE_DIR/agentping.timer" <<EOF
[Unit]
Description=agentping daily at $(printf '%02d:%02d' "$SCHEDULE_HOUR" "$SCHEDULE_MINUTE") $SCHEDULE_TZ

[Timer]
OnCalendar=*-*-* $(printf '%02d:%02d:00' "$SCHEDULE_HOUR" "$SCHEDULE_MINUTE") $SCHEDULE_TZ
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now agentping.timer

  echo "installed (systemd). runs daily at $(printf '%02d:%02d' "$SCHEDULE_HOUR" "$SCHEDULE_MINUTE") $SCHEDULE_TZ."
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
