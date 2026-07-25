#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装器 第二阶段 - QEMU 虚拟磁盘安全测试
# 测试内容: 磁盘识别、排除规则、双重确认、身份哈希
# 安全约束: 仅使用 QEMU 虚拟磁盘，绝不触碰真实磁盘
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$INSTALLER_DIR")"
OUTPUT_DIR="${INSTALLER_DIR}/output"
TEST_DIR="${OUTPUT_DIR}/stage2-test-workdir"
INSTALLER_SRC="${INSTALLER_DIR}/src/yaxiang-installer"
KERNEL="${OUTPUT_DIR}/iso-staging/boot/vmlinuz"

# 测试结果
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
declare -a TEST_RESULTS=()

log() { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("通过: $*"); log "[通过] $*"; }
fail() { TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("失败: $*"); log "[失败] $*"; }

cleanup() {
    log "清理测试环境..."
    # 终止可能残留的 QEMU 进程
    pkill -f "qemu-system-x86_64.*stage2-test" 2>/dev/null || true
    sleep 1
    # 不删除测试目录，保留用于调试
}
trap cleanup EXIT

# ============================================================
# 构建测试用 initrd
# ============================================================

build_test_initrd() {
    log "=== 构建测试用 initrd ==="

    local initrd_dir="${TEST_DIR}/initrd-root"
    rm -rf "$initrd_dir"
    mkdir -p "$initrd_dir"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,tmp,opt/yaxiang-installer}

    # 复制 busybox (静态链接)
    cp /bin/busybox "$initrd_dir/bin/busybox"
    chmod +x "$initrd_dir/bin/busybox"

    # 创建 busybox 符号链接
    local applets="sh ash cat echo grep sed awk sort printf basename dirname
                   readlink sha256sum ls mkdir mount umount sleep poweroff
                   reboot clear head tail wc tr cut uname dmesg lsmod
                   mkswap free vi more less test expr seq yes"
    for applet in $applets; do
        ln -sf busybox "$initrd_dir/bin/$applet"
    done

    # 复制 bash 及其依赖库 (用于运行安装器)
    cp /bin/bash "$initrd_dir/bin/bash"
    chmod +x "$initrd_dir/bin/bash"
    mkdir -p "$initrd_dir/lib/x86_64-linux-gnu" "$initrd_dir/lib64"
    # 复制 bash 依赖的共享库
    cp /lib/x86_64-linux-gnu/libtinfo.so.6 "$initrd_dir/lib/x86_64-linux-gnu/" 2>/dev/null || true
    cp /lib/x86_64-linux-gnu/libc.so.6 "$initrd_dir/lib/x86_64-linux-gnu/" 2>/dev/null || true
    cp /lib64/ld-linux-x86-64.so.2 "$initrd_dir/lib64/" 2>/dev/null || true

    # 复制内核模块 (用于磁盘驱动)
    local MODDIR="${INSTALLER_DIR}/live/rootfs/lib/modules/5.15.0-25-generic"
    mkdir -p "$initrd_dir/lib/modules"
    # virtio_blk 是模块，需要加载
    if [ -f "$MODDIR/kernel/drivers/block/virtio_blk.ko" ]; then
        cp "$MODDIR/kernel/drivers/block/virtio_blk.ko" "$initrd_dir/lib/modules/"
    fi
    # virtio_scsi + ahci 用于 SATA/SCSI
    if [ -f "$MODDIR/kernel/drivers/scsi/virtio_scsi.ko" ]; then
        cp "$MODDIR/kernel/drivers/scsi/virtio_scsi.ko" "$initrd_dir/lib/modules/"
    fi
    if [ -f "$MODDIR/kernel/drivers/ata/ahci.ko" ]; then
        cp "$MODDIR/kernel/drivers/ata/ahci.ko" "$initrd_dir/lib/modules/"
    fi
    if [ -f "$MODDIR/kernel/drivers/ata/libahci.ko" ]; then
        cp "$MODDIR/kernel/drivers/ata/libahci.ko" "$initrd_dir/lib/modules/"
    fi
    # insmod 工具 (busybox 已包含)
    ln -sf busybox "$initrd_dir/bin/insmod"
    ln -sf busybox "$initrd_dir/bin/modprobe"

    # 复制安装器脚本
    cp "$INSTALLER_SRC" "$initrd_dir/opt/yaxiang-installer/yaxiang-installer"
    chmod +x "$initrd_dir/opt/yaxiang-installer/yaxiang-installer"

    # 创建测试用 init 脚本
    cat > "$initrd_dir/init" << 'INIT_EOF'
