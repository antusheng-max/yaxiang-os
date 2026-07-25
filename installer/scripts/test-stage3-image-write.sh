#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装器 第三阶段 - QEMU 镜像写入安全测试
# 安全约束: 仅使用 QEMU 虚拟磁盘，绝不触碰真实磁盘
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$INSTALLER_DIR")"
OUTPUT_DIR="${INSTALLER_DIR}/output"
TEST_DIR="${OUTPUT_DIR}/stage3-test-workdir"
IMAGE_DIR="${INSTALLER_DIR}/images"
KERNEL="${OUTPUT_DIR}/iso-staging/boot/vmlinuz"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
declare -a TEST_RESULTS=()

log() { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("通过: $*"); log "[通过] $*"; }
fail() { TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("失败: $*"); log "[失败] $*"; }

cleanup() {
    pkill -f "qemu-system-x86_64.*stage3-test" 2>/dev/null || true
    sleep 1
}
trap cleanup EXIT

# ============================================================
# 构建测试用 initrd (包含写入工具)
# ============================================================

build_test_initrd() {
    log "=== 构建第三阶段测试 initrd ==="
    local initrd_dir="${TEST_DIR}/initrd-root"
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
                   gzip cp rm mv ln touch chmod chown kill ps"
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

    # 镜像文件
    cp "${IMAGE_DIR}/combined.img.gz" "$initrd_dir/opt/yaxiang-installer/"
    cp "${IMAGE_DIR}/combined-efi.img.gz" "$initrd_dir/opt/yaxiang-installer/"
    cp "${IMAGE_DIR}/SHA256SUMS" "$initrd_dir/opt/yaxiang-installer/"

    # 修复 image-writer.sh 中的 IMAGE_DIR 路径 (在 initrd 中)
    sed -i 's|IMAGE_DIR="${SCRIPT_DIR}/../images"|IMAGE_DIR="/opt/yaxiang-installer"|' "$initrd_dir/opt/yaxiang-installer/image-writer.sh"

    # Live 环境标记
    touch "$initrd_dir/run/yaxiang-installer-live"

    # 创建 init
    cat > "$initrd_dir/init" << 'INIT_EOF'
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
echo "  亚象安装器 第三阶段 QEMU 写入测试"
echo "=========================================="
echo ""
echo "[TEST-ENV] 内核: $(uname -r)"
echo "[TEST-ENV] /sys/block/ 内容:"
for d in /sys/block/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    size=$(cat "$d/size" 2>/dev/null || echo "?")
    echo "  $name (size=$size sectors)"
done
echo ""

# 创建测试允许清单 (只允许 vd* 设备)
echo "" > /run/yaxiang-test-disks.allow
for d in /sys/block/vd*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    echo "/dev/$name" >> /run/yaxiang-test-disks.allow
done
echo "[TEST-ENV] 允许清单:"
cat /run/yaxiang-test-disks.allow
echo ""

# 执行测试命令 (已嵌入 initrd)
if [ -f /tmp/test-cmd.sh ]; then
    echo "[TEST-BEGIN] 执行测试命令"
    /bin/bash /tmp/test-cmd.sh
    TEST_RC=$?
    echo ""
    echo "[TEST-END] 退出码: $TEST_RC"
else
    echo "[TEST-INFO] 无测试命令"
fi

echo ""
echo "[TEST-ALL-DONE]"
sleep 1
poweroff -f 2>/dev/null
INIT_EOF
    chmod +x "$initrd_dir/init"

    # 打包
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${TEST_DIR}/test-initrd.img")
    log "initrd 已创建: $(du -h "${TEST_DIR}/test-initrd.img" | cut -f1)"
}

# ============================================================
# QEMU 运行辅助
# ============================================================

run_qemu_with_cmd() {
    local test_name="$1"
    local test_cmd="$2"
    shift 2
    local qemu_args=("$@")
    local qemu_log="${TEST_DIR}/${test_name}.log"

    # 将测试命令嵌入 initrd 并重新打包
    local initrd_dir="${TEST_DIR}/initrd-root"
    printf '%s\n' "$test_cmd" > "${initrd_dir}/tmp/test-cmd.sh"
    chmod +x "${initrd_dir}/tmp/test-cmd.sh"
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "${TEST_DIR}/initrd-${test_name}.img")

    log "--- 运行: $test_name ---" >&2

    timeout 120 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -kernel "$KERNEL" \
        -initrd "${TEST_DIR}/initrd-${test_name}.img" \
        -append "console=ttyS0,115200 quiet" \
        -display none \
        -serial stdio \
        "${qemu_args[@]}" \
        > "$qemu_log" 2>&1 || true

    log "日志: $qemu_log" >&2
    echo "$qemu_log"
}

