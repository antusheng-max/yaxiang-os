#!/bin/bash
# Yaxiang OS - OpenWrt Image Build Script
# Uses OpenWrt Image Builder to create system images

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")/.."
CONFIG_FILE="${PROJECT_DIR}/openwrt/configs/x86_64-v0.2-dev.config"

# Source configuration
source "$CONFIG_FILE"

echo "========================================="
echo " Yaxiang OS Image Build"
echo " Version: ${PRODUCT_VERSION}"
echo " Target: ${ARCH}"
echo "========================================="
echo ""

# ===== Pre-build checks =====
echo "[Pre-build] Checking prerequisites..."

# Check Image Builder exists
if [ ! -d "$IMAGE_BUILDER" ]; then
  echo "ERROR: Image Builder not found at $IMAGE_BUILDER"
  exit 1
fi

# Check disk space (need at least 5GB)
AVAILABLE_KB=$(df -k "$IMAGE_BUILDER" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_KB" -lt 5242880 ]; then
  echo "ERROR: Insufficient disk space (${AVAILABLE_KB}KB available, need 5GB)"
  exit 1
fi
echo "  Disk space: $((AVAILABLE_KB / 1024))MB available"

# Check web dist exists
if [ ! -d "$WEB_DIST" ]; then
  echo "ERROR: Web dist not found. Run build-web.sh first."
  exit 1
fi
echo "  Web dist: OK"

# Check custom packages
if [ ! -d "$PACKAGE_DIR" ]; then
  echo "ERROR: Package directory not found at $PACKAGE_DIR"
  exit 1
fi
echo "  Custom packages: OK"

echo ""

# ===== Prepare files overlay =====
echo "[1/5] Preparing files overlay..."

FILES_DIR="${PROJECT_DIR}/openwrt/files-overlay"
rm -rf "$FILES_DIR"
mkdir -p "$FILES_DIR"

# Copy web dist to files overlay
echo "  Copying web dist..."
mkdir -p "$FILES_DIR/www"
cp -r "$WEB_DIST"/* "$FILES_DIR/www/"

# Copy branding files
echo "  Copying branding files..."
mkdir -p "$FILES_DIR/etc"
if [ -f "${PACKAGE_DIR}/yaxiang-branding/files/etc/yaxiang-release" ]; then
  cp "${PACKAGE_DIR}/yaxiang-branding/files/etc/yaxiang-release" "$FILES_DIR/etc/"
fi

# Copy uci-defaults
echo "  Copying uci-defaults..."
mkdir -p "$FILES_DIR/etc/uci-defaults"
for script in "${PACKAGE_DIR}"/*/files/etc/uci-defaults/*; do
  [ -f "$script" ] && cp "$script" "$FILES_DIR/etc/uci-defaults/" && chmod +x "$FILES_DIR/etc/uci-defaults/$(basename $script)"
done

# Copy init scripts
echo "  Copying init scripts..."
mkdir -p "$FILES_DIR/etc/init.d"
for script in "${PACKAGE_DIR}"/*/files/etc/init.d/*; do
  [ -f "$script" ] && cp "$script" "$FILES_DIR/etc/init.d/" && chmod +x "$FILES_DIR/etc/init.d/$(basename $script)"
done

# Copy binaries
echo "  Copying binaries..."
mkdir -p "$FILES_DIR/usr/bin"
for bin in "${PACKAGE_DIR}"/*/files/usr/bin/*; do
  [ -f "$bin" ] && cp "$bin" "$FILES_DIR/usr/bin/" && chmod +x "$FILES_DIR/usr/bin/$(basename $bin)"
done

# Copy rpcd scripts
echo "  Copying rpcd scripts..."
mkdir -p "$FILES_DIR/usr/libexec/rpcd"
for script in "${PACKAGE_DIR}"/*/files/usr/libexec/rpcd/*; do
  [ -f "$script" ] && cp "$script" "$FILES_DIR/usr/libexec/rpcd/" && chmod +x "$FILES_DIR/usr/libexec/rpcd/$(basename $script)"
done

# Copy ACL files
echo "  Copying ACL files..."
mkdir -p "$FILES_DIR/usr/share/rpcd/acl.d"
for acl in "${PACKAGE_DIR}"/*/files/usr/share/rpcd/acl.d/*; do
  [ -f "$acl" ] && cp "$acl" "$FILES_DIR/usr/share/rpcd/acl.d/"
done

echo "  Files overlay prepared: $FILES_DIR"
echo ""

# ===== Prepare custom packages =====
echo "[2/5] Preparing custom packages..."

# Copy custom packages to Image Builder packages directory
IB_PACKAGES_DIR="$IMAGE_BUILDER/packages"
for pkg_dir in "$PACKAGE_DIR"/*/; do
  pkg_name=$(basename "$pkg_dir")
  echo "  Package: $pkg_name"
  # Note: For Image Builder, we use FILES= overlay instead of .apk packages
  # The packages are defined for documentation/full-build compatibility
done

echo ""

# ===== Build images =====
echo "[3/5] Building images..."

cd "$IMAGE_BUILDER"

# Common packages to include (verified available in Image Builder 25.12.5)
PACKAGES="uhttpd uhttpd-mod-ubus rpcd rpcd-mod-file rpcd-mod-ucode ubus uci firewall4 nftables ip-full \
  kmod-e1000 kmod-e1000e kmod-igb kmod-igc kmod-ixgbe kmod-r8169 \
  ca-bundle dnsmasq odhcpd-ipv6only odhcp6c \
  dropbear kmod-button-hotplug grub2-bios-setup procd-ujail"

# Build combined image (Legacy BIOS)
echo "  Building combined image (Legacy BIOS)..."
make image \
  PROFILE="$PROFILE" \
  PACKAGES="$PACKAGES" \
  FILES="$FILES_DIR" \
  BIN_DIR="$OUTPUT_DIR" \
  EXTRA_IMAGE_NAME="yaxiang-v0.2-dev" \
  2>&1 | tee "$OUTPUT_DIR/build-combined.log"

# Build combined-efi image (UEFI)
echo "  Building combined-efi image (UEFI)..."
make image \
  PROFILE="$PROFILE" \
  PACKAGES="$PACKAGES" \
  FILES="$FILES_DIR" \
  BIN_DIR="$OUTPUT_DIR" \
  EXTRA_IMAGE_NAME="yaxiang-v0.2-dev-efi" \
  2>&1 | tee "$OUTPUT_DIR/build-combined-efi.log"

echo ""

# ===== Rename and organize output =====
echo "[4/5] Organizing output files..."

cd "$OUTPUT_DIR"

# Find and rename images
for f in openwrt-*generic-combined.img.gz; do
  [ -f "$f" ] && mv "$f" "Yaxiang-OS-V0.2-dev-x86_64-combined.img.gz" && echo "  Renamed: $f -> Yaxiang-OS-V0.2-dev-x86_64-combined.img.gz"
done

for f in openwrt-*generic-combined-efi.img.gz; do
  [ -f "$f" ] && mv "$f" "Yaxiang-OS-V0.2-dev-x86_64-combined-efi.img.gz" && echo "  Renamed: $f -> Yaxiang-OS-V0.2-dev-x86_64-combined-efi.img.gz"
done

# Generate SHA256SUMS
echo "  Generating SHA256SUMS..."
sha256sum Yaxiang-OS-V0.2-dev-x86_64-*.img.gz > SHA256SUMS 2>/dev/null || true

# Copy build info
echo "  Copying build info..."
[ -f "$IMAGE_BUILDER/build_dir/target-x86_64_musl/linux-x86_64/openwrt-25.12.5-x86-64-generic.manifest" ] && \
  cp "$IMAGE_BUILDER/build_dir/target-x86_64_musl/linux-x86_64/openwrt-25.12.5-x86-64-generic.manifest" "$OUTPUT_DIR/package-manifest.txt" 2>/dev/null || true

[ -f "$IMAGE_BUILDER/build_dir/target-x86_64_musl/linux-x86_64/openwrt-25.12.5-x86-64-generic.config.buildinfo" ] && \
  cp "$IMAGE_BUILDER/build_dir/target-x86_64_musl/linux-x86_64/openwrt-25.12.5-x86-64-generic.config.buildinfo" "$OUTPUT_DIR/config.buildinfo" 2>/dev/null || true

[ -f "$IMAGE_BUILDER/build_dir/target-x86_64_musl/linux-x86_64/openwrt-25.12.5-x86-64-generic.feeds.buildinfo" ] && \
  cp "$IMAGE_BUILDER/build_dir/target-x86_64_musl/linux-x86_64/openwrt-25.12.5-x86-64-generic.feeds.buildinfo" "$OUTPUT_DIR/feeds.buildinfo" 2>/dev/null || true

# Record source commit
echo "  Recording source commit..."
cat > "$OUTPUT_DIR/source-commit.txt" << EOF
Yaxiang OS V0.2-dev Build Information
=====================================
Build Date: $(date '+%Y-%m-%d %H:%M:%S')
Build Host: $(hostname)
OpenWrt Version: 25.12.5
OpenWrt Revision: r33051-f5dae5ece4
Yaxiang Web Commit: $(cd "$PROJECT_DIR/web" && git log -1 --format='%H %s' 2>/dev/null || echo "unknown")
Yaxiang Project Commit: $(cd "$PROJECT_DIR" && git log -1 --format='%H %s' 2>/dev/null || echo "unknown")
EOF

echo ""

# ===== Summary =====
echo "[5/5] Build summary:"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"/*.img.gz 2>/dev/null || echo "  No images found"
echo ""
echo "Build completed!"
echo ""
echo "Next steps:"
echo "  1. Run QEMU tests: ./scripts/test-qemu.sh"
echo "  2. Verify image: ./scripts/verify-image.sh"
echo "  3. Generate report: ./scripts/generate-report.sh"