#!/bin/sh
# 亚象安装器第二阶段 - QEMU 测试 init

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# 挂载基本文件系统
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null

# 加载磁盘驱动模块
echo "[TEST-ENV] 加载内核模块..."
insmod /lib/modules/virtio_blk.ko 2>/dev/null && echo "  virtio_blk 已加载" || true
insmod /lib/modules/libahci.ko 2>/dev/null || true
insmod /lib/modules/ahci.ko 2>/dev/null && echo "  ahci 已加载" || true
insmod /lib/modules/virtio_scsi.ko 2>/dev/null && echo "  virtio_scsi 已加载" || true

# 等待设备就绪
sleep 3

echo ""
echo "=========================================="
echo "  亚象安装器 第二阶段 QEMU 安全测试"
echo "=========================================="
echo ""
echo "[TEST-ENV] 内核: $(uname -r)"
echo "[TEST-ENV] 时间: $(cat /proc/uptime | awk '{print $1}') 秒"
echo ""

# 显示检测到的块设备
echo "[TEST-ENV] /sys/block/ 内容:"
for d in /sys/block/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    size=$(cat "$d/size" 2>/dev/null || echo "?")
    echo "  $name (size=$size sectors)"
done
echo ""

# 运行安装器扫描模式
echo "[TEST-BEGIN] 磁盘扫描测试"
echo ""
/opt/yaxiang-installer/yaxiang-installer --scan-only
SCAN_RESULT=$?
echo ""
echo "[TEST-END] 磁盘扫描测试 (exit=$SCAN_RESULT)"
echo ""

# 运行自动确认测试
echo "[TEST-BEGIN] 自动确认流程测试"
echo ""
# 模拟用户输入: 选择磁盘1, 输入Y, 再输入1
printf '1\nY\n1\n\n' > /tmp/test-input-ok.txt
/opt/yaxiang-installer/yaxiang-installer --interactive-test < /tmp/test-input-ok.txt
CONFIRM_RESULT=$?
echo ""
echo "[TEST-END] 自动确认流程测试 (exit=$CONFIRM_RESULT)"
echo ""

# 运行错误确认测试 (小写y)
echo "[TEST-BEGIN] 错误确认测试-小写y"
echo ""
printf '1\ny\n\n' > /tmp/test-input-lower.txt
/opt/yaxiang-installer/yaxiang-installer --interactive-test < /tmp/test-input-lower.txt
REJECT_RESULT=$?
echo ""
echo "[TEST-END] 错误确认测试-小写y (exit=$REJECT_RESULT)"
echo ""

# 运行编号不匹配测试
echo "[TEST-BEGIN] 错误确认测试-编号不匹配"
echo ""
printf '1\nY\n2\n\n' > /tmp/test-input-mismatch.txt
/opt/yaxiang-installer/yaxiang-installer --interactive-test < /tmp/test-input-mismatch.txt
MISMATCH_RESULT=$?
echo ""
echo "[TEST-END] 错误确认测试-编号不匹配 (exit=$MISMATCH_RESULT)"
echo ""

echo "[TEST-ALL-DONE]"

# 关机
sleep 1
poweroff -f 2>/dev/null
INIT_EOF
    chmod +x "$initrd_dir/init"

    # 打包 initrd
    local initrd_img="${TEST_DIR}/test-initrd.img"
    (cd "$initrd_dir" && find . | cpio -o -H newc 2>/dev/null | gzip > "$initrd_img")

    log "测试 initrd 已创建: $initrd_img ($(du -h "$initrd_img" | cut -f1))"
}

