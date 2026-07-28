#!/bin/bash
# 01-preflight checks for Yaxiang OS build
set -euo pipefail

PROJECT_DIR="/root/project"
LOG="${PROJECT_DIR}/logs/01-preflight.log"
BUILD_ROOT="/home/builder/yaxiang-build"
OPENWRT_COMMIT="f5dae5ece4805730c5e2850f8aa84765af2f6b32"

mkdir -p "${PROJECT_DIR}/logs"
exec > >(tee "$LOG") 2>&1

echo "=== 01-preflight ==="
echo "Started: $(date -Iseconds)"
echo ""

PASS=0
FAIL=0
warn() { echo "[WARN] $*"; }
pass() { echo "[PASS] $*"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $*"; FAIL=$((FAIL+1)); }

# Git
echo "--- Git ---"
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current)
HEAD=$(git -C "$PROJECT_DIR" rev-parse HEAD)
ORIGIN_MAIN=$(git -C "$PROJECT_DIR" rev-parse origin/main 2>/dev/null || echo "unavailable")
echo "Branch: $BRANCH"
echo "HEAD: $HEAD"
echo "origin/main: $ORIGIN_MAIN"
[ "$BRANCH" = "recovery/source-changes-20260728" ] && pass "branch ok" || fail "unexpected branch: $BRANCH"

# CVE patches
echo ""
echo "--- CVE Patches ---"
PATCH_DIR="${PROJECT_DIR}/openwrt/kernel-patches/6.12"
COUNT=$(ls "$PATCH_DIR"/*.patch 2>/dev/null | wc -l)
echo "Count: $COUNT"
[ "$COUNT" -eq 11 ] && pass "11 CVE patches present" || fail "expected 11 patches, got $COUNT"
sha256sum "$PATCH_DIR"/*.patch | sort

# Security config
echo ""
echo "--- x86_64-security.config ---"
CONFIG="${PROJECT_DIR}/openwrt/configs/x86_64-security.config"
if [ -f "$CONFIG" ]; then
  LINES=$(wc -l < "$CONFIG")
  echo "Lines: $LINES"
  pass "x86_64-security.config exists ($LINES lines)"
else
  fail "x86_64-security.config missing"
fi

# CPU / memory / disk
echo ""
echo "--- Hardware ---"
echo "CPU cores: $(nproc)"
echo "Architecture: $(uname -m)"
free -h
df -h /
AVAIL_GB=$(df -BG / | awk 'NR==2 {gsub(/G/,"",$4); print $4}')
echo "Available disk: ${AVAIL_GB}GB"
[ "$AVAIL_GB" -ge 8 ] && pass "disk >= 8GB threshold" || fail "disk below 8GB"
[ "$AVAIL_GB" -ge 24 ] && pass "disk >= 24GB for source-checkout" || warn "disk below 24GB for source-checkout gate"

# OS
echo ""
echo "--- OS ---"
lsb_release -a 2>/dev/null || cat /etc/os-release

# Paths with spaces
echo ""
echo "--- Build Paths ---"
for p in "$PROJECT_DIR" "$BUILD_ROOT"; do
  if [[ "$p" == *" "* ]]; then
    fail "path contains space: $p"
  else
    pass "no spaces in path: $p"
  fi
done

# Time
echo ""
echo "--- Time ---"
timedatectl 2>/dev/null || { date; cat /etc/timezone 2>/dev/null; }

# tmux
echo ""
echo "--- tmux ---"
if command -v tmux >/dev/null; then
  tmux -V
  pass "tmux available"
else
  fail "tmux not found"
fi

# Network connectivity
echo ""
echo "--- Network Connectivity ---"
check_url() {
  local name="$1" url="$2"
  if curl -fsSL --connect-timeout 10 --max-time 20 -o /dev/null "$url"; then
    pass "$name reachable: $url"
  else
    fail "$name unreachable: $url"
  fi
}
check_url "GitHub" "https://github.com"
check_url "OpenWrt git" "https://git.openwrt.org"
check_url "Ubuntu archive" "http://archive.ubuntu.com/ubuntu/dists/jammy/Release"

# OpenWrt commit pin
echo ""
echo "--- OpenWrt Pin ---"
echo "Target commit: $OPENWRT_COMMIT"

echo ""
echo "=== Summary ==="
echo "PASS: $PASS  FAIL: $FAIL"
echo "Finished: $(date -Iseconds)"

[ "$FAIL" -eq 0 ]
