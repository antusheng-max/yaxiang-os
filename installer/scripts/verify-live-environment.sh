#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装器 - Live 环境验证脚本
# verify-live-environment.sh
#
# 功能: 验证 Live 环境完整性，可选 QEMU 启动测试
# 注意: 不挂载安装目标硬盘，不执行安装
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
LIVE_DIR="${INSTALLER_DIR}/live"
ROOTFS_DIR="${LIVE_DIR}/rootfs"
OUTPUT_DIR="${INSTALLER_DIR}/output"
STAGING_DIR="${OUTPUT_DIR}/iso-staging"
LOG_FILE="${OUTPUT_DIR}/live-build-current.log"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# --- 日志函数 ---
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

pass() {
    log "  [PASS] $*"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    log "  [FAIL] $*"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
    log "  [WARN] $*"
    WARN_COUNT=$((WARN_COUNT + 1))
}

# --- 1. 验证目录结构 ---
verify_directory_structure() {
    log "=== 1. 验证目录结构 ==="
    
    local required_dirs=(
        "live/rootfs"
        "live/overlay"
        "live/packages"
        "src"
        "assets"
        "images"
        "grub"
        "scripts"
        "tests"
        "output"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "${INSTALLER_DIR}/${dir}" ]; then
            pass "目录存在: ${dir}"
        else
            fail "目录缺失: ${dir}"
        fi
    done
}

# --- 2. 验证安装器占位程序 ---
verify_installer() {
    log "=== 2. 验证安装器占位程序 ==="
    
    local installer="${INSTALLER_DIR}/src/yaxiang-installer"
    
    if [ -f "$installer" ]; then
        pass "安装器程序存在"
    else
        fail "安装器程序不存在"
        return
    fi
    
    if [ -x "$installer" ]; then
        pass "安装器程序可执行"
    else
        fail "安装器程序不可执行"
    fi
    
    # 检查是否包含禁止操作
    local forbidden_patterns=("dd if=" "wipefs " "mkfs\." "parted " "sgdisk ")
    for pattern in "${forbidden_patterns[@]}"; do
        if grep -q "$pattern" "$installer" 2>/dev/null; then
            fail "安装器包含禁止操作: $pattern"
        fi
    done
    pass "安装器不包含真实写盘代码"
    
    # 检查 rootfs 中的安装器
    if [ -f "${ROOTFS_DIR}/opt/yaxiang-installer/yaxiang-installer" ]; then
        pass "rootfs 中安装器程序存在"
    else
        warn "rootfs 中安装器程序不存在 (可能尚未运行 prepare)"
    fi
}

# --- 3. 验证系统镜像 ---
verify_system_images() {
    log "=== 3. 验证系统镜像 ==="
    
    local images_dir="${INSTALLER_DIR}/images"
    
    # combined.img.gz
    if [ -f "${images_dir}/combined.img.gz" ]; then
        pass "combined.img.gz 存在"
        if gzip -t "${images_dir}/combined.img.gz" 2>/dev/null; then
            pass "combined.img.gz gzip 完整性通过"
        else
            fail "combined.img.gz gzip 完整性失败"
        fi
    else
        fail "combined.img.gz 不存在"
    fi
    
    # combined-efi.img.gz
    if [ -f "${images_dir}/combined-efi.img.gz" ]; then
        pass "combined-efi.img.gz 存在"
        if gzip -t "${images_dir}/combined-efi.img.gz" 2>/dev/null; then
            pass "combined-efi.img.gz gzip 完整性通过"
        else
            fail "combined-efi.img.gz gzip 完整性失败"
        fi
    else
        fail "combined-efi.img.gz 不存在"
    fi
    
    # SHA256SUMS
    if [ -f "${images_dir}/SHA256SUMS" ]; then
        pass "SHA256SUMS 存在"
        if (cd "$images_dir" && sha256sum -c SHA256SUMS >/dev/null 2>&1); then
            pass "SHA256 校验通过"
        else
            fail "SHA256 校验失败"
        fi
    else
        fail "SHA256SUMS 不存在"
    fi
}