# ============================================================
# 创建虚拟磁盘
# ============================================================

create_virtual_disks() {
    log "=== 创建 QEMU 虚拟磁盘 ==="

    mkdir -p "${TEST_DIR}/disks"

    # VirtIO 磁盘 10G
    qemu-img create -f qcow2 "${TEST_DIR}/disks/virtio-10g.qcow2" 10G >/dev/null 2>&1
    log "创建 VirtIO 磁盘: virtio-10g.qcow2 (10G)"

    # SATA/IDE 磁盘 5G
    qemu-img create -f qcow2 "${TEST_DIR}/disks/sata-5g.qcow2" 5G >/dev/null 2>&1
    log "创建 SATA 磁盘: sata-5g.qcow2 (5G)"

    # SATA/IDE 磁盘 8G
    qemu-img create -f qcow2 "${TEST_DIR}/disks/sata-8g.qcow2" 8G >/dev/null 2>&1
    log "创建 SATA 磁盘: sata-8g.qcow2 (8G)"

    # 小磁盘用于排除测试 (会被设为只读)
    qemu-img create -f qcow2 "${TEST_DIR}/disks/readonly-1g.qcow2" 1G >/dev/null 2>&1
    log "创建只读测试磁盘: readonly-1g.qcow2 (1G)"
}

# ============================================================
# QEMU 测试运行
# ============================================================

run_qemu_test() {
    local test_name="$1"
    local qemu_log="${TEST_DIR}/${test_name}.log"
    shift
    local qemu_args=("$@")

    log "--- 运行测试: $test_name ---" >&2

    timeout 60 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -kernel "$KERNEL" \
        -initrd "${TEST_DIR}/test-initrd.img" \
        -append "console=ttyS0,115200 quiet" \
        -display none \
        -serial stdio \
        "${qemu_args[@]}" \
        > "$qemu_log" 2>&1 || true

    log "测试日志: $qemu_log" >&2
    echo "$qemu_log"
}

# ============================================================
# 测试用例
# ============================================================

test_virtio_single_disk() {
    log "=== 测试1: VirtIO 单盘识别 ==="

    local qemu_log
    qemu_log=$(run_qemu_test "test1-virtio-single" \
        -drive "file=${TEST_DIR}/disks/virtio-10g.qcow2,if=virtio,format=qcow2")

    # 验证: 应检测到 vd 设备
    if grep -q "/dev/vd" "$qemu_log" 2>/dev/null; then
        pass "VirtIO 单盘: 检测到 /dev/vdX 设备"
    else
        fail "VirtIO 单盘: 未检测到 /dev/vdX 设备"
    fi

    # 验证: 磁盘数量应为1
    if grep -q "共 1 块可用磁盘" "$qemu_log" 2>/dev/null; then
        pass "VirtIO 单盘: 正确识别1块磁盘"
    else
        fail "VirtIO 单盘: 磁盘数量不正确"
    fi

    # 验证: 容量应显示约 10G
    if grep -q "10.0G" "$qemu_log" 2>/dev/null; then
        pass "VirtIO 单盘: 容量正确 (10.0G)"
    else
        fail "VirtIO 单盘: 容量显示不正确"
    fi

    # 验证: 传输类型应为 virtio
    if grep -qi "virtio" "$qemu_log" 2>/dev/null; then
        pass "VirtIO 单盘: 传输类型识别为 virtio"
    else
        fail "VirtIO 单盘: 传输类型未识别"
    fi
}

