#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象网络操作系统 - 安装 ISO 构建脚本
# 第四阶段: 生成 Legacy BIOS + UEFI 双启动 ISO
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$INSTALLER_DIR")"
OUTPUT_DIR="${INSTALLER_DIR}/output"
ISO_STAGING="${OUTPUT_DIR}/iso-build-staging"
ISO_NAME="Yaxiang-OS-V0.2-dev-x86_64-installer.iso"
ISO_PATH="${OUTPUT_DIR}/${ISO_NAME}"
BUILD_LOG="${OUTPUT_DIR}/stage4-iso-build.log"
VERSION="V0.2-dev"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$BUILD_LOG"; }
die() { log "[错误] $*"; exit 1; }

# 初始化日志
mkdir -p "$OUTPUT_DIR"
echo "亚象安装 ISO 构建日志 - $(date '+%Y-%m-%d %H:%M:%S')" > "$BUILD_LOG"

log "=========================================="
log "亚象安装 ISO 构建开始"
log "=========================================="

# ============================================================
# 1. 校验输入文件
# ============================================================
log "=== 1. 校验输入文件 ==="

KERNEL="${OUTPUT_DIR}/iso-staging/boot/vmlinuz"
INITRD="${OUTPUT_DIR}/iso-staging/boot/initrd.img"
SQUASHFS="${OUTPUT_DIR}/iso-staging/live/filesystem.squashfs"
IMAGE_BIOS="${INSTALLER_DIR}/images/combined.img.gz"
IMAGE_UEFI="${INSTALLER_DIR}/images/combined-efi.img.gz"
IMAGE_SHA="${INSTALLER_DIR}/images/SHA256SUMS"
INSTALLER="${INSTALLER_DIR}/src/yaxiang-installer"
WRITER="${INSTALLER_DIR}/src/image-writer.sh"
VERIFIER="${INSTALLER_DIR}/src/image-verifier.sh"
BANNER="${INSTALLER_DIR}/assets/banner.txt"

for f in "$KERNEL" "$INITRD" "$IMAGE_BIOS" "$IMAGE_UEFI" "$IMAGE_SHA" "$INSTALLER" "$WRITER" "$VERIFIER"; do
    [ -f "$f" ] || die "必需文件缺失: $f"
done
log "所有输入文件存在"

# 镜像完整性
gzip -t "$IMAGE_BIOS" || die "combined.img.gz gzip 校验失败"
gzip -t "$IMAGE_UEFI" || die "combined-efi.img.gz gzip 校验失败"
(cd "$(dirname "$IMAGE_BIOS")" && sha256sum -c SHA256SUMS) >> "$BUILD_LOG" 2>&1 || die "SHA256 校验失败"
log "镜像完整性和 SHA256 校验通过"

# 工具检查
command -v grub-mkrescue >/dev/null 2>&1 || die "grub-mkrescue 不可用"
command -v xorriso >/dev/null 2>&1 || die "xorriso 不可用"
log "构建工具就绪"

# ============================================================
# 2. 清理并创建 ISO staging 目录
# ============================================================
log "=== 2. 创建 ISO staging 目录 ==="

rm -rf "$ISO_STAGING"
mkdir -p "$ISO_STAGING"/{boot/grub,live,installer/images,installer/src,opt/yaxiang-installer}

# ============================================================
# 3. 复制文件
# ============================================================
log "=== 3. 复制文件到 ISO ==="

# 内核和 initrd
cp "$KERNEL" "$ISO_STAGING/boot/vmlinuz"
cp "$INITRD" "$ISO_STAGING/boot/initrd.img"
log "内核和 initrd 已复制"

# SquashFS (如果存在)
if [ -f "$SQUASHFS" ]; then
    cp "$SQUASHFS" "$ISO_STAGING/live/filesystem.squashfs"
    log "SquashFS 已复制 ($(du -h "$SQUASHFS" | cut -f1))"
else
    log "警告: SquashFS 不存在，ISO 将使用 initrd 启动"
fi

# 系统镜像
cp "$IMAGE_BIOS" "$ISO_STAGING/installer/images/"
cp "$IMAGE_UEFI" "$ISO_STAGING/installer/images/"
cp "$IMAGE_SHA" "$ISO_STAGING/installer/images/"
log "系统镜像已复制"

# 安装器脚本
cp "$INSTALLER" "$ISO_STAGING/opt/yaxiang-installer/yaxiang-installer"
cp "$WRITER" "$ISO_STAGING/opt/yaxiang-installer/image-writer.sh"
cp "$VERIFIER" "$ISO_STAGING/opt/yaxiang-installer/image-verifier.sh"
chmod +x "$ISO_STAGING/opt/yaxiang-installer/"*
log "安装器脚本已复制"

# Banner 和版本信息
if [ -f "$BANNER" ]; then
    mkdir -p "$ISO_STAGING/opt/yaxiang-installer/assets"
    cp "$BANNER" "$ISO_STAGING/opt/yaxiang-installer/assets/"