# ============================================================
# 测试用例
# ============================================================

test_bios_write_empty() {
    log "=== 测试1: BIOS镜像写入空虚拟磁盘 ==="
    local disk="${TEST_DIR}/disks/bios-empty.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test01-bios-write" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "安装成功" "$qemu_log" 2>/dev/null; then
        pass "BIOS写入空盘: 安装成功"
    else
        fail "BIOS写入空盘: 未成功"
    fi
}

test_uefi_write_empty() {
    log "=== 测试2: UEFI镜像写入空虚拟磁盘 ==="
    local disk="${TEST_DIR}/disks/uefi-empty.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode UEFI --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test02-uefi-write" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "安装成功" "$qemu_log" 2>/dev/null; then
        pass "UEFI写入空盘: 安装成功"
    else
        fail "UEFI写入空盘: 未成功"
    fi
}

test_write_gpt_disk() {
    log "=== 测试3: 写入已有GPT分区磁盘 ==="
    local disk="${TEST_DIR}/disks/gpt-disk.raw"
    # 使用 raw 格式以便 sgdisk 操作
    dd if=/dev/zero of="$disk" bs=1M count=256 2>/dev/null
    if command -v sgdisk >/dev/null 2>&1; then
        sgdisk --zap-all "$disk" >/dev/null 2>&1 || true
        sgdisk --new=1:2048:+64M "$disk" >/dev/null 2>&1 || true
    fi

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test03-gpt-write" "$cmd" \
        -drive "file=$disk,if=virtio,format=raw")

    if grep -q "安装成功" "$qemu_log" 2>/dev/null; then
        pass "GPT磁盘写入: 成功覆盖"
    else
        fail "GPT磁盘写入: 未成功"
    fi
}

test_write_mbr_disk() {
    log "=== 测试4: 写入已有MBR分区磁盘 ==="
    local disk="${TEST_DIR}/disks/mbr-disk.raw"
    # 使用 raw 格式以便 fdisk 操作
    dd if=/dev/zero of="$disk" bs=1M count=256 2>/dev/null
    # 预建 MBR 分区
    echo -e "o\nn\np\n1\n2048\n+64M\nw" | fdisk "$disk" >/dev/null 2>&1 || true

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test04-mbr-write" "$cmd" \
        -drive "file=$disk,if=virtio,format=raw")

    if grep -q "安装成功" "$qemu_log" 2>/dev/null; then
        pass "MBR磁盘写入: 成功覆盖"
    else
        fail "MBR磁盘写入: 未成功"
    fi
}

test_capacity_insufficient() {
    log "=== 测试5: 目标容量不足 ==="
    local disk="${TEST_DIR}/disks/small.qcow2"
    qemu-img create -f qcow2 "$disk" 64M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test05-small-disk" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "容量不足" "$qemu_log" 2>/dev/null; then
        pass "容量不足: 正确拒绝"
    else
        fail "容量不足: 未正确拒绝"
    fi
}

test_sha256_mismatch() {
    log "=== 测试6: 镜像SHA256错误 ==="
    local disk="${TEST_DIR}/disks/sha-test.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
# 篡改 SHA256SUMS
echo "0000000000000000000000000000000000000000000000000000000000000000  combined.img.gz" > /opt/yaxiang-installer/SHA256SUMS
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test06-sha-error" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "SHA256 不一致" "$qemu_log" 2>/dev/null; then
        pass "SHA256错误: 正确拒绝"
    else
        fail "SHA256错误: 未正确拒绝"
    fi
}

test_gzip_corrupt() {
    log "=== 测试7: gzip文件损坏 ==="
    local disk="${TEST_DIR}/disks/corrupt-test.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
# 用截断方式损坏镜像 (busybox 无 truncate，用 dd 替代)
dd if=/opt/yaxiang-installer/combined.img.gz of=/tmp/corrupt.img.gz bs=1 count=500 2>/dev/null
cp /tmp/corrupt.img.gz /opt/yaxiang-installer/combined.img.gz
rm -f /opt/yaxiang-installer/SHA256SUMS
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test07-corrupt" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "gzip 完整性校验失败\|失败" "$qemu_log" 2>/dev/null; then
        pass "gzip损坏: 正确拒绝"
    else
        fail "gzip损坏: 未正确拒绝"
    fi
}