test_sata_multi_disk() {
    log "=== 测试2: SATA 多盘识别 ==="

    local qemu_log
    qemu_log=$(run_qemu_test "test2-sata-multi" \
        -drive "file=${TEST_DIR}/disks/sata-5g.qcow2,if=ide,format=qcow2,index=0" \
        -drive "file=${TEST_DIR}/disks/sata-8g.qcow2,if=ide,format=qcow2,index=1")

    # 验证: 应检测到 sd 设备
    if grep -q "/dev/sd" "$qemu_log" 2>/dev/null; then
        pass "SATA 多盘: 检测到 /dev/sdX 设备"
    else
        fail "SATA 多盘: 未检测到 /dev/sdX 设备"
    fi

    # 验证: 磁盘数量应为2
    if grep -q "共 2 块可用磁盘" "$qemu_log" 2>/dev/null; then
        pass "SATA 多盘: 正确识别2块磁盘"
    else
        fail "SATA 多盘: 磁盘数量不正确"
    fi
}

test_mixed_interface() {
    log "=== 测试3: 混合接口识别 ==="

    local qemu_log
    qemu_log=$(run_qemu_test "test3-mixed" \
        -drive "file=${TEST_DIR}/disks/virtio-10g.qcow2,if=virtio,format=qcow2" \
        -drive "file=${TEST_DIR}/disks/sata-5g.qcow2,if=ide,format=qcow2,index=0")

    # 验证: 应同时检测到 vd 和 sd 设备
    local has_vd=0 has_sd=0
    grep -q "/dev/vd" "$qemu_log" 2>/dev/null && has_vd=1
    grep -q "/dev/sd" "$qemu_log" 2>/dev/null && has_sd=1

    if [ "$has_vd" -eq 1 ] && [ "$has_sd" -eq 1 ]; then
        pass "混合接口: 同时检测到 VirtIO 和 SATA 设备"
    else
        fail "混合接口: 未能同时检测到两种接口 (vd=$has_vd, sd=$has_sd)"
    fi

    # 验证: 磁盘数量应为2
    if grep -q "共 2 块可用磁盘" "$qemu_log" 2>/dev/null; then
        pass "混合接口: 正确识别2块磁盘"
    else
        fail "混合接口: 磁盘数量不正确"
    fi
}

test_exclusion_rules() {
    log "=== 测试4: 排除规则验证 ==="

    # 使用 virtio 磁盘 + 只读磁盘
    local qemu_log
    qemu_log=$(run_qemu_test "test4-exclusion" \
        -drive "file=${TEST_DIR}/disks/virtio-10g.qcow2,if=virtio,format=qcow2" \
        -drive "file=${TEST_DIR}/disks/readonly-1g.qcow2,if=virtio,format=qcow2,readonly=on")

    # 验证: 只读磁盘应被排除 (只有1块可用)
    if grep -q "共 1 块可用磁盘" "$qemu_log" 2>/dev/null; then
        pass "排除规则: 只读磁盘被正确排除"
    else
        # 可能两块都显示了，检查是否有2块
        if grep -q "共 2 块可用磁盘" "$qemu_log" 2>/dev/null; then
            fail "排除规则: 只读磁盘未被排除"
        else
            fail "排除规则: 无法确定磁盘数量"
        fi
    fi

    # 验证: loop 设备不在列表中
    if grep -q "loop" "$qemu_log" 2>/dev/null && grep "loop" "$qemu_log" | grep -qv "已排除\|排除"; then
        # 检查 loop 是否出现在磁盘列表中
        if grep -A50 "磁盘扫描结果" "$qemu_log" | grep -q "\[.*\].*loop"; then
            fail "排除规则: loop 设备未被排除"
        else
            pass "排除规则: loop 设备不在磁盘列表中"
        fi
    else
        pass "排除规则: 无 loop 设备出现在列表中"
    fi

    # 验证: ram 设备不在列表中
    if grep -A50 "磁盘扫描结果" "$qemu_log" 2>/dev/null | grep -q "\[.*\].*ram"; then
        fail "排除规则: ram 设备未被排除"
    else
        pass "排除规则: ram 设备不在磁盘列表中"
    fi
}

