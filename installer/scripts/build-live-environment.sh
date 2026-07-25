#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装器 - Live 环境构建脚本
# build-live-environment.sh
#
# 功能: 将 rootfs 打包为 squashfs，准备 ISO 启动文件
# 注意: 不制作最终 ISO，不操作真实块设备
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
LIVE_DIR="${INSTALLER_DIR}/live"
ROOTFS_DIR="${LIVE_DIR}/rootfs"
OUTPUT_DIR="${INSTALLER_DIR}/output"
LOG_FILE="${OUTPUT_DIR}/live-build-current.log"

# ISO 暂存目录
STAGING_DIR="${OUTPUT_DIR}/iso-staging"

# --- 日志函数 ---
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

error() {
    log "ERROR: $*"
    exit 1
}

# --- 前置检查 ---
preflight_check() {
    log "=== 构建前置检查 ==="
    
    if [ "$(id -u)" -ne 0 ]; then
        error "此脚本需要 root 权限运行"
    fi
    
    local required_tools=("mksquashfs" "grub-mkrescue" "xorriso")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            error "缺少必要工具: $tool"
        fi
    done
    
    if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
        error "根文件系统未准备好。请先运行 prepare-live-rootfs.sh"
    fi
    
    # 检查安装器文件
    if [ ! -f "$ROOTFS_DIR/opt/yaxiang-installer/yaxiang-installer" ]; then
        error "安装器程序未安装到 rootfs 中"
    fi
    
    # 检查系统镜像
    if [ ! -f "${INSTALLER_DIR}/images/combined.img.gz" ]; then
        error "系统镜像 combined.img.gz 不存在"
    fi
    if [ ! -f "${INSTALLER_DIR}/images/combined-efi.img.gz" ]; then
        error "系统镜像 combined-efi.img.gz 不存在"
    fi
    
    log "前置检查通过"
}

# --- 创建 squashfs ---
create_squashfs() {
    log "=== 创建 SquashFS 文件系统 ==="
    
    local squashfs_file="${STAGING_DIR}/live/filesystem.squashfs"
    mkdir -p "${STAGING_DIR}/live"
    
    # 删除旧的 squashfs
    rm -f "$squashfs_file"
    
    log "正在压缩根文件系统为 squashfs..."
    mksquashfs "$ROOTFS_DIR" "$squashfs_file" \
        -comp xz \
        -Xdict-size 100% \
        -noappend \
        -e dev proc sys run tmp var/tmp var/log \
        2>&1 | while IFS= read -r line; do
            log "  mksquashfs: $line"
        done
    
    if [ ! -f "$squashfs_file" ]; then
        error "squashfs 创建失败"
    fi
    
    local size
    size=$(du -sh "$squashfs_file" | cut -f1)
    log "SquashFS 创建完成: ${squashfs_file} (${size})"
}