fi
cat > "$ISO_STAGING/opt/yaxiang-installer/version.txt" << EOF
亚象网络操作系统安装器
版本: ${VERSION}
构建时间: $(date '+%Y-%m-%d %H:%M:%S')
架构: x86_64
阶段: 第四阶段 (ISO 生成)
EOF
log "版本信息已创建"

# ============================================================
# 4. GRUB 配置
# ============================================================
log "=== 4. 创建 GRUB 配置 ==="

cat > "$ISO_STAGING/boot/grub/grub.cfg" << 'GRUBEOF'
# ============================================================
# 亚象网络操作系统 - GRUB 启动配置
# Yaxiang OS Installer V0.2-dev
# ============================================================

set default=0
set timeout=5

if [ "${grub_platform}" = "efi" ]; then
    insmod efi_gop
    insmod efi_uga
else
    insmod vbe
    insmod vga
fi

insmod gfxterm
insmod font
insmod iso9660
insmod search
insmod linux
insmod chain

if loadfont /boot/grub/fonts/unicode.pf2 ; then
    set gfxmode=1024x768
    terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "启动亚象安装程序 (Start Yaxiang Installer)" {
    set root=(cd)
    linux /boot/vmlinuz boot=live quiet console=tty1 console=tty0
    initrd /boot/initrd.img
}

menuentry "启动亚象安装程序 - 串口控制台 (Serial Console)" {
    set root=(cd)
    linux /boot/vmlinuz boot=live quiet console=ttyS0,115200n8
    initrd /boot/initrd.img
}

menuentry "硬件兼容模式 (Safe Graphics / Compatibility)" {
    set root=(cd)
    linux /boot/vmlinuz boot=live quiet nomodeset acpi=off console=tty1 console=tty0
    initrd /boot/initrd.img
}

menuentry "进入维护环境 (Maintenance Shell)" {
    set root=(cd)
    linux /boot/vmlinuz boot=live quiet single console=tty1 console=tty0
    initrd /boot/initrd.img
}

menuentry "重启 (Reboot)" {
    reboot
}

menuentry "关机 (Power Off)" {
    halt
}
GRUBEOF

# 复制 GRUB 字体 (如果存在)
if [ -d "${OUTPUT_DIR}/iso-staging/boot/grub/fonts" ]; then
    cp -r "${OUTPUT_DIR}/iso-staging/boot/grub/fonts" "$ISO_STAGING/boot/grub/"
fi

log "GRUB 配置已创建 (6 菜单项, 默认第一项, 5秒超时)"

# ============================================================
# 5. 生成 ISO
# ============================================================
log "=== 5. 生成 ISO ==="
log "使用 grub-mkrescue 生成混合启动 ISO..."

grub-mkrescue \
    -o "$ISO_PATH" \
    "$ISO_STAGING" \
    -- -volid "YAXIANG_OS_INSTALLER" \
    >> "$BUILD_LOG" 2>&1 || die "grub-mkrescue 失败"

[ -f "$ISO_PATH" ] || die "ISO 文件未生成"
ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
log "ISO 已生成: $ISO_PATH ($ISO_SIZE)"

# ============================================================
# 6. 生成校验和清单
# ============================================================
log "=== 6. 生成校验和清单 ==="

# ISO SHA256
ISO_SHA256=$(sha256sum "$ISO_PATH" | awk '{print $1}')
echo "$ISO_SHA256  $ISO_NAME" > "${OUTPUT_DIR}/SHA256SUMS"
log "ISO SHA256: ${ISO_SHA256:0:32}..."

# 文件清单
{
    echo "亚象安装 ISO 文件清单"
    echo "ISO: $ISO_NAME"
    echo "大小: $ISO_SIZE"
    echo "SHA256: $ISO_SHA256"
    echo "构建时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "=== ISO 内容 ==="
    # 使用 xorriso 列出 ISO 内容
    xorriso -indev "$ISO_PATH" -find / -exec ls -la {} \; 2>/dev/null | head -100 || true
} > "${OUTPUT_DIR}/iso-file-manifest.txt"
log "校验和清单已生成"

# ============================================================
# 7. 安全扫描
# ============================================================
log "=== 7. 安全扫描 ==="

# 确认 ISO 不包含敏感文件
SENSITIVE_FOUND=0
for pattern in "node_modules" ".git" ".map" "id_rsa" ".ssh" "password" ".env"; do
    if xorriso -indev "$ISO_PATH" -find / -name "*${pattern}*" 2>/dev/null | grep -q "$pattern"; then
        log "警告: ISO 中可能包含敏感文件: $pattern"
        SENSITIVE_FOUND=1
    fi
done
if [ "$SENSITIVE_FOUND" -eq 0 ]; then
    log "安全扫描通过: 无敏感文件"
fi

log ""
log "=========================================="
log "ISO 构建完成"
log "文件: $ISO_PATH"
log "大小: $ISO_SIZE"
log "SHA256: $ISO_SHA256"
log "=========================================="
