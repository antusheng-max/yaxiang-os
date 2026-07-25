#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装器 - Live 根文件系统准备脚本
# prepare-live-rootfs.sh
# 
# 功能: 使用 debootstrap 创建最小 x86_64 Live 根文件系统
# 注意: 不操作真实块设备，不修改服务器网络
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
LIVE_DIR="${INSTALLER_DIR}/live"
ROOTFS_DIR="${LIVE_DIR}/rootfs"
LOG_DIR="${INSTALLER_DIR}/output"
LOG_FILE="${LOG_DIR}/live-build-current.log"

SUITE="jammy"
MIRROR="http://archive.ubuntu.com/ubuntu"
ARCH="amd64"

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
    log "=== 前置检查 ==="
    
    # 检查 root 权限
    if [ "$(id -u)" -ne 0 ]; then
        error "此脚本需要 root 权限运行"
    fi
    
    # 检查必要工具
    local required_tools=("debootstrap" "mksquashfs" "chroot")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            error "缺少必要工具: $tool"
        fi
    done
    log "所有必要工具已就绪"
    
    # 检查目录
    if [ ! -d "$INSTALLER_DIR" ]; then
        error "安装器目录不存在: $INSTALLER_DIR"
    fi
    
    log "前置检查通过"
}

# --- 创建根文件系统 ---
create_rootfs() {
    log "=== 创建 Live 根文件系统 ==="
    
    # 清理旧的 rootfs
    if [ -d "$ROOTFS_DIR" ] && [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
        log "清理旧的 rootfs..."
        rm -rf "${ROOTFS_DIR:?}/"*
    fi
    
    mkdir -p "$ROOTFS_DIR"
    
    log "使用 debootstrap 创建最小 ${ARCH} ${SUITE} 根文件系统..."
    log "镜像源: ${MIRROR}"
    
    debootstrap \
        --arch="$ARCH" \
        --variant=minbase \
        --include=locales,kbd,console-setup \
        "$SUITE" \
        "$ROOTFS_DIR" \
        "$MIRROR" \
        2>&1 | while IFS= read -r line; do
            log "  debootstrap: $line"
        done
    
    if [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
        error "debootstrap 失败: bash 不存在"
    fi
    
    log "根文件系统创建完成"
}

# --- 安装必要工具 ---
install_tools() {
    log "=== 安装 Live 环境工具 ==="
    
    # 配置 chroot 环境
    mount --bind /dev "$ROOTFS_DIR/dev" 2>/dev/null || true
    mount --bind /proc "$ROOTFS_DIR/proc" 2>/dev/null || true
    mount --bind /sys "$ROOTFS_DIR/sys" 2>/dev/null || true
    
    # 安装必要工具包
    local packages=(
        # 磁盘工具
        "util-linux"        # lsblk, findmnt, blkid
        "gdisk"             # sgdisk (仅用于 Live 环境检查，不执行写盘)
        "parted"            # 分区信息查看
        "dosfstools"        # FAT 文件系统工具
        
        # 系统工具
        "udev"              # udevadm
        "gzip"              # 压缩/解压
        "coreutils"         # sha256sum, dd, sync 等
        "mount"             # mount/umount (已在 util-linux)
        "kmod"              # 内核模块管理
        
        # 存储驱动支持 (内核模块自动包含)
        "linux-image-generic"  # 完整内核含驱动
        
        # 基础工具
        "bash"
        "nano"
        "less"
        "file"
        "pciutils"          # lspci
        "usbutils"          # lsusb
        "net-tools"         # ifconfig 等
        "iproute2"          # ip 命令
        
        # 安装器依赖
               # BIOS 引导
         # UEFI 引导
        
        
        
    )
    
    log "安装工具包: ${packages[*]}"
    chroot "$ROOTFS_DIR" apt-get update -qq 2>&1 | while IFS= read -r line; do
        log "  apt-update: $line"
    done
    
    chroot "$ROOTFS_DIR" apt-get install -y --no-install-recommends "${packages[@]}" 2>&1 | while IFS= read -r line; do
        log "  apt-install: $line"
    done
    
    log "工具安装完成"
}

# --- 配置 Live 环境 ---
configure_live() {
    log "=== 配置 Live 环境 ==="
    
    # 设置主机名
    echo "yaxiang-live" > "$ROOTFS_DIR/etc/hostname"
    
    # 配置 hosts
    cat > "$ROOTFS_DIR/etc/hosts" << HOSTS
127.0.0.1   localhost yaxiang-live
::1         localhost yaxiang-live
HOSTS
    
    # 禁用不需要的服务
    chroot "$ROOTFS_DIR" systemctl disable apt-daily.timer 2>/dev/null || true
    chroot "$ROOTFS_DIR" systemctl disable apt-daily-upgrade.timer 2>/dev/null || true
    chroot "$ROOTFS_DIR" systemctl disable motd-news.timer 2>/dev/null || true
    chroot "$ROOTFS_DIR" systemctl disable unattended-upgrades.service 2>/dev/null || true
    
    # 禁用开发服务（确保不启动）
    chroot "$ROOTFS_DIR" systemctl mask nginx.service 2>/dev/null || true
    chroot "$ROOTFS_DIR" systemctl mask nodejs.service 2>/dev/null || true
    
    # 配置串口控制台
    mkdir -p "$ROOTFS_DIR/etc/systemd/system/getty.target.wants"
    cat > "$ROOTFS_DIR/etc/systemd/system/serial-getty@ttyS0.service" << SERIAL
[Unit]
Description=Serial Getty on %I
After=systemd-user-sessions.service

[Service]
ExecStart=-/sbin/agetty -o -p -- \u --keep-baud 115200 %I $TERM
Restart=always
RestartSec=0

[Install]
WantedBy=getty.target
SERIAL
    ln -sf ../serial-getty@ttyS0.service "$ROOTFS_DIR/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service"
    
    # 配置自动登录 TTY1 (启动安装器)
    mkdir -p "$ROOTFS_DIR/etc/systemd/system/getty@tty1.service.d"
    cat > "$ROOTFS_DIR/etc/systemd/system/getty@tty1.service.d/autologin.conf" << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
AUTOLOGIN
    
    # 配置 root 自动启动安装器
    cat > "$ROOTFS_DIR/root/.bash_profile" << 'PROFILE'
#!/bin/bash
# 亚象安装器自动启动
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$YAXIANG_MAINTENANCE" ]; then
    if [ -x /opt/yaxiang-installer/yaxiang-installer ]; then
        /opt/yaxiang-installer/yaxiang-installer
    fi
fi
PROFILE
    
    # 创建安装器目录并复制文件
    mkdir -p "$ROOTFS_DIR/opt/yaxiang-installer/assets"
    
    # 配置 fstab (Live 环境)
    cat > "$ROOTFS_DIR/etc/fstab" << FSTAB
# 亚象 Live 环境 fstab
# <filesystem>  <mount>  <type>  <options>         <dump> <pass>
tmpfs           /tmp     tmpfs   defaults,noatime  0      0
tmpfs           /run     tmpfs   defaults,noatime  0      0
FSTAB
    
    # 设置 root 密码为空（Live 环境）
    chroot "$ROOTFS_DIR" passwd -d root 2>/dev/null || true
    
    log "Live 环境配置完成"
}

# --- 安装安装器文件 ---
install_installer_files() {
    log "=== 安装安装器文件 ==="
    
    # 复制安装器程序
    if [ -f "${INSTALLER_DIR}/src/yaxiang-installer" ]; then
        cp "${INSTALLER_DIR}/src/yaxiang-installer" "$ROOTFS_DIR/opt/yaxiang-installer/"
        chmod +x "$ROOTFS_DIR/opt/yaxiang-installer/yaxiang-installer"
        log "安装器程序已复制"
    else
        error "安装器程序不存在: ${INSTALLER_DIR}/src/yaxiang-installer"
    fi
    
    # 复制 banner
    if [ -f "${INSTALLER_DIR}/assets/banner.txt" ]; then
        cp "${INSTALLER_DIR}/assets/banner.txt" "$ROOTFS_DIR/opt/yaxiang-installer/assets/"
        log "Banner 已复制"
    fi
    
    # 复制系统镜像到 Live 环境
    if [ -d "${INSTALLER_DIR}/images" ]; then
        mkdir -p "$ROOTFS_DIR/opt/yaxiang-installer/images"
        cp "${INSTALLER_DIR}/images/combined.img.gz" "$ROOTFS_DIR/opt/yaxiang-installer/images/" 2>/dev/null || true
        cp "${INSTALLER_DIR}/images/combined-efi.img.gz" "$ROOTFS_DIR/opt/yaxiang-installer/images/" 2>/dev/null || true
        cp "${INSTALLER_DIR}/images/SHA256SUMS" "$ROOTFS_DIR/opt/yaxiang-installer/images/" 2>/dev/null || true
        log "系统镜像已复制到 Live 环境"
    fi
    
    log "安装器文件安装完成"
}

# --- 清理 ---
cleanup_rootfs() {
    log "=== 清理根文件系统 ==="
    
    # 卸载挂载点
    umount "$ROOTFS_DIR/sys" 2>/dev/null || true
    umount "$ROOTFS_DIR/proc" 2>/dev/null || true
    umount "$ROOTFS_DIR/dev" 2>/dev/null || true
    
    # 清理 apt 缓存
    rm -rf "$ROOTFS_DIR/var/cache/apt/archives/"*.deb 2>/dev/null || true
    rm -rf "$ROOTFS_DIR/var/lib/apt/lists/"* 2>/dev/null || true
    
    # 清理日志
    rm -rf "$ROOTFS_DIR/var/log/"*.log 2>/dev/null || true
    
    log "清理完成"
}

# --- 主程序 ---
main() {
    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"
    
    log "=========================================="
    log "亚象安装器 - Live 根文件系统准备"
    log "开始时间: $(date)"
    log "=========================================="
    
    preflight_check
    create_rootfs
    install_tools
    configure_live
    install_installer_files
    cleanup_rootfs
    
    log "=========================================="
    log "Live 根文件系统准备完成"
    log "结束时间: $(date)"
    log "根文件系统路径: ${ROOTFS_DIR}"
    log "根文件系统大小: $(du -sh "$ROOTFS_DIR" | cut -f1)"
    log "=========================================="
}

main "$@"
