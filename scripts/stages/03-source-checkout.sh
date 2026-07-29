#!/bin/bash
# 03-source-checkout: create builder user and clone OpenWrt source
set -Eeuo pipefail

PROJECT_DIR="/root/project"
LOG="${PROJECT_DIR}/logs/03-source-checkout.log"
BUILD_ROOT="/home/builder/yaxiang-build"
OPENWRT_DIR="${BUILD_ROOT}/openwrt"
OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
OPENWRT_TARGET_COMMIT="f5dae5ece4805730c5e2850f8aa84765af2f6b32"
MIN_DISK_GB=24

mkdir -p "${PROJECT_DIR}/logs"
exec > >(tee "$LOG") 2>&1

echo "=== 03-source-checkout ==="
echo "Started: $(date -Iseconds)"
echo ""

PASS=0
FAIL=0
warn() { echo "[WARN] $*"; }
pass() { echo "[PASS] $*"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $*"; FAIL=$((FAIL+1)); }

# Error handler function - preserve exit code and show context
on_error() {
  local rc="$1"
  local line="$2"
  local cmd="$3"
  trap - ERR
  printf '[ERROR] Command failed: %s\n' "$cmd"
  printf '[ERROR] Line: %s, Exit code: %s\n' "$line" "$rc"
  exit "$rc"
}

trap 'on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

# Pre-flight checks
echo "--- Pre-flight Checks ---"

# Check Linux environment
if [ "$(uname -s)" != "Linux" ]; then
  fail "Must run on Linux (current: $(uname -s))"
  echo "Finished: $(date -Iseconds)"
  exit 1
fi
pass "Linux environment detected"

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
  fail "Must run as root (current UID: $(id -u))"
  echo "Finished: $(date -Iseconds)"
  exit 1
fi
pass "Running as root"

# Check git availability
if ! command -v git >/dev/null 2>&1; then
  fail "git command not found"
  echo "Finished: $(date -Iseconds)"
  exit 1
fi
pass "git available: $(git --version | head -1)"

# Check sudo availability
if ! command -v sudo >/dev/null 2>&1; then
  fail "sudo command not found"
  echo "Finished: $(date -Iseconds)"
  exit 1
fi
pass "sudo available: $(sudo --version | head -1)"

echo ""
echo "--- Builder User Management ---"

# Check if builder user exists
if id -u builder >/dev/null 2>&1; then
  echo "User 'builder' already exists"
  BUILDER_UID=$(id -u builder)
  BUILDER_GID=$(id -g builder)
  BUILDER_HOME=$(eval echo ~builder)
  echo "UID: $BUILDER_UID"
  echo "GID: $BUILDER_GID"
  echo "Home: $BUILDER_HOME"
  
  # Verify home directory is /home/builder
  if [ "$BUILDER_HOME" != "/home/builder" ]; then
    fail "builder home directory is $BUILDER_HOME, expected /home/builder"
    echo "Please manually fix builder user home directory"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
  
  pass "builder user exists (reusing)"
else
  echo "Creating user 'builder'..."
  useradd -m -s /bin/bash -c "OpenWrt Build User" builder
  if id -u builder >/dev/null 2>&1; then
    BUILDER_HOME=$(eval echo ~builder)
    echo "UID: $(id -u builder)"
    echo "GID: $(id -g builder)"
    echo "Home: $BUILDER_HOME"
    
    # Verify created home is /home/builder
    if [ "$BUILDER_HOME" != "/home/builder" ]; then
      fail "builder user created but home is $BUILDER_HOME, expected /home/builder"
      echo "Finished: $(date -Iseconds)"
      exit 1
    fi
    
    pass "builder user created"
  else
    fail "Failed to create builder user"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
fi

# Ensure build root directory exists with correct ownership
echo ""
echo "--- Build Directory Setup ---"
if [ ! -d "$BUILD_ROOT" ]; then
  echo "Creating build directory: $BUILD_ROOT"
  mkdir -p "$BUILD_ROOT"
  chown builder:builder "$BUILD_ROOT"
  pass "Build directory created"
else
  echo "Build directory exists: $BUILD_ROOT"
  pass "Build directory present"
fi

# Verify ownership
OWNER=$(stat -c '%U:%G' "$BUILD_ROOT")
if [ "$OWNER" != "builder:builder" ]; then
  echo "Fixing ownership: $BUILD_ROOT"
  chown builder:builder "$BUILD_ROOT"
fi
echo "Owner: $OWNER"

echo ""
echo "--- OpenWrt Source Checkout ---"
echo "Repository: $OPENWRT_REPO"
echo "Target commit: $OPENWRT_TARGET_COMMIT"
echo "Destination: $OPENWRT_DIR"
echo ""

# Check if OpenWrt directory already exists
if [ -d "$OPENWRT_DIR" ]; then
  echo "OpenWrt directory already exists: $OPENWRT_DIR"
  
  # Verify it's a git repository
  if [ ! -d "$OPENWRT_DIR/.git" ]; then
    fail "Directory exists but is not a git repository: $OPENWRT_DIR"
    echo "Please manually remove or rename this directory and retry"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
  
  # Check current commit (as builder user)
  CURRENT_HEAD=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
  echo "Current HEAD: $CURRENT_HEAD"
  
  # Verify target commit can be resolved (as builder user)
  TARGET_FULL=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse "${OPENWRT_TARGET_COMMIT}^{commit}" 2>/dev/null || echo "")
  
  if [ -z "$TARGET_FULL" ]; then
    fail "Cannot resolve target commit ${OPENWRT_TARGET_COMMIT} in existing repository"
    echo "Repository may be corrupted or commit does not exist"
    echo "Please manually verify or remove this directory"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
  
  echo "Target resolved: $TARGET_FULL"
  
  # Check if already on target commit
  if [ "$CURRENT_HEAD" = "$TARGET_FULL" ]; then
    pass "Already on target commit"
    
    # Final verification (as builder user)
    VERIFY_HEAD=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse HEAD)
    VERIFY_TARGET=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse "${OPENWRT_TARGET_COMMIT}^{commit}")
    
    if [ "$VERIFY_HEAD" != "$VERIFY_TARGET" ]; then
      fail "Verification failed: HEAD != target"
      echo "HEAD:   $VERIFY_HEAD"
      echo "Target: $VERIFY_TARGET"
      echo "Finished: $(date -Iseconds)"
      exit 1
    fi
    
    echo ""
    echo "=== Summary ==="
    echo "PASS: $PASS  FAIL: $FAIL"
    echo "OpenWrt commit: $VERIFY_HEAD"
    echo "Finished: $(date -Iseconds)"
    exit 0
  else
    fail "Repository exists but on different commit"
    echo "Current: $CURRENT_HEAD"
    echo "Target:  $TARGET_FULL"
    echo "Manual intervention required - refusing to modify existing checkout"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