# --- 准备内核和 initrd ---
prepare_kernel() {
    log "=== 准备内核和 initrd ==="
    
    mkdir -p "${STAGING_DIR}/boot"
    
    # 从 rootfs 复制内核
    local kernel_file
    kernel_file=$(find "$ROOTFS_DIR/boot" -name "vmlinuz-*" -type f 2>/dev/null | sort -V | tail -1)
    
    if [ -z "$kernel_file" ]; then
        error "未找到内核文件"
    fi
    
    cp "$kernel_file" "${STAGING_DIR}/boot/vmlinuz"
    log "内核已复制: $(basename "$kernel_file")"
    
    # 创建最小 initrd
    log "创建 initrd..."
    local initrd_dir
    initrd_dir=$(mktemp -d)
    
    # initrd 基本结构
    mkdir -p "$initrd_dir"/{bin,dev,proc,sys,etc,lib,lib64,mnt,root,run,sbin,tmp,usr/bin,usr/sbin,var}
    
    # 创建 init 脚本 (Live 启动脚本)
    cat > "$initrd_dir/init" << INIT_SCRIPT
#!/bin/busybox sh
# 亚象 Live 环境 initrd init 脚本

echo "Yaxiang OS Live Environment - Initializing..."

# 挂载必要的文件系统
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

# 加载存储驱动
for mod in ahci nvme virtio_blk virtio_pci sd_mod sr_mod ata_piix; do
    modprobe $mod 2>/dev/null || true
done

sleep 2

# 查找 Live 介质
echo "Searching for live media..."
LIVE_MEDIA=""
for dev in /dev/sr0 /dev/sda1 /dev/vda1; do
    if [ -b "$dev" ]; then
        mkdir -p /mnt/live
        if mount -r "$dev" /mnt/live 2>/dev/null; then
            if [ -f /mnt/live/live/filesystem.squashfs ]; then
                LIVE_MEDIA="/mnt/live"
                echo "Found live media on $dev"
                break
            fi
            umount /mnt/live 2>/dev/null
        fi
    fi
done

if [ -z "$LIVE_MEDIA" ]; then
    echo "ERROR: Could not find live media"
    echo "Dropping to rescue shell..."
    exec /bin/busybox sh
fi

# 挂载 squashfs
echo "Mounting squashfs..."
mkdir -p /rootfs
mount -t squashfs -o ro,loop "$LIVE_MEDIA/live/filesystem.squashfs" /rootfs

# 创建 overlay
mkdir -p /rootfs-rw/upper /rootfs-rw/work
mount -t tmpfs tmpfs /rootfs-rw
mkdir -p /rootfs-rw/upper /rootfs-rw/work

# 合并 overlay
mkdir -p /merged
mount -t overlay overlay -o lowerdir=/rootfs,upperdir=/rootfs-rw/upper,workdir=/rootfs-rw/work /merged

# 移动挂载点
mount --move /proc /merged/proc
mount --move /sys /merged/sys
mount --move /dev /merged/dev

# 切换到真实根文件系统
echo "Switching to live root..."
exec switch_root /merged /sbin/init
INIT_SCRIPT
    chmod +x "$initrd_dir/init"
    
    # 复制 busybox
    local busybox_path
    busybox_path=$(which busybox 2>/dev/null || echo "")
    if [ -z "$busybox_path" ]; then
        # 从 rootfs 获取 busybox
        busybox_path="$ROOTFS_DIR/bin/busybox"
    fi
    
    if [ -f "$busybox_path" ]; then
        cp "$busybox_path" "$initrd_dir/bin/busybox"
        chmod +x "$initrd_dir/bin/busybox"
        
        # 创建常用命令的符号链接
        for cmd in sh mount umount mkdir modprobe echo sleep cat ls find switch_root; do
            ln -sf busybox "$initrd_dir/bin/$cmd" 2>/dev/null || true
        done
    else
        log "WARNING: busybox 未找到，尝试从 rootfs 安装"
        cp "$ROOTFS_DIR/bin/busybox" "$initrd_dir/bin/busybox" 2>/dev/null || error "无法获取 busybox"
        chmod +x "$initrd_dir/bin/busybox"
        for cmd in sh mount umount mkdir modprobe echo sleep cat ls find switch_root; do
            ln -sf busybox "$initrd_dir/bin/$cmd" 2>/dev/null || true
        done
    fi
    
    # 打包 initrd
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip -9 > "${STAGING_DIR}/boot/initrd.img")
    
    rm -rf "$initrd_dir"
    
    log "initrd 创建完成"
}