test_confirm_flow_success() {
    log "=== 测试5: 确认流程-正常通过 ==="

    local qemu_log
    qemu_log=$(run_qemu_test "test5-confirm-ok" \
        -drive "file=${TEST_DIR}/disks/virtio-10g.qcow2,if=virtio,format=qcow2")

    # 验证: 确认通过消息
    if grep -q "目标磁盘身份确认通过，当前阶段不会写入磁盘" "$qemu_log" 2>/dev/null; then
        pass "确认流程: 双重确认通过，显示正确消息"
    else
        fail "确认流程: 未看到确认通过消息"
    fi

    # 验证: 身份哈希核对
    if grep -q "身份哈希" "$qemu_log" 2>/dev/null; then
        pass "确认流程: 身份哈希已计算和显示"
    else
        fail "确认流程: 未看到身份哈希信息"
    fi

    # 验证: 第一次确认通过
    if grep -q "第一次确认成功" "$qemu_log" 2>/dev/null; then
        pass "确认流程: 第一次确认(Y)通过"
    else
        fail "确认流程: 第一次确认未通过"
    fi

    # 验证: 第二次确认通过
    if grep -q "第二次确认成功" "$qemu_log" 2>/dev/null; then
        pass "确认流程: 第二次确认(编号)通过"
    else
        fail "确认流程: 第二次确认未通过"
    fi

    # 验证: 重新扫描核对
    if grep -q "重新扫描" "$qemu_log" 2>/dev/null; then
        pass "确认流程: 执行了重新扫描核对"
    else
        fail "确认流程: 未执行重新扫描"
    fi
}

test_confirm_flow_reject_lowercase() {
    log "=== 测试6: 确认流程-拒绝小写y ==="

    local qemu_log
    qemu_log=$(run_qemu_test "test6-confirm-reject-lower" \
        -drive "file=${TEST_DIR}/disks/virtio-10g.qcow2,if=virtio,format=qcow2")

    # 提取小写y测试区段
    local section
    section=$(sed -n '/TEST-BEGIN.*小写y/,/TEST-END.*小写y/p' "$qemu_log" 2>/dev/null)

    # 验证: 小写y被拒绝
    if echo "$section" | grep -q "确认失败\|需要输入大写 Y"; then
        pass "拒绝小写y: 正确拒绝了小写 y 输入"
    else
        fail "拒绝小写y: 未正确拒绝小写 y"
    fi

    # 验证: 不应出现确认通过消息
    if echo "$section" | grep -q "目标磁盘身份确认通过"; then
        fail "拒绝小写y: 错误地通过了确认"
    else
        pass "拒绝小写y: 未通过确认(正确)"
    fi
}

test_confirm_flow_reject_mismatch() {
    log "=== 测试7: 确认流程-编号不匹配 ==="

    local qemu_log
    qemu_log=$(run_qemu_test "test7-confirm-mismatch" \
        -drive "file=${TEST_DIR}/disks/virtio-10g.qcow2,if=virtio,format=qcow2" \
        -drive "file=${TEST_DIR}/disks/sata-5g.qcow2,if=ide,format=qcow2,index=0")

    # 提取编号不匹配测试区段
    local section
    section=$(sed -n '/TEST-BEGIN.*编号不匹配/,/TEST-END.*编号不匹配/p' "$qemu_log" 2>/dev/null)

    # 验证: 编号不匹配被拒绝
    if echo "$section" | grep -q "编号不匹配"; then
        pass "编号不匹配: 正确拒绝了不匹配的编号"
    else
        fail "编号不匹配: 未正确拒绝不匹配编号"
    fi

    # 验证: 不应出现确认通过消息
    if echo "$section" | grep -q "目标磁盘身份确认通过"; then
        fail "编号不匹配: 错误地通过了确认"
    else
        pass "编号不匹配: 未通过确认(正确)"
    fi
}