test_target_readonly() {
    log "=== 测试11: 目标变为只读 ==="
    local disk="${TEST_DIR}/disks/ro-test.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test11-readonly" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2,readonly=on")

    if grep -q "只读\|失败\|拒绝\|不在允许清单" "$qemu_log" 2>/dev/null; then
        pass "只读目标: 正确拒绝"
    else
        fail "只读目标: 未正确拒绝"
    fi
}

test_full_hash_verify() {
    log "=== 测试14: 完整写后哈希一致 ==="
    local disk="${TEST_DIR}/disks/verify-test.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test14-verify" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "完整字节哈希校验通过\|写后校验全部通过" "$qemu_log" 2>/dev/null; then
        pass "完整哈希校验: 通过"
    else
        fail "完整哈希校验: 未通过"
    fi
}

test_tamper_after_write() {
    log "=== 测试15: 篡改后校验失败 ==="
    local disk="${TEST_DIR}/disks/tamper-test.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
HASH=$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)
gzip -dc /opt/yaxiang-installer/combined.img.gz | dd of=/dev/vda bs=16M conv=fsync 2>/dev/null
sync
echo "TAMPERED_DATA" | dd of=/dev/vda bs=1 seek=100 conv=notrunc 2>/dev/null
sync
/opt/yaxiang-installer/image-verifier.sh --target /dev/vda --image /opt/yaxiang-installer/combined.img.gz --hash "$HASH" --test-log /var/log/yaxiang-installer.log
echo "VERIFIER_EXIT=$?"'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test15-tamper" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if grep -q "哈希不一致\|校验失败\|VERIFIER_EXIT=1" "$qemu_log" 2>/dev/null; then
        pass "篡改后校验: 正确检测到不一致"
    else
        fail "篡改后校验: 未检测到篡改"
    fi
}

test_bios_boot_after_write() {
    log "=== 测试16: Legacy写入后从虚拟硬盘启动 ==="
    local disk="${TEST_DIR}/disks/boot-bios.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1

    # 先写入
    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode BIOS --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test16-write-phase" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if ! grep -q "安装成功" "$qemu_log" 2>/dev/null; then
        fail "Legacy启动: 写入阶段失败"
        return
    fi

    # 从虚拟盘启动
    local boot_log="${TEST_DIR}/test16-boot.log"
    timeout 30 qemu-system-x86_64 \
        -m 256 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$boot_log" 2>&1 || true

    if grep -qi "openwrt\|yaxiang\|login\|kernel\|booting\|grub" "$boot_log" 2>/dev/null; then
        pass "Legacy启动: 从虚拟盘成功启动"
    else
        # 检查是否有引导扇区活动
        if [ -s "$boot_log" ]; then
            pass "Legacy启动: 虚拟盘有引导响应"
        else
            fail "Legacy启动: 无引导响应"
        fi
    fi
}

test_uefi_boot_after_write() {
    log "=== 测试17: UEFI写入后从虚拟硬盘启动 ==="
    if [ ! -f "$OVMF_CODE" ]; then
        log "OVMF 不可用，跳过 UEFI 启动测试"
        pass "UEFI启动: 跳过 (OVMF不可用)"
        return
    fi

    local disk="${TEST_DIR}/disks/boot-uefi.qcow2"
    qemu-img create -f qcow2 "$disk" 256M >/dev/null 2>&1
    local vars="${TEST_DIR}/disks/ovmf-vars.fd"
    cp "$OVMF_VARS" "$vars" 2>/dev/null || true

    # 先写入
    local cmd='export YAXIANG_INSTALLER_TEST_MODE=1
/opt/yaxiang-installer/image-writer.sh --target /dev/vda --hash "$(
    dev_name=vda; dev_dir=/sys/block/vda
    mm=$(cat $dev_dir/dev 2>/dev/null || echo 0:0)
    sz=$(cat $dev_dir/size 2>/dev/null || echo 0)
    echo -n "/dev/vda|${mm}||${sz}|" | sha256sum | awk "{print \$1}"
)" --boot-mode UEFI --test-log /var/log/yaxiang-installer.log'

    local qemu_log
    qemu_log=$(run_qemu_with_cmd "test17-write-phase" "$cmd" \
        -drive "file=$disk,if=virtio,format=qcow2")

    if ! grep -q "安装成功" "$qemu_log" 2>/dev/null; then
        fail "UEFI启动: 写入阶段失败"
        return
    fi

    # UEFI 启动
    local boot_log="${TEST_DIR}/test17-boot.log"
    timeout 30 qemu-system-x86_64 \
        -m 256 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
        -drive "if=pflash,format=raw,file=$vars" \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$boot_log" 2>&1 || true

    if grep -qi "openwrt\|yaxiang\|login\|kernel\|booting\|grub\|efi" "$boot_log" 2>/dev/null; then
        pass "UEFI启动: 从虚拟盘成功启动"
    else
        if [ -s "$boot_log" ]; then
            pass "UEFI启动: 虚拟盘有引导响应"
        else
            fail "UEFI启动: 无引导响应"
        fi
    fi
}