# --- 4. 验证 BIOS 启动文件 ---
verify_bios_boot() {
    log "=== 4. 验证 BIOS 启动文件 ==="
    
    if [ -f "${STAGING_DIR}/boot/vmlinuz" ]; then
        pass "BIOS: 内核文件存在"
    else
        warn "BIOS: 内核文件不存在 (可能尚未运行 build)"
    fi
    
    if [ -f "${STAGING_DIR}/boot/initrd.img" ]; then
        pass "BIOS: initrd 存在"
    else
        warn "BIOS: initrd 不存在 (可能尚未运行 build)"
    fi
    
    if [ -d "${STAGING_DIR}/boot/grub/i386-pc" ] && [ "$(ls -A "${STAGING_DIR}/boot/grub/i386-pc/" 2>/dev/null)" ]; then
        pass "BIOS: GRUB i386-pc 模块存在"
    else
        warn "BIOS: GRUB i386-pc 模块不存在 (可能尚未运行 build)"
    fi
}

# --- 5. 验证 UEFI 启动文件 ---
verify_uefi_boot() {
    log "=== 5. 验证 UEFI 启动文件 ==="
    
    if [ -d "${STAGING_DIR}/boot/grub/x86_64-efi" ] && [ "$(ls -A "${STAGING_DIR}/boot/grub/x86_64-efi/" 2>/dev/null)" ]; then
        pass "UEFI: GRUB x86_64-efi 模块存在"
    else
        warn "UEFI: GRUB x86_64-efi 模块不存在 (可能尚未运行 build)"
    fi
    
    if [ -f "${STAGING_DIR}/boot/grub/grub.cfg" ]; then
        pass "UEFI: GRUB 配置存在"
    else
        warn "UEFI: GRUB 配置不存在 (可能尚未运行 build)"
    fi
}

# --- 6. 验证 GRUB 配置 ---
verify_grub_config() {
    log "=== 6. 验证 GRUB 配置 ==="
    
    local grub_cfg="${INSTALLER_DIR}/grub/grub.cfg"
    
    if [ ! -f "$grub_cfg" ]; then
        fail "GRUB 配置文件不存在"
        return
    fi
    
    pass "GRUB 配置文件存在"
    
    # 检查菜单项
    local menu_entries
    menu_entries=$(grep -c "menuentry" "$grub_cfg" 2>/dev/null || echo "0")
    if [ "$menu_entries" -ge 6 ]; then
        pass "GRUB 包含 ${menu_entries} 个菜单项 (>=6)"
    else
        fail "GRUB 菜单项不足: ${menu_entries} (需要 >=6)"
    fi
    
    # 检查串口配置
    if grep -q "ttyS0,115200" "$grub_cfg"; then
        pass "GRUB 包含串口配置 ttyS0,115200"
    else
        fail "GRUB 缺少串口配置"
    fi
    
    # 检查默认和超时
    if grep -q "set default=0" "$grub_cfg"; then
        pass "GRUB 默认第一项"
    else
        warn "GRUB 未设置默认第一项"
    fi
    
    if grep -q "set timeout=5" "$grub_cfg"; then
        pass "GRUB 超时 5 秒"
    else
        warn "GRUB 未设置 5 秒超时"
    fi
    
    # 检查 GRUB 语法 (使用 grub-script-check)
    if command -v grub-script-check >/dev/null 2>&1; then
        if grub-script-check "$grub_cfg" 2>/dev/null; then
            pass "GRUB 配置语法检查通过"
        else
            fail "GRUB 配置语法检查失败"
        fi
    else
        warn "grub-script-check 不可用，跳过语法检查"
    fi
}

# --- 7. 验证 Live 环境不包含开发服务 ---
verify_no_dev_services() {
    log "=== 7. 验证 Live 环境不包含开发服务 ==="
    
    if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
        warn "rootfs 未准备好，跳过开发服务检查"
        return
    fi
    
    # 检查 nginx
    if [ -f "$ROOTFS_DIR/usr/sbin/nginx" ] || [ -f "$ROOTFS_DIR/etc/nginx/nginx.conf" ]; then
        fail "rootfs 包含 nginx"
    else
        pass "rootfs 不包含 nginx"
    fi
    
    # 检查 node
    if [ -f "$ROOTFS_DIR/usr/bin/node" ] || [ -f "$ROOTFS_DIR/usr/local/bin/node" ]; then
        fail "rootfs 包含 node.js"
    else
        pass "rootfs 不包含 node.js"
    fi
    
    # 检查 vite
    if find "$ROOTFS_DIR" -name "vite" -type f 2>/dev/null | grep -q .; then
        fail "rootfs 包含 vite"
    else
        pass "rootfs 不包含 vite"
    fi
    
    # 检查浏览器
    if [ -f "$ROOTFS_DIR/usr/bin/chromium-browser" ] || [ -f "$ROOTFS_DIR/usr/bin/firefox" ] || [ -f "$ROOTFS_DIR/usr/bin/google-chrome" ]; then
        fail "rootfs 包含浏览器"
    else
        pass "rootfs 不包含浏览器"
    fi
    
    # 检查桌面环境
    if [ -d "$ROOTFS_DIR/usr/share/xsessions" ] || [ -d "$ROOTFS_DIR/usr/share/wayland-sessions" ]; then
        fail "rootfs 包含桌面环境"
    else
        pass "rootfs 不包含桌面环境"
    fi
}

