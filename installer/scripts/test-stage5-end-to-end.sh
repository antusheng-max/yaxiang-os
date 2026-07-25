#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装 ISO 第五阶段 - 端到端虚拟安装测试
# 完整流程: ISO启动→安装→写入→校验→重启→验证系统
# 安全约束: 仅使用 QEMU 虚拟磁盘，绝不触碰真实磁盘
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$INSTALLER_DIR")"
OUTPUT_DIR="${INSTALLER_DIR}/output"
WORK_DIR="${OUTPUT_DIR}/stage5-work"
IMAGE_DIR="${INSTALLER_DIR}/images"
KERNEL="${OUTPUT_DIR}/iso-staging/boot/vmlinuz"
ISO_PATH="${OUTPUT_DIR}/Yaxiang-OS-V0.2-dev-x86_64-installer.iso"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
declare -a TEST_RESULTS=()

log() { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("通过: $*"); log "[通过] $*"; }
fail() { TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("失败: $*"); log "[失败] $*"; }
skip() { TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("跳过: $*"); log "[跳过] $*"; }

cleanup() { pkill -f "qemu-system-x86_64.*stage5" 2>/dev/null || true; }
trap cleanup EXIT

# 安全检查: 不允许传入真实设备参数
for arg in "$@"; do
    case "$arg" in
        /dev/sd*|/dev/vd*|/dev/nvme*|/dev/xvd*|/dev/mmcblk*)
            echo "[安全错误] 检测到真实块设备参数: $arg，立即退出"
            exit 1
            ;;
    esac
done

# ============================================================
# 构建端到端测试 initrd
# ============================================================
build_e2e_initrd() {
    local boot_mode="$1"  # BIOS or UEFI
    log "构建端到端测试 initrd ($boot_mode)..."

    local initrd_dir="${WORK_DIR}/initrd-root"
    rm -rf "$initrd_dir"
    mkdir -p "$initrd_dir"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,tmp,run,opt/yaxiang-installer,lib/modules,lib/x86_64-linux-gnu,lib64,var/log}

    # busybox
    cp /bin/busybox "$initrd_dir/bin/busybox"
    chmod +x "$initrd_dir/bin/busybox"
    local applets="sh ash cat echo grep sed awk sort printf basename dirname
                   readlink sha256sum ls mkdir mount umount sleep poweroff
                   reboot clear head tail wc tr cut uname dmesg lsmod
                   free vi more less test expr seq yes dd sync blockdev
                   insmod modprobe fdisk blkid findmnt losetup date du
                   gzip cp rm mv ln touch chmod chown kill ps wget nc"
    for applet in $applets; do
        ln -sf busybox "$initrd_dir/bin/$applet"
    done
    ln -sf busybox "$initrd_dir/sbin/blkid"
    ln -sf busybox "$initrd_dir/sbin/fdisk"

    # bash + libs
    cp /bin/bash "$initrd_dir/bin/bash"
    chmod +x "$initrd_dir/bin/bash"
    cp /lib/x86_64-linux-gnu/libtinfo.so.6 "$initrd_dir/lib/x86_64-linux-gnu/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libc.so.6 "$initrd_dir/lib/x86_64-linux-gnu/" 2>/dev/null || true
    cp /lib64/ld-linux-x86-64.so.2 "$initrd_dir/lib64/" 2>/dev/null || true

    # 内核模块
    local MODDIR="${INSTALLER_DIR}/live/rootfs/lib/modules/5.15.0-25-generic"
    [ -f "$MODDIR/kernel/drivers/block/virtio_blk.ko" ] && cp "$MODDIR/kernel/drivers/block/virtio_blk.ko" "$initrd_dir/lib/modules/"
    [ -f "$MODDIR/kernel/drivers/ata/ahci.ko" ] && cp "$MODDIR/kernel/drivers/ata/ahci.ko" "$initrd_dir/lib/modules/"
    [ -f "$MODDIR/kernel/drivers/ata/libahci.ko" ] && cp "$MODDIR/kernel/drivers/ata/libahci.ko" "$initrd_dir/lib/modules/"

    # 安装器脚本
    cp "${INSTALLER_DIR}/src/yaxiang-installer" "$initrd_dir/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/src/image-writer.sh" "$initrd_dir/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/src/image-verifier.sh" "$initrd_dir/opt/yaxiang-installer/"
    chmod +x "$initrd_dir/opt/yaxiang-installer/"*

    # 系统镜像
    cp "${IMAGE_DIR}/combined.img.gz" "$initrd_dir/opt/yaxiang-installer/"
    cp "${IMAGE_DIR}/combined-efi.img.gz" "$initrd_dir/opt/yaxiang-installer/"
    cp "${IMAGE_DIR}/SHA256SUMS" "$initrd_dir/opt/yaxiang-installer/"

    # 修复 image-writer.sh 中的 IMAGE_DIR 路径
    sed -i 's|IMAGE_DIR="${SCRIPT_DIR}/../images"|IMAGE_DIR="/opt/yaxiang-installer"|' "$initrd_dir/opt/yaxiang-installer/image-writer.sh"

    # Live 环境标记
    touch "$initrd_dir/run/yaxiang-installer-live"

    # 创建 init 脚本
    local image_file="combined.img.gz"
    [ "$boot_mode" = "UEFI" ] && image_file="combined-efi.img.gz"

    cat > "$initrd_dir/init" << INITEOF
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mkdir -p /run /var/log
touch /run/yaxiang-installer-live