else
  # Clone fresh repository
  echo "Cloning OpenWrt repository..."
  echo "This may take 10-15 minutes..."
  
  # Check disk space before cloning
  echo ""
  echo "Checking disk space for fresh clone..."
  AVAIL_KB=$(df -k / | awk 'NR==2 {print $4}')
  AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
  echo "Available disk: ${AVAIL_GB}GB (required: ${MIN_DISK_GB}GB)"
  
  if [ "$AVAIL_GB" -lt "$MIN_DISK_GB" ]; then
    fail "Insufficient disk space for clone: ${AVAIL_GB}GB < ${MIN_DISK_GB}GB"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
  pass "Disk space sufficient: ${AVAIL_GB}GB >= ${MIN_DISK_GB}GB"
  echo ""
  
  # Clone as builder user - target specific commit
  # Use --branch master to get latest, then checkout target
  sudo -H -u builder git clone "$OPENWRT_REPO" "$OPENWRT_DIR" 2>&1 || {
    fail "git clone failed"
    echo "Finished: $(date -Iseconds)"
    exit 1
  }
  
  pass "Repository cloned"
  
  # Verify target commit exists (as builder user)
  TARGET_FULL=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse "${OPENWRT_TARGET_COMMIT}^{commit}" 2>/dev/null || echo "")
  
  if [ -z "$TARGET_FULL" ]; then
    fail "Target commit ${OPENWRT_TARGET_COMMIT} not found in repository"
    echo "This should not happen with full clone"
    echo "Repository may be incomplete or commit does not exist"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
  
  echo "Target commit resolved: $TARGET_FULL"
  
  # Check current HEAD (as builder user)
  CURRENT_HEAD=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse HEAD 2>/dev/null)
  echo "Current HEAD: $CURRENT_HEAD"
  
  # Checkout target commit if not already there (as builder user)
  if [ "$CURRENT_HEAD" != "$TARGET_FULL" ]; then
    echo "Checking out target commit: $TARGET_FULL"
    sudo -H -u builder git -C "$OPENWRT_DIR" checkout "$OPENWRT_TARGET_COMMIT" 2>&1 || {
      fail "git checkout failed"
      echo "Finished: $(date -Iseconds)"
      exit 1
    }
    pass "Checked out target commit"
  else
    pass "Already on target commit"
  fi
  
  # Final verification - ensure HEAD matches target exactly (as builder user)
  FINAL_HEAD=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse HEAD)
  FINAL_TARGET=$(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse "${OPENWRT_TARGET_COMMIT}^{commit}")
  
  echo "Final HEAD:   $FINAL_HEAD"
  echo "Final target: $FINAL_TARGET"
  
  if [ "$FINAL_HEAD" != "$FINAL_TARGET" ]; then
    fail "Commit verification failed after checkout"
    echo "HEAD does not match target commit"
    echo "Finished: $(date -Iseconds)"
    exit 1
  fi
  
  pass "Commit verification passed"
fi

echo ""
echo "--- Repository Information ---"
echo "HEAD: $(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse HEAD)"
echo "Branch: $(sudo -H -u builder git -C "$OPENWRT_DIR" branch --show-current 2>/dev/null || echo '(detached HEAD)')"
echo "Remote: $(sudo -H -u builder git -C "$OPENWRT_DIR" remote get-url origin 2>/dev/null || echo '(none)')"
echo "Commit date: $(sudo -H -u builder git -C "$OPENWRT_DIR" log -1 --format='%ci' HEAD)"
echo "Commit subject: $(sudo -H -u builder git -C "$OPENWRT_DIR" log -1 --format='%s' HEAD)"

# Get repository size
REPO_SIZE=$(du -sh "$OPENWRT_DIR" 2>/dev/null | cut -f1)
echo "Repository size: $REPO_SIZE"

# Count files
FILE_COUNT=$(find "$OPENWRT_DIR" -type f 2>/dev/null | wc -l)
echo "File count: $FILE_COUNT"

echo ""
echo "--- Post-checkout Disk Usage ---"
df -h /

echo ""
echo "=== Summary ==="
echo "PASS: $PASS  FAIL: $FAIL"
echo "OpenWrt commit: $(sudo -H -u builder git -C "$OPENWRT_DIR" rev-parse HEAD)"
echo "Finished: $(date -Iseconds)"

[ "$FAIL" -eq 0 ]