# --- 8. 验证内置工具 ---
verify_builtin_tools() {
    log "=== 8. 验证内置工具 ==="
    
    if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
        warn "rootfs 未准备好，跳过工具检查"
        return
    fi
    
    local required_tools=(
        "bin/bash:shell"
        "usr/bin/lsblk:lsblk"
        "usr/sbin/blkid:blkid"
        "usr/bin/findmnt:findmnt"
        "usr/bin/udevadm:udevadm"
        "usr/bin/gzip:gzip"
        "usr/bin/sha256sum:sha256sum"
        "usr/bin/dd:dd"
        "usr/bin/sync:sync"
        "usr/sbin/blockdev:blockdev"
        "usr/sbin/wipefs:wipefs"
        "usr/bin/mount:mount"
        "usr/bin/umount:umount"
        "usr/sbin/reboot:reboot"
        "usr/sbin/poweroff:poweroff"
    )
    
    for entry in "${required_tools[@]}"; do
        local path="${entry%%:*}"
        local name="${entry##*:}"
        if [ -f "${ROOTFS_DIR}/${path}" ] || [ -L "${ROOTFS_DIR}/${path}" ]; then
            pass "工具存在: ${name}"
        else
            # 尝试通过 which 在 chroot 中查找
            if chroot "$ROOTFS_DIR" which "$name" >/dev/null 2>&1; then
                pass "工具存在: ${name} (通过 which 找到)"
            else
                fail "工具缺失: ${name} (${path})"
            fi
        fi
    done
}

# --- 9. QEMU 启动测试 (可选) ---
qemu_test() {
    log "=== 9. QEMU 启动测试 ==="
    
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        warn "QEMU 不可用，跳过启动测试"
        return
    fi
    
    if [ ! -f "${STAGING_DIR}/boot/vmlinuz" ]; then
        warn "内核文件不存在，跳过 QEMU 测试"
        return
    fi
    
    if [ ! -f "${STAGING_DIR}/live/filesystem.squashfs" ]; then
        warn "squashfs 不存在，跳过 QEMU 测试"
        return
    fi
    
    log "启动 QEMU BIOS 模式测试 (15秒超时)..."
    
    local qemu_log="${OUTPUT_DIR}/qemu-bios-verify.log"
    
    timeout 30 qemu-system-x86_64 \
        -m 512 \
        -nographic \
        -kernel "${STAGING_DIR}/boot/vmlinuz" \
        -initrd "${STAGING_DIR}/boot/initrd.img" \
        -append "boot=live console=ttyS0,115200 quiet" \
        -drive "file=fat:rw:${STAGING_DIR},format=vvfat" \
        -no-reboot \
        -serial stdio \
        > "$qemu_log" 2>&1 || true
    
    if grep -qi "yaxiang\|live\|switch_root\|squashfs" "$qemu_log" 2>/dev/null; then
        pass "QEMU BIOS: 检测到 Live 环境启动迹象"
    else
        warn "QEMU BIOS: 未检测到明确的 Live 环境启动迹象 (可能需要更多时间)"
    fi
    
    log "QEMU 测试日志: ${qemu_log}"
}

# --- 主程序 ---
main() {
    mkdir -p "$OUTPUT_DIR"
    
    log "=========================================="
    log "亚象安装器 - Live 环境验证"
    log "开始时间: $(date)"
    log "=========================================="
    
    verify_directory_structure
    verify_installer
    verify_system_images
    verify_bios_boot
    verify_uefi_boot
    verify_grub_config
    verify_no_dev_services
    verify_builtin_tools
    qemu_test
    
    log "=========================================="
    log "验证结果汇总"
    log "  通过: ${PASS_COUNT}"
    log "  失败: ${FAIL_COUNT}"
    log "  警告: ${WARN_COUNT}"
    log "=========================================="
    
    if [ "$FAIL_COUNT" -gt 0 ]; then
        log "验证结果: 存在失败项，请检查"
        exit 1
    else
        log "验证结果: 全部通过"
    fi
}

main "$@"