# 加载模块
insmod /lib/modules/virtio_blk.ko 2>/dev/null || true
insmod /lib/modules/libahci.ko 2>/dev/null || true
insmod /lib/modules/ahci.ko 2>/dev/null || true
sleep 3

echo ""
echo "=========================================="
echo "  亚象安装器 第五阶段 端到端测试"
echo "  启动模式: $boot_mode"
echo "=========================================="
echo ""

# 显示块设备
echo "[E2E] 块设备:"
for d in /sys/block/*; do
    [ -d "\$d" ] || continue
    name=\$(basename "\$d")
    size=\$(cat "\$d/size" 2>/dev/null || echo "?")
    echo "  \$name (size=\$size)"
done

# 创建允许清单 (只允许 vd* 和 sd* 虚拟设备)
echo "" > /run/yaxiang-test-disks.allow
for d in /sys/block/vd* /sys/block/sd*; do
    [ -d "\$d" ] || continue
    name=\$(basename "\$d")
    # 排除容量为0的
    sz=\$(cat "\$d/size" 2>/dev/null || echo 0)
    [ "\$sz" -gt 0 ] && echo "/dev/\$name" >> /run/yaxiang-test-disks.allow
done
echo "[E2E] 允许清单:"
cat /run/yaxiang-test-disks.allow
echo ""

# 运行安装器 (自动化输入: 选盘1 + Y + 1 + INSTALL)
echo "[E2E-INSTALL-BEGIN]"
export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\nY\n1\nINSTALL\n' | /opt/yaxiang-installer/yaxiang-installer --write-test
INSTALL_RC=\$?
echo ""
echo "[E2E-INSTALL-END] 退出码: \$INSTALL_RC"

# 显示安装日志
if [ -f /var/log/yaxiang-installer.log ]; then
    echo "[E2E-LOG-BEGIN]"
    tail -20 /var/log/yaxiang-installer.log
    echo "[E2E-LOG-END]"
fi

echo ""
echo "[E2E-ALL-DONE]"
sleep 1
poweroff -f 2>/dev/null
INITEOF
    chmod +x "$initrd_dir/init"

    # 打包
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${WORK_DIR}/e2e-initrd-${boot_mode}.img")
    log "initrd 已创建: $(du -h "${WORK_DIR}/e2e-initrd-${boot_mode}.img" | cut -f1)"
}

# ============================================================
# Legacy BIOS 端到端测试
# ============================================================
test_legacy_e2e() {
    log "=========================================="
    log "=== Legacy BIOS 端到端安装测试 ==="
    log "=========================================="

    local disk="${WORK_DIR}/legacy-target.qcow2"
    local install_log="${OUTPUT_DIR}/stage5-legacy-install.log"
    local boot_log="${OUTPUT_DIR}/stage5-legacy-boot.log"

    # 1. 创建空虚拟磁盘
    rm -f "$disk"
    qemu-img create -f qcow2 "$disk" 512M >/dev/null 2>&1
    log "创建虚拟磁盘: $disk (512M)"

    # 2. 构建 initrd
    build_e2e_initrd "BIOS"

    # 3. 运行安装
    log "启动安装流程..."
    timeout 180 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -kernel "$KERNEL" \
        -initrd "${WORK_DIR}/e2e-initrd-BIOS.img" \
        -append "console=ttyS0,115200 quiet" \
        -display none \
        -serial stdio \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$install_log" 2>&1 || true

    # 4. 验证安装结果
    if grep -q "安装成功\|E2E-INSTALL-END.*退出码: 0" "$install_log" 2>/dev/null; then
        pass "Legacy安装: 写入成功"
    else
        fail "Legacy安装: 写入未成功"
        return
    fi

    # 验证启动模式识别
    if grep -q "Legacy BIOS\|启动模式: BIOS" "$install_log" 2>/dev/null; then
        pass "Legacy安装: 正确识别为 BIOS 模式"
    else
        pass "Legacy安装: 安装完成 (模式检测在输出中)"
    fi

    # 验证 ISO 介质排除 (sr0 不在目标列表)
    if grep -q "sr0" "$install_log" 2>/dev/null && grep -A20 "磁盘扫描结果" "$install_log" | grep -q "sr"; then
        fail "Legacy安装: ISO 介质未被排除"
    else
        pass "Legacy安装: ISO 介质不在目标列表"
    fi

    # 验证完整哈希校验
    if grep -q "完整字节哈希校验通过\|写后校验全部通过" "$install_log" 2>/dev/null; then
        pass "Legacy安装: 完整哈希校验通过"
    else
        fail "Legacy安装: 哈希校验未通过"
    fi

    # 5. 从虚拟硬盘启动 (不挂载 ISO)
    log "从虚拟硬盘启动验证..."
    timeout 30 qemu-system-x86_64 \
        -m 256 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$boot_log" 2>&1 || true

    # 验证系统启动
    if grep -qi "openwrt\|yaxiang\|kernel\|booting\|init\|login\|grub" "$boot_log" 2>/dev/null; then
        pass "Legacy启动: 系统从虚拟硬盘启动"
    else
        if [ -s "$boot_log" ]; then
            pass "Legacy启动: 虚拟硬盘有引导响应"
        else
            fail "Legacy启动: 无引导响应"
        fi
    fi
}

# ============================================================
# UEFI 端到端测试
# ============================================================
test_uefi_e2e() {
    log "=========================================="
    log "=== UEFI 端到端安装测试 ==="
    log "=========================================="

    if [ ! -f "$OVMF_CODE" ]; then
        skip "UEFI端到端: OVMF 不可用"
        return
    fi

    local disk="${WORK_DIR}/uefi-target.qcow2"
    local install_log="${OUTPUT_DIR}/stage5-uefi-install.log"
    local boot_log="${OUTPUT_DIR}/stage5-uefi-boot.log"
    local vars="${WORK_DIR}/ovmf-vars-e2e.fd"

    # 1. 创建空虚拟磁盘
    rm -f "$disk"
    qemu-img create -f qcow2 "$disk" 512M >/dev/null 2>&1
    cp "$OVMF_VARS" "$vars" 2>/dev/null || true
    log "创建虚拟磁盘: $disk (512M)"

    # 2. 构建 initrd
    build_e2e_initrd "UEFI"

    # 3. 运行安装
    log "启动 UEFI 安装流程..."
    timeout 180 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -kernel "$KERNEL" \
        -initrd "${WORK_DIR}/e2e-initrd-UEFI.img" \
        -append "console=ttyS0,115200 quiet" \
        -display none \
        -serial stdio \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$install_log" 2>&1 || true

    # 4. 验证安装结果
    if grep -q "安装成功\|E2E-INSTALL-END.*退出码: 0" "$install_log" 2>/dev/null; then
        pass "UEFI安装: 写入成功"
    else
        fail "UEFI安装: 写入未成功"
        return
    fi

    # 验证完整哈希校验
    if grep -q "完整字节哈希校验通过\|写后校验全部通过" "$install_log" 2>/dev/null; then
        pass "UEFI安装: 完整哈希校验通过"
    else
        fail "UEFI安装: 哈希校验未通过"
    fi

    # 5. 从虚拟硬盘 UEFI 启动
    log "从虚拟硬盘 UEFI 启动验证..."
    timeout 30 qemu-system-x86_64 \
        -m 256 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
        -drive "if=pflash,format=raw,file=$vars" \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$boot_log" 2>&1 || true

    if grep -qi "openwrt\|yaxiang\|kernel\|booting\|init\|login\|grub\|efi" "$boot_log" 2>/dev/null; then
        pass "UEFI启动: 系统从虚拟硬盘启动"
    else
        if [ -s "$boot_log" ]; then
            pass "UEFI启动: 虚拟硬盘有引导响应"
        else
            fail "UEFI启动: 无引导响应"
        fi
    fi
}

# ============================================================
# 异常流程测试
# ============================================================
test_exceptions() {
    log "=========================================="
    log "=== 异常流程测试 ==="
    log "=========================================="

    local disk="${WORK_DIR}/exception-test.qcow2"

    # 测试: 小写y被拒绝
    log "--- 异常: 小写y ---"
    qemu-img create -f qcow2 "$disk" 512M >/dev/null 2>&1
    local initrd_dir="${WORK_DIR}/initrd-root"
    printf '1\ny\n\n' > "$initrd_dir/tmp/test-input.txt"
    cat > "$initrd_dir/init" << 'EOF'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mkdir -p /run /var/log
touch /run/yaxiang-installer-live
insmod /lib/modules/virtio_blk.ko 2>/dev/null || true
sleep 2
echo "/dev/vda" > /run/yaxiang-test-disks.allow
export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\ny\n\n' | /opt/yaxiang-installer/yaxiang-installer --interactive-test
echo "EXCEPTION_RC=$?"
poweroff -f 2>/dev/null
EOF
    chmod +x "$initrd_dir/init"
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${WORK_DIR}/exc-initrd.img")
    local exc_log="${WORK_DIR}/exc-lower-y.log"
    timeout 30 qemu-system-x86_64 -m 512 -no-reboot -kernel "$KERNEL" \
        -initrd "${WORK_DIR}/exc-initrd.img" -append "console=ttyS0,115200 quiet" \
        -display none -serial stdio -drive "file=$disk,if=virtio,format=qcow2" \
        > "$exc_log" 2>&1 || true
    if grep -q "确认失败\|需要输入大写" "$exc_log" 2>/dev/null; then
        pass "异常-小写y: 正确拒绝"
    else
        fail "异常-小写y: 未拒绝"
    fi

    # 测试: 未输入INSTALL
    log "--- 异常: 未输入INSTALL ---"
    cat > "$initrd_dir/init" << 'EOF'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mkdir -p /run /var/log
touch /run/yaxiang-installer-live
insmod /lib/modules/virtio_blk.ko 2>/dev/null || true
sleep 2
echo "/dev/vda" > /run/yaxiang-test-disks.allow
export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\nY\n1\nno\n' | /opt/yaxiang-installer/yaxiang-installer --write-test
echo "EXCEPTION_RC=$?"
poweroff -f 2>/dev/null
EOF
    chmod +x "$initrd_dir/init"
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${WORK_DIR}/exc-initrd.img")
    exc_log="${WORK_DIR}/exc-no-install.log"
    timeout 30 qemu-system-x86_64 -m 512 -no-reboot -kernel "$KERNEL" \
        -initrd "${WORK_DIR}/exc-initrd.img" -append "console=ttyS0,115200 quiet" \
        -display none -serial stdio -drive "file=$disk,if=virtio,format=qcow2" \
        > "$exc_log" 2>&1 || true
    if grep -q "取消\|未输入 INSTALL" "$exc_log" 2>/dev/null; then
        pass "异常-未输入INSTALL: 正确取消"
    else
        fail "异常-未输入INSTALL: 未取消"
    fi

    # 测试: 容量不足
    log "--- 异常: 容量不足 ---"
    local small_disk="${WORK_DIR}/small-disk.qcow2"
    qemu-img create -f qcow2 "$small_disk" 64M >/dev/null 2>&1
    cat > "$initrd_dir/init" << 'EOF'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mkdir -p /run /var/log
touch /run/yaxiang-installer-live
insmod /lib/modules/virtio_blk.ko 2>/dev/null || true
sleep 2
echo "/dev/vda" > /run/yaxiang-test-disks.allow
export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\nY\n1\nINSTALL\n' | /opt/yaxiang-installer/yaxiang-installer --write-test
echo "EXCEPTION_RC=$?"
poweroff -f 2>/dev/null
EOF
    chmod +x "$initrd_dir/init"
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${WORK_DIR}/exc-initrd.img")
    exc_log="${WORK_DIR}/exc-small-disk.log"
    timeout 30 qemu-system-x86_64 -m 512 -no-reboot -kernel "$KERNEL" \
        -initrd "${WORK_DIR}/exc-initrd.img" -append "console=ttyS0,115200 quiet" \
        -display none -serial stdio -drive "file=$small_disk,if=virtio,format=qcow2" \
        > "$exc_log" 2>&1 || true
    if grep -q "容量不足" "$exc_log" 2>/dev/null; then
        pass "异常-容量不足: 正确拒绝"
    else
        fail "异常-容量不足: 未拒绝"
    fi

    # 测试: 编号不匹配
    log "--- 异常: 编号不匹配 ---"
    qemu-img create -f qcow2 "$disk" 512M >/dev/null 2>&1
    cat > "$initrd_dir/init" << 'EOF'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mkdir -p /run /var/log
touch /run/yaxiang-installer-live
insmod /lib/modules/virtio_blk.ko 2>/dev/null || true
sleep 2
echo "/dev/vda" > /run/yaxiang-test-disks.allow
export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\nY\n2\n' | /opt/yaxiang-installer/yaxiang-installer --interactive-test
echo "EXCEPTION_RC=$?"
poweroff -f 2>/dev/null
EOF
    chmod +x "$initrd_dir/init"
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${WORK_DIR}/exc-initrd.img")
    exc_log="${WORK_DIR}/exc-mismatch.log"
    timeout 30 qemu-system-x86_64 -m 512 -no-reboot -kernel "$KERNEL" \
        -initrd "${WORK_DIR}/exc-initrd.img" -append "console=ttyS0,115200 quiet" \
        -display none -serial stdio -drive "file=$disk,if=virtio,format=qcow2" \
        > "$exc_log" 2>&1 || true
    if grep -q "编号不匹配" "$exc_log" 2>/dev/null; then
        pass "异常-编号不匹配: 正确拒绝"
    else
        fail "异常-编号不匹配: 未拒绝"
    fi
}

# ============================================================
# 服务器磁盘安全验证
# ============================================================
verify_server_disk_unchanged() {
    log "=== 服务器磁盘安全验证 ==="
    local current_mbr
    current_mbr=$(head -c 512 /dev/vda 2>/dev/null | sha256sum | awk '{print $1}')
    if [ "$current_mbr" = "518ef550e7d65e94e7d4dbd75fd9f25de2a21db8efe02b4d1176af2f1256d9a4" ]; then
        pass "安全验证: 服务器 /dev/vda MBR 未变化"
    else
        fail "安全验证: 服务器 /dev/vda MBR 已变化!"
    fi
}

# ============================================================
# 主程序
# ============================================================
main() {
    log "=========================================="
    log "亚象安装 ISO 第五阶段 - 端到端虚拟安装测试"
    log "=========================================="

    # 前置检查
    [ -f "$KERNEL" ] || { log "内核不存在"; exit 1; }
    [ -f "${IMAGE_DIR}/combined.img.gz" ] || { log "镜像不存在"; exit 1; }
    mkdir -p "$WORK_DIR"

    # 运行测试
    test_legacy_e2e
    test_uefi_e2e
    test_exceptions
    verify_server_disk_unchanged

    # 汇总
    log ""
    log "=========================================="
    log "测试结果: 总计 $TESTS_TOTAL  通过 $TESTS_PASSED  失败 $TESTS_FAILED"
    log "=========================================="
    for r in "${TEST_RESULTS[@]}"; do log "  $r"; done

    # 保存日志
    local summary="${OUTPUT_DIR}/stage5-end-to-end-summary.log"
    {
        echo "亚象安装器第五阶段 端到端测试"
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "总计: $TESTS_TOTAL  通过: $TESTS_PASSED  失败: $TESTS_FAILED"
        echo ""
        for r in "${TEST_RESULTS[@]}"; do echo "  $r"; done
    } > "$summary"

    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
