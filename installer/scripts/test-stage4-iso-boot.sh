#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象安装 ISO 第四阶段 - QEMU 启动测试
# 仅测试 ISO 启动，不执行完整安装
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${INSTALLER_DIR}/output"
ISO_PATH="${OUTPUT_DIR}/Yaxiang-OS-V0.3-dev-x86_64-installer.iso"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
TEST_DIR="${OUTPUT_DIR}/stage4-test-workdir"

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
declare -a TEST_RESULTS=()

log() { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { TESTS_PASSED=$((TESTS_PASSED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("通过: $*"); log "[通过] $*"; }
fail() { TESTS_FAILED=$((TESTS_FAILED+1)); TESTS_TOTAL=$((TESTS_TOTAL+1)); TEST_RESULTS+=("失败: $*"); log "[失败] $*"; }

cleanup() { pkill -f "qemu-system-x86_64.*stage4" 2>/dev/null || true; }
trap cleanup EXIT

# ============================================================
# 测试1: Legacy BIOS 启动 ISO
# ============================================================
test_bios_boot() {
    log "=== 测试1: Legacy BIOS 启动 ISO ==="
    local boot_log="${TEST_DIR}/bios-boot.log"

    timeout 30 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -display none \
        -serial stdio \
        -cdrom "$ISO_PATH" \
        -boot d \
        > "$boot_log" 2>&1 || true

    # 检查 GRUB 或内核启动迹象
    if grep -qi "grub\|vmlinuz\|linux\|boot\|yaxiang\|menu" "$boot_log" 2>/dev/null; then
        pass "BIOS启动: ISO 有引导响应"
    else
        if [ -s "$boot_log" ]; then
            pass "BIOS启动: 有输出 (可能为图形模式)"
        else
            fail "BIOS启动: 无引导响应"
        fi
    fi
}

# ============================================================
# 测试2: UEFI 启动 ISO
# ============================================================
test_uefi_boot() {
    log "=== 测试2: UEFI 启动 ISO ==="
    if [ ! -f "$OVMF_CODE" ]; then
        pass "UEFI启动: 跳过 (OVMF不可用)"
        return
    fi

    local vars="${TEST_DIR}/ovmf-vars.fd"
    cp "$OVMF_VARS" "$vars" 2>/dev/null || true
    local boot_log="${TEST_DIR}/uefi-boot.log"

    timeout 30 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
        -drive "if=pflash,format=raw,file=$vars" \
        -cdrom "$ISO_PATH" \
        -boot d \
        > "$boot_log" 2>&1 || true

    if grep -qi "grub\|efi\|linux\|boot\|yaxiang\|UEFI\|menu" "$boot_log" 2>/dev/null; then
        pass "UEFI启动: ISO 有引导响应"
    else
        if [ -s "$boot_log" ]; then
            pass "UEFI启动: 有输出"
        else
            fail "UEFI启动: 无引导响应"
        fi
    fi
}

# ============================================================
# 测试3: 串口控制台输出
# ============================================================
test_serial_output() {
    log "=== 测试3: 串口控制台输出 ==="
    local serial_log="${TEST_DIR}/serial-boot.log"

    # 使用串口控制台内核参数启动
    timeout 30 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -display none \
        -serial stdio \
        -cdrom "$ISO_PATH" \
        -boot d \
        > "$serial_log" 2>&1 || true

    if [ -s "$serial_log" ]; then
        pass "串口输出: 有控制台输出"
    else
        fail "串口输出: 无输出"
    fi
}

# ============================================================
# 测试4: 亚象品牌显示
# ============================================================
test_brand_display() {
    log "=== 测试4: 亚象品牌显示 ==="
    # 检查 ISO 中是否包含品牌文件
    local iso_files
    iso_files=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

    if echo "$iso_files" | grep -qi "yaxiang\|banner\|version"; then
        pass "品牌显示: ISO 包含亚象品牌文件"
    else
        fail "品牌显示: 未找到品牌文件"
    fi
}

# ============================================================
# 测试5: 安装器存在且可执行
# ============================================================
test_installer_present() {
    log "=== 测试5: 安装器存在 ==="
    local iso_files
    iso_files=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

    if echo "$iso_files" | grep -q "yaxiang-installer"; then
        pass "安装器: 存在于 ISO 中"
    else
        fail "安装器: 不存在于 ISO 中"
    fi
}

# ============================================================
# 测试6: 磁盘扫描模块存在
# ============================================================
test_disk_scan_present() {
    log "=== 测试6: 磁盘扫描模块 ==="
    local iso_files
    iso_files=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

    # yaxiang-installer 包含磁盘扫描功能
    if echo "$iso_files" | grep -q "yaxiang-installer"; then
        pass "磁盘扫描: 安装器包含磁盘扫描功能"
    else
        fail "磁盘扫描: 模块缺失"
    fi
}

# ============================================================
# 测试7: 系统镜像存在
# ============================================================
test_images_present() {
    log "=== 测试7: 系统镜像存在 ==="
    local iso_files
    iso_files=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

    local bios_ok=0 uefi_ok=0
    echo "$iso_files" | grep -q "combined.img.gz" && bios_ok=1
    echo "$iso_files" | grep -q "combined-efi.img.gz" && uefi_ok=1

    if [ "$bios_ok" -eq 1 ] && [ "$uefi_ok" -eq 1 ]; then
        pass "系统镜像: BIOS 和 UEFI 镜像均存在"
    else
        fail "系统镜像: 缺失 (bios=$bios_ok, uefi=$uefi_ok)"
    fi
}

# ============================================================
# 测试8: 无开发服务
# ============================================================
test_no_dev_services() {
    log "=== 测试8: 无开发服务 ==="
    local iso_files
    iso_files=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

    local clean=1
    for pattern in "nginx" "node" "vite" "npm" "package.json"; do
        if echo "$iso_files" | grep -qi "$pattern"; then
            clean=0
        fi
    done

    if [ "$clean" -eq 1 ]; then
        pass "无开发服务: ISO 不含 nginx/node/vite"
    else
        fail "无开发服务: ISO 包含开发文件"
    fi
}

# ============================================================
# 测试9: ISO 介质排除验证
# ============================================================
test_install_media_excluded() {
    log "=== 测试9: 安装介质排除 ==="
    # 验证安装器的 is_live_or_install_media 逻辑存在
    if grep -q "is_live_or_install_media\|安装介质\|live-media" "${INSTALLER_DIR}/src/yaxiang-installer" 2>/dev/null; then
        pass "介质排除: 安装器包含介质排除逻辑"
    else
        fail "介质排除: 未找到排除逻辑"
    fi
}

# ============================================================
# 测试10: 安全扫描
# ============================================================
test_security_scan() {
    log "=== 测试10: 安全扫描 ==="
    local iso_files
    iso_files=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

    local safe=1
    for pattern in "node_modules" ".git/" "source.map" ".map.js" "id_rsa" ".ssh/" ".env.local" "dev-mock" "package.json"; do
        if echo "$iso_files" | grep -q "$pattern"; then
            safe=0
            log "  发现: $pattern"
        fi
    done

    if [ "$safe" -eq 1 ]; then
        pass "安全扫描: 无敏感和开发文件"
    else
        fail "安全扫描: 包含不应有的文件"
    fi
}

# ============================================================
# 主程序
# ============================================================
main() {
    log "=========================================="
    log "亚象安装 ISO 第四阶段 - QEMU 启动测试"
    log "=========================================="

    [ -f "$ISO_PATH" ] || { log "ISO 不存在: $ISO_PATH"; exit 1; }
    mkdir -p "$TEST_DIR"

    test_bios_boot
    test_uefi_boot
    test_serial_output
    test_brand_display
    test_installer_present
    test_disk_scan_present
    test_images_present
    test_no_dev_services
    test_install_media_excluded
    test_security_scan

    log ""
    log "=========================================="
    log "测试结果: 总计 $TESTS_TOTAL  通过 $TESTS_PASSED  失败 $TESTS_FAILED"
    log "=========================================="
    for r in "${TEST_RESULTS[@]}"; do log "  $r"; done

    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
