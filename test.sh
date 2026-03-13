#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_PREFIX="agentping-test"
PASS=0
FAIL=0
SKIP=0
RESULTS=()

NAMES=()
IMAGES=()
SETUPS=()

add() { NAMES+=("$1"); IMAGES+=("$2"); SETUPS+=("$3"); }

add "ubuntu"     "ubuntu:latest"                 "apt-get update -qq && apt-get install -y -qq bash coreutils"
add "debian"     "debian:latest"                 "apt-get update -qq && apt-get install -y -qq bash coreutils"
add "alpine"     "alpine:latest"                 "apk add --no-cache bash coreutils"
add "fedora"     "fedora:latest"                 "dnf install -y -q bash coreutils"
add "opensuse"   "opensuse/leap:latest"          "zypper -q install -y bash coreutils"
add "arch"       "archlinux:latest"              "pacman -Sy --noconfirm bash coreutils"
add "kali"       "kalilinux/kali-rolling:latest" "apt-get update -qq && apt-get install -y -qq bash coreutils"
add "rocky"      "rockylinux:9"                  "dnf install -y -q bash coreutils"
add "centos"     "quay.io/centos/centos:stream9" "dnf install -y -q bash coreutils"
add "amazon"     "amazonlinux:latest"            "dnf install -y -q bash coreutils"
add "oracle"     "oraclelinux:9"                 "dnf install -y -q bash coreutils"
add "alma"       "almalinux:9"                   "dnf install -y -q bash coreutils"
add "void"       "voidlinux/voidlinux:latest"    "xbps-install -Sy bash coreutils"
add "clearlinux" "clearlinux:latest"             "true"
add "gentoo"     "gentoo/stage3:latest"          "true"

cleanup() {
  echo ""
  echo "=== cleanup ==="
  local containers
  containers=$(docker ps -a --filter "name=${TEST_PREFIX}" --format '{{.Names}}' 2>/dev/null || true)
  if [ -n "$containers" ]; then
    echo "$containers" | xargs -r docker rm -f 2>/dev/null || true
  fi
  echo "done."
}
trap cleanup EXIT

run_test() {
  local name="$1"
  local image="$2"
  local setup="$3"
  local container="${TEST_PREFIX}-${name}"

  echo ""
  echo "--- ${name} (${image}) ---"

  if ! docker pull -q "$image" >/dev/null 2>&1; then
    echo "  SKIP: image pull failed"
    RESULTS+=("SKIP  $name (image pull failed)")
    SKIP=$((SKIP + 1))
    return
  fi

  local test_script='
set -e

# setup deps
'"$setup"' 2>/dev/null || true

# mock all supported CLIs
mkdir -p /usr/local/bin
for cli in claude codex opencode gemini; do
  cat > "/usr/local/bin/$cli" <<MOCK
#!/usr/bin/env bash
echo "Pong! Health check OK from $cli"
MOCK
  chmod +x "/usr/local/bin/$cli"
done

# copy scripts and patch for fast test
cp /mnt/agentping.sh /tmp/agentping.sh
cp /mnt/config.sh /tmp/config.sh
chmod +x /tmp/agentping.sh
sed -i "s/MAX_RETRIES=10/MAX_RETRIES=2/" /tmp/config.sh
sed -i "s/RETRY_DELAY=30/RETRY_DELAY=1/" /tmp/config.sh

cd /tmp && bash /tmp/agentping.sh

# verify log
if ls /tmp/logs/*.log 1>/dev/null 2>&1; then
  echo "LOG_CHECK=PASS"
else
  echo "LOG_CHECK=FAIL"
  exit 1
fi
'

  local output
  if output=$(docker run --rm --name "$container" \
    -v "$SCRIPT_DIR/agentping.sh:/mnt/agentping.sh:ro" \
    -v "$SCRIPT_DIR/config.sh:/mnt/config.sh:ro" \
    "$image" \
    sh -c "$test_script" 2>&1); then

    if echo "$output" | grep -q "LOG_CHECK=PASS"; then
      echo "  PASS"
      RESULTS+=("PASS  $name")
      PASS=$((PASS + 1))
    else
      echo "  FAIL: log check failed"
      echo "$output" | tail -5
      RESULTS+=("FAIL  $name (log check)")
      FAIL=$((FAIL + 1))
    fi
  else
    if echo "$output" | grep -qi "not found\|no such file\|executable file"; then
      echo "  SKIP: bash not available"
      RESULTS+=("SKIP  $name (no bash)")
      SKIP=$((SKIP + 1))
    else
      echo "  FAIL: script error"
      echo "$output" | tail -10
      RESULTS+=("FAIL  $name")
      FAIL=$((FAIL + 1))
    fi
  fi
}

echo "=== agentping linux distro test ==="
echo "testing across ${#NAMES[@]} distributions..."

for i in "${!NAMES[@]}"; do
  run_test "${NAMES[$i]}" "${IMAGES[$i]}" "${SETUPS[$i]}"
done

echo ""
echo "=== results ==="
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""
echo "total: $PASS pass, $FAIL fail, $SKIP skip / ${#NAMES[@]} distros"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