# --- 准备 GRUB 启动文件 ---
prepare_grub() {
    log "=== 准备 GRUB 启动文件 ==="
    
    # BIOS GRUB
    mkdir -p "${STAGING_DIR}/boot/grub"
    
    # 复制 grub.cfg
    if [ -f "${INSTALLER_DIR}/grub/grub.cfg" ]; then
        cp "${INSTALLER_DIR}/grub/grub.cfg" "${STAGING_DIR}/boot/grub/grub.cfg"
        log "GRUB 配置已复制"
    else
        error "GRUB 配置不存在: ${INSTALLER_DIR}/grub/grub.cfg"
    fi
    
    # 复制 GRUB 字体
    local grub_font
    grub_font=$(find /usr/share/grub -name "unicode.pf2" 2>/dev/null | head -1)
    if [ -n "$grub_font" ]; then
        mkdir -p "${STAGING_DIR}/boot/grub/fonts"
        cp "$grub_font" "${STAGING_DIR}/boot/grub/fonts/"
        log "GRUB 字体已复制"
    fi
    
    # 复制 GRUB 模块 (BIOS)
    if [ -d /usr/lib/grub/i386-pc ]; then
        mkdir -p "${STAGING_DIR}/boot/grub/i386-pc"
        cp /usr/lib/grub/i386-pc/*.mod "${STAGING_DIR}/boot/grub/i386-pc/" 2>/dev/null || true
        cp /usr/lib/grub/i386-pc/*.lst "${STAGING_DIR}/boot/grub/i386-pc/" 2>/dev/null || true
        log "GRUB BIOS 模块已复制"
    fi
    
    # 复制 GRUB 模块 (UEFI)
    if [ -d /usr/lib/grub/x86_64-efi ]; then
        mkdir -p "${STAGING_DIR}/boot/grub/x86_64-efi"
        cp /usr/lib/grub/x86_64-efi/*.mod "${STAGING_DIR}/boot/grub/x86_64-efi/" 2>/dev/null || true
        cp /usr/lib/grub/x86_64-efi/*.lst "${STAGING_DIR}/boot/grub/x86_64-efi/" 2>/dev/null || true
        log "GRUB UEFI 模块已复制"
    fi
    
    log "GRUB 启动文件准备完成"
}

# --- 验证构建产物 ---
verify_build() {
    log "=== 验证构建产物 ==="
    
    local checks_passed=0
    local checks_total=0
    
    # 检查 squashfs
    checks_total=$((checks_total + 1))
    if [ -f "${STAGING_DIR}/live/filesystem.squashfs" ]; then
        log "  [PASS] squashfs 文件存在"
        checks_passed=$((checks_passed + 1))
    else
        log "  [FAIL] squashfs 文件不存在"
    fi
    
    # 检查内核
    checks_total=$((checks_total + 1))
    if [ -f "${STAGING_DIR}/boot/vmlinuz" ]; then
        log "  [PASS] 内核文件存在"
        checks_passed=$((checks_passed + 1))
    else
        log "  [FAIL] 内核文件不存在"
    fi
    
    # 检查 initrd
    checks_total=$((checks_total + 1))
    if [ -f "${STAGING_DIR}/boot/initrd.img" ]; then
        log "  [PASS] initrd 文件存在"
        checks_passed=$((checks_passed + 1))
    else
        log "  [FAIL] initrd 文件不存在"
    fi
    
    # 检查 GRUB 配置
    checks_total=$((checks_total + 1))
    if [ -f "${STAGING_DIR}/boot/grub/grub.cfg" ]; then
        log "  [PASS] GRUB 配置存在"
        checks_passed=$((checks_passed + 1))
    else
        log "  [FAIL] GRUB 配置不存在"
    fi
    
    # 检查 GRUB BIOS 模块
    checks_total=$((checks_total + 1))
    if [ -d "${STAGING_DIR}/boot/grub/i386-pc" ] && [ "$(ls -A "${STAGING_DIR}/boot/grub/i386-pc/" 2>/dev/null)" ]; then
        log "  [PASS] GRUB BIOS 模块存在"
        checks_passed=$((checks_passed + 1))
    else
        log "  [FAIL] GRUB BIOS 模块不存在"
    fi
    
    # 检查 GRUB UEFI 模块
    checks_total=$((checks_total + 1))
    if [ -d "${STAGING_DIR}/boot/grub/x86_64-efi" ] && [ "$(ls -A "${STAGING_DIR}/boot/grub/x86_64-efi/" 2>/dev/null)" ]; then
        log "  [PASS] GRUB UEFI 模块存在"
        checks_passed=$((checks_passed + 1))
    else
        log "  [FAIL] GRUB UEFI 模块不存在"
    fi
    
    log "验证结果: ${checks_passed}/${checks_total} 通过"
    
    if [ "$checks_passed" -ne "$checks_total" ]; then
        error "构建验证失败"
    fi
}

# --- 输出构建摘要 ---
build_summary() {
    log "=== 构建摘要 ==="
    log "暂存目录: ${STAGING_DIR}"
    log "squashfs: $(du -sh "${STAGING_DIR}/live/filesystem.squashfs" 2>/dev/null | cut -f1)"
    log "内核:     $(du -sh "${STAGING_DIR}/boot/vmlinuz" 2>/dev/null | cut -f1)"
    log "initrd:   $(du -sh "${STAGING_DIR}/boot/initrd.img" 2>/dev/null | cut -f1)"
    log "GRUB:     $(du -sh "${STAGING_DIR}/boot/grub" 2>/dev/null | cut -f1)"
    log "总计:     $(du -sh "${STAGING_DIR}" 2>/dev/null | cut -f1)"
}

# --- 主程序 ---
main() {
    mkdir -p "$OUTPUT_DIR"
    
    log "=========================================="
    log "亚象安装器 - Live 环境构建"
    log "开始时间: $(date)"
    log "=========================================="
    
    preflight_check
    create_squashfs
    prepare_kernel
    prepare_grub
    verify_build
    build_summary
    
    log "=========================================="
    log "Live 环境构建完成"
    log "结束时间: $(date)"
    log "注意: 本阶段不制作最终 ISO"
    log "=========================================="
}

main "$@"
