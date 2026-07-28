#!/bin/bash
# 02-host-dependencies: install OpenWrt build deps for Ubuntu 22.04
set -euo pipefail

PROJECT_DIR="/root/project"
LOG="${PROJECT_DIR}/logs/02-host-dependencies.log"

mkdir -p "${PROJECT_DIR}/logs"
exec > >(tee "$LOG") 2>&1

echo "=== 02-host-dependencies ==="
echo "Started: $(date -Iseconds)"
echo ""

# Complete dependency list per OpenWrt official build requirements (Ubuntu 22.04)
PACKAGES=(
  build-essential
  clang
  flex
  bison
  g++
  gawk
  gcc-multilib
  g++-multilib
  gettext
  git
  libncurses5-dev
  libssl-dev
  python3
  python3-distutils
  python3-setuptools
  rsync
  unzip
  zlib1g-dev
  file
  wget
  libelf-dev
  dwarves
  quilt
  subversion
  swig
  time
  xsltproc
  bc
  lib32gcc-s1
  lib32stdc++6
  cpio
  xz-utils
  patch
  make
  cmake
  pkg-config
  perl
  python3-dev
)

echo "--- Dependency List (${#PACKAGES[@]} packages) ---"
printf '%s\n' "${PACKAGES[@]}"
echo ""

echo "--- Pre-install disk ---"
df -h /

echo ""
echo "--- apt update ---"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

echo ""
echo "--- apt install (single batch) ---"
apt-get install -y --no-install-recommends "${PACKAGES[@]}"

echo ""
echo "--- Verify required commands ---"
REQUIRED_CMDS=(
  gcc g++ make patch flex bison gawk git rsync wget unzip
  python3 perl quilt svn swig xsltproc bc curl
  nm objcopy strip readelf
)
MISSING=0
for cmd in "${REQUIRED_CMDS[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd -> $(command -v "$cmd")"
  else
    echo "[MISSING] $cmd"
    MISSING=$((MISSING+1))
  fi
done

# pahole from dwarves
if command -v pahole >/dev/null; then
  echo "[OK] pahole -> $(command -v pahole)"
else
  echo "[MISSING] pahole (from dwarves)"
  MISSING=$((MISSING+1))
fi

echo ""
echo "--- Post-install disk ---"
df -h /

echo ""
if [ "$MISSING" -eq 0 ]; then
  echo "[PASS] All required commands available"
  echo "Finished: $(date -Iseconds)"
  exit 0
else
  echo "[FAIL] $MISSING command(s) missing"
  echo "Finished: $(date -Iseconds)"
  exit 1
fi
