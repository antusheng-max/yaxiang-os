#!/bin/bash
# Yaxiang OS - Image Verification Script
# Checks image integrity and content

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")/.."
OUTPUT_DIR="${PROJECT_DIR}/openwrt/output/v0.2-dev"

echo "========================================="
echo " Yaxiang OS Image Verification"
echo "========================================="
echo ""

PASS=0
FAIL=0
WARN=0

check_pass() { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
check_fail() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }
check_warn() { WARN=$((WARN + 1)); echo "  [WARN] $1"; }

# ===== Image file checks =====
echo "[1] Image file checks"

if [ -f "$OUTPUT_DIR/Yaxiang-OS-V0.2-dev-x86_64-combined.img.gz" ]; then
  check_pass "combined image exists"
else
  check_fail "combined image missing"
fi

if [ -f "$OUTPUT_DIR/Yaxiang-OS-V0.2-dev-x86_64-combined-efi.img.gz" ]; then
  check_pass "combined-efi image exists"
else
  check_fail "combined-efi image missing"
fi

# Check gzip integrity
for img in "$OUTPUT_DIR"/Yaxiang-OS-V0.2-dev-x86_64-*.img.gz; do
  [ -f "$img" ] || continue
  if gzip -t "$img" 2>/dev/null; then
    check_pass "$(basename $img) gzip integrity OK"
  else
    check_fail "$(basename $img) gzip integrity failed"
  fi
done

# Check SHA256
if [ -f "$OUTPUT_DIR/SHA256SUMS" ]; then
  cd "$OUTPUT_DIR"
  if sha256sum -c SHA256SUMS 2>/dev/null; then
    check_pass "SHA256 checksums verified"
  else
    check_fail "SHA256 checksum verification failed"
  fi
  cd - >/dev/null
else
  check_warn "SHA256SUMS file not found"
fi

echo ""

# ===== Content checks =====
echo "[2] Content checks"

# Check web files exist in overlay
FILES_DIR="${PROJECT_DIR}/openwrt/files-overlay"
if [ -d "$FILES_DIR" ]; then
  if [ -f "$FILES_DIR/www/index.html" ]; then
    check_pass "Web index.html exists"
  else
    check_fail "Web index.html missing"
  fi

  if [ -f "$FILES_DIR/etc/yaxiang-release" ]; then
    check_pass "yaxiang-release exists"
  else
    check_fail "yaxiang-release missing"
  fi

  if ls "$FILES_DIR"/etc/uci-defaults/*yaxiang* 1>/dev/null 2>&1; then
    check_pass "uci-defaults scripts exist"
  else
    check_fail "uci-defaults scripts missing"
  fi

  if ls "$FILES_DIR"/usr/libexec/rpcd/yaxiang_* 1>/dev/null 2>&1; then
    check_pass "rpcd scripts exist"
  else
    check_fail "rpcd scripts missing"
  fi

  if ls "$FILES_DIR"/usr/share/rpcd/acl.d/yaxiang.json 1>/dev/null 2>&1; then
    check_pass "rpcd ACL exists"
  else
    check_fail "rpcd ACL missing"
  fi

  if [ -f "$FILES_DIR/usr/bin/yaxiang-console" ]; then
    check_pass "yaxiang-console exists"
  else
    check_fail "yaxiang-console missing"
  fi

  if [ -f "$FILES_DIR/usr/bin/yaxiang-collect" ]; then
    check_pass "yaxiang-collect exists"
  else
    check_fail "yaxiang-collect missing"
  fi

  if ls "$FILES_DIR"/etc/init.d/yaxiang-* 1>/dev/null 2>&1; then
    check_pass "procd init scripts exist"
  else
    check_fail "procd init scripts missing"
  fi
else
  check_fail "Files overlay directory not found"
fi

echo ""

# ===== Security checks =====
echo "[3] Security checks"

if [ -d "$FILES_DIR/www" ]; then
  if find "$FILES_DIR/www" -name "node_modules" -type d 2>/dev/null | grep -q .; then
    check_fail "node_modules found in web dist"
  else
    check_pass "No node_modules in web dist"
  fi

  if find "$FILES_DIR/www" -name "*.map" 2>/dev/null | grep -q .; then
    check_fail "Source maps found in web dist"
  else
    check_pass "No source maps in web dist"
  fi

  if find "$FILES_DIR/www" -name ".git" -type d 2>/dev/null | grep -q .; then
    check_fail ".git directory found in web dist"
  else
    check_pass "No .git in web dist"
  fi

  # Check for sensitive content
  if grep -rq "LineHub\|智能网络优化" "$FILES_DIR/www/" 2>/dev/null; then
    check_fail "Sensitive text (LineHub/智能网络优化) found"
  else
    check_pass "No sensitive branding text"
  fi

  if grep -rq "dev-mock\|mockData" "$FILES_DIR/www/" 2>/dev/null; then
    check_fail "Mock data references found"
  else
    check_pass "No mock data references"
  fi

  if grep -rq "4173" "$FILES_DIR/www/" 2>/dev/null; then
    check_fail "Port 4173 references found"
  else
    check_pass "No port 4173 references"
  fi
fi

# Check for SSH private keys
if find "$FILES_DIR" -name "*.pem" -o -name "id_rsa" -o -name "id_ed25519" 2>/dev/null | grep -q .; then
  check_fail "SSH private keys found"
else
  check_pass "No SSH private keys"
fi

# Check for passwords/secrets
if grep -rq "password\|secret\|密钥" "$FILES_DIR/etc/" 2>/dev/null | grep -v "yaxiang-release"; then
  check_warn "Potential secrets in config files"
else
  check_pass "No obvious secrets in config"
fi

echo ""

# ===== Build info checks =====
echo "[4] Build info checks"

if [ -f "$OUTPUT_DIR/package-manifest.txt" ]; then
  check_pass "package manifest exists"
else
  check_warn "package manifest not found"
fi

if [ -f "$OUTPUT_DIR/source-commit.txt" ]; then
  check_pass "source commit info exists"
else
  check_warn "source commit info not found"
fi

if [ -f "$OUTPUT_DIR/config.buildinfo" ]; then
  check_pass "config buildinfo exists"
else
  check_warn "config buildinfo not found"
fi

echo ""

# ===== Summary =====
echo "========================================="
echo " Verification Summary"
echo "========================================="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo ""

if [ $FAIL -gt 0 ]; then
  echo "RESULT: FAILED - $FAIL check(s) failed"
  exit 1
else
  echo "RESULT: PASSED - All critical checks passed"
  exit 0
fi