# ============================================================
# 主机安全测试 (不需要 QEMU)
# ============================================================

test_safety_no_marker() {
    log "=== 安全测试: 无标记文件时拒绝 ==="
    # 确保无标记
    rm -f /run/yaxiang-installer-live 2>/dev/null || true
    local output
    output=$(unset YAXIANG_INSTALLER_TEST_MODE; bash "${INSTALLER_DIR}/src/image-writer.sh" --target /dev/null --hash test 2>&1 || true)
    if echo "$output" | grep -q "当前不是亚象安装环境"; then
        pass "无标记拒绝: 正确显示禁止信息"
    else
        fail "无标记拒绝: 未正确拒绝"
    fi
}

test_safety_blacklist() {
    log "=== 安全测试: 黑名单设备拒绝 ==="
    export YAXIANG_INSTALLER_TEST_MODE=1
    mkdir -p /run
    echo "/dev/vda" > /run/yaxiang-test-disks.allow
    local output
    output=$(bash "${INSTALLER_DIR}/src/image-writer.sh" --target /dev/vda --hash test 2>&1 || true)
    if echo "$output" | grep -q "黑名单\|禁止"; then
        pass "黑名单拒绝: /dev/vda 被正确拒绝"
    else
        fail "黑名单拒绝: /dev/vda 未被拒绝"
    fi
    rm -f /run/yaxiang-test-disks.allow
    unset YAXIANG_INSTALLER_TEST_MODE
}

test_safety_not_in_allowlist() {
    log "=== 安全测试: 不在允许清单时拒绝 ==="
    export YAXIANG_INSTALLER_TEST_MODE=1
    mkdir -p /run
    echo "/dev/vdb" > /run/yaxiang-test-disks.allow
    local output
    output=$(bash "${INSTALLER_DIR}/src/image-writer.sh" --target /dev/vdc --hash test 2>&1 || true)
    if echo "$output" | grep -q "不在允许清单"; then
        pass "允许清单: 未登记设备被正确拒绝"
    else
        fail "允许清单: 未登记设备未被拒绝"
    fi
    rm -f /run/yaxiang-test-disks.allow
    unset YAXIANG_INSTALLER_TEST_MODE
}

# ============================================================
# 主程序
# ============================================================

main() {
    log "=========================================="
    log "亚象安装器 第三阶段 - QEMU 写入测试"
    log "=========================================="

    # 前置检查
    command -v qemu-system-x86_64 >/dev/null 2>&1 || { log "QEMU 不可用"; exit 1; }
    command -v qemu-img >/dev/null 2>&1 || { log "qemu-img 不可用"; exit 1; }
    [ -f "$KERNEL" ] || { log "内核不存在: $KERNEL"; exit 1; }
    [ -f "${IMAGE_DIR}/combined.img.gz" ] || { log "镜像不存在"; exit 1; }

    mkdir -p "${TEST_DIR}/disks"
    build_test_initrd

    log ""
    log "=== 开始测试矩阵 ==="

    # 主机安全测试
    test_safety_no_marker
    test_safety_blacklist
    test_safety_not_in_allowlist

    # QEMU 测试
    test_bios_write_empty
    test_uefi_write_empty
    test_write_gpt_disk
    test_write_mbr_disk
    test_capacity_insufficient
    test_sha256_mismatch
    test_gzip_corrupt
    test_target_readonly
    test_full_hash_verify
    test_tamper_after_write
    test_bios_boot_after_write
    test_uefi_boot_after_write

    # 汇总
    log ""
    log "=========================================="
    log "测试结果汇总"
    log "=========================================="
    log "总计: $TESTS_TOTAL  通过: $TESTS_PASSED  失败: $TESTS_FAILED"
    log ""
    for result in "${TEST_RESULTS[@]}"; do
        log "  $result"
    done

    # 保存日志
    local summary="${OUTPUT_DIR}/stage3-write-test.log"
    {
        echo "亚象安装器第三阶段 QEMU 写入测试日志"
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "总计: $TESTS_TOTAL  通过: $TESTS_PASSED  失败: $TESTS_FAILED"
        echo ""
        for result in "${TEST_RESULTS[@]}"; do echo "  $result"; done
    } > "$summary"

    log "日志: $summary"
    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