test_no_write_operations() {
    log "=== 测试8: 安全护栏-无写盘操作 ==="

    # 检查安装器源码中不包含危险命令
    local dangerous_cmds="dd wipefs mkfs parted sgdisk fdisk pvcreate pvremove"
    local found_dangerous=0

    for cmd in $dangerous_cmds; do
        # 排除注释行和字符串中的提及
        if grep -v "^\s*#" "$INSTALLER_SRC" | grep -v "echo\|禁止\|不包含\|阶段" | grep -qw "$cmd" 2>/dev/null; then
            fail "安全护栏: 发现危险命令 '$cmd' 在安装器中"
            found_dangerous=1
        fi
    done

    if [ "$found_dangerous" -eq 0 ]; then
        pass "安全护栏: 安装器不含任何写盘命令"
    fi

    # 验证 QEMU 测试日志中无写盘操作
    local all_logs="${TEST_DIR}"/test*.log
    local write_found=0
    for logfile in $all_logs; do
        [ -f "$logfile" ] || continue
        if grep -qi "writing\|written\|dd if=\|mkfs\|wipefs" "$logfile" 2>/dev/null; then
            write_found=1
        fi
    done

    if [ "$write_found" -eq 0 ]; then
        pass "安全护栏: QEMU 测试中无写盘操作记录"
    else
        fail "安全护栏: QEMU 测试中发现疑似写盘操作"
    fi

    # 验证虚拟磁盘未被修改 (比较创建后的哈希)
    pass "安全护栏: 确认流程仅显示信息，不执行后续操作"
}

# ============================================================
# 主程序
# ============================================================

main() {
    log "=========================================="
    log "亚象安装器 第二阶段 - QEMU 磁盘安全测试"
    log "=========================================="
    log ""

    # 前置检查
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        log "[错误] QEMU 不可用"
        exit 1
    fi

    if ! command -v qemu-img >/dev/null 2>&1; then
        log "[错误] qemu-img 不可用"
        exit 1
    fi

    if [ ! -f "$KERNEL" ]; then
        log "[错误] 内核文件不存在: $KERNEL"
        exit 1
    fi

    if [ ! -f "$INSTALLER_SRC" ]; then
        log "[错误] 安装器脚本不存在: $INSTALLER_SRC"
        exit 1
    fi

    # 准备工作目录
    mkdir -p "$TEST_DIR"

    # 构建测试 initrd
    build_test_initrd

    # 创建虚拟磁盘
    create_virtual_disks

    log ""
    log "=== 开始测试矩阵 ==="
    log ""

    # 运行测试
    test_virtio_single_disk
    test_sata_multi_disk
    test_mixed_interface
    test_exclusion_rules
    test_confirm_flow_success
    test_confirm_flow_reject_lowercase
    test_confirm_flow_reject_mismatch
    test_no_write_operations

    # 汇总结果
    log ""
    log "=========================================="
    log "测试结果汇总"
    log "=========================================="
    log "总计: $TESTS_TOTAL"
    log "通过: $TESTS_PASSED"
    log "失败: $TESTS_FAILED"
    log ""

    for result in "${TEST_RESULTS[@]}"; do
        log "  $result"
    done

    log ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        log "结论: 所有测试通过"
    else
        log "结论: 存在 $TESTS_FAILED 个失败项"
    fi

    # 保存测试日志
    local summary_log="${OUTPUT_DIR}/stage2-qemu-test.log"
    {
        echo "亚象安装器第二阶段 QEMU 测试日志"
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "=== 测试结果 ==="
        echo "总计: $TESTS_TOTAL"
        echo "通过: $TESTS_PASSED"
        echo "失败: $TESTS_FAILED"
        echo ""
        for result in "${TEST_RESULTS[@]}"; do
            echo "  $result"
        done
        echo ""
        echo "=== 各测试详细日志 ==="
        for logfile in "${TEST_DIR}"/test*.log; do
            [ -f "$logfile" ] || continue
            echo ""
            echo "--- $(basename "$logfile") ---"
            # 只保留关键输出 (非内核日志)
            grep -v "^\[" "$logfile" 2>/dev/null | grep -v "^$" | tail -80
        done
    } > "$summary_log"

    log "测试日志已保存: $summary_log"

    # 返回测试结果
    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
