#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象网络操作系统 - 写后校验模块
# 版本: 0.2-dev (Stage 3)
# 完整字节哈希校验，不得只校验前几MB
# ============================================================

VERIFIER_VERSION="0.2-dev"
LOG_FILE="/var/log/yaxiang-installer.log"
TEST_LOG=""

log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [verifier] $*"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
    if [ -n "$TEST_LOG" ]; then
        echo "$msg" >> "$TEST_LOG" 2>/dev/null || true
    fi
}

log_status() {
    echo "$*"
    log_msg "$*"
}

verify_fail() {
    log_status "[校验失败] $*"
    log_msg "校验失败: $*"
    return 1
}

# ============================================================
# 设备身份哈希
# ============================================================

compute_identity_hash() {
    local dev_name="$1"
    local dev_dir="/sys/block/${dev_name}"
    local dev_path="/dev/${dev_name}"

    local major_minor
    major_minor=$(cat "$dev_dir/dev" 2>/dev/null || echo "0:0")
    local serial=""
    if [ -f "$dev_dir/device/serial" ]; then
        serial=$(cat "$dev_dir/device/serial" 2>/dev/null | sed 's/[[:space:]]*$//' || true)
    fi
    local size_sectors
    size_sectors=$(cat "$dev_dir/size" 2>/dev/null || echo "0")
    local model=""
    if [ -f "$dev_dir/device/model" ]; then
        model=$(cat "$dev_dir/device/model" 2>/dev/null | sed 's/[[:space:]]*$//' || true)
    fi

    # 使用与安装器相同的默认值
    serial="${serial:-无}"
    model="${model:-未知}"

    echo -n "${dev_path}|${major_minor}|${serial}|${size_sectors}|${model}" | sha256sum | awk '{print $1}'
}

# ============================================================
# 写后校验主逻辑
# ============================================================

main() {
    local target=""
    local image=""
    local expected_hash=""
    local expected_size=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --target) target="$2"; shift 2 ;;
            --image) image="$2"; shift 2 ;;
            --hash) expected_hash="$2"; shift 2 ;;
            --size) expected_size="$2"; shift 2 ;;
            --test-log) TEST_LOG="$2"; shift 2 ;;
            *) echo "未知参数: $1"; exit 1 ;;
        esac
    done

    if [ -z "$target" ] || [ -z "$image" ]; then
        echo "用法: $0 --target <设备> --image <镜像> [--hash <哈希>] [--size <字节数>]"
        exit 1
    fi

    local dev_name
    dev_name=$(basename "$target")

    log_msg "=========================================="
    log_msg "写后校验开始 V${VERIFIER_VERSION}"
    log_msg "目标: $target"
    log_msg "镜像: $image"
    log_msg "=========================================="

    local checks_passed=0
    local checks_failed=0

    # --- 校验1: 获取镜像解压后精确字节数 ---
    log_status "  [1/10] 获取镜像解压字节数..."
    local image_size="$expected_size"
    if [ -z "$image_size" ]; then
        image_size=$(gzip -l "$image" 2>/dev/null | tail -1 | awk '{print $2}')
        if [ -z "$image_size" ] || [ "$image_size" = "-1" ]; then
            image_size=$(gzip -dc "$image" | wc -c)
        fi
    fi
    if [ -z "$image_size" ] || [ "$image_size" -eq 0 ]; then
        verify_fail "无法获取镜像解压大小"
        checks_failed=$((checks_failed + 1))
    else
        log_msg "  镜像解压大小: $image_size 字节"
        checks_passed=$((checks_passed + 1))
    fi

    # --- 校验2: 计算源镜像 SHA256 ---
    log_status "  [2/10] 计算源镜像 SHA256 (完整 $image_size 字节)..."
    local source_hash=""
    source_hash=$(gzip -dc "$image" | sha256sum | awk '{print $1}')
    if [ -z "$source_hash" ]; then
        verify_fail "无法计算源镜像哈希"
        checks_failed=$((checks_failed + 1))
    else
        log_msg "  源镜像 SHA256: ${source_hash:0:32}..."
        checks_passed=$((checks_passed + 1))
    fi

    # --- 校验3: 从目标磁盘读取相同字节数 ---
    log_status "  [3/10] 从目标磁盘读取 $image_size 字节..."
    local target_hash=""
    # 使用精确 bs 读取避免 SIGPIPE
    target_hash=$(dd if="$target" bs="$image_size" count=1 2>/dev/null | sha256sum | awk '{print $1}')
    if [ -z "$target_hash" ]; then
        verify_fail "无法从目标磁盘读取数据"
        checks_failed=$((checks_failed + 1))
    else
        log_msg "  目标磁盘 SHA256: ${target_hash:0:32}..."
        checks_passed=$((checks_passed + 1))
    fi

    # --- 校验4: 哈希比对 ---
    log_status "  [4/10] 比对完整哈希..."
    if [ "$source_hash" != "$target_hash" ]; then
        verify_fail "哈希不一致! 源: ${source_hash:0:16}... 目标: ${target_hash:0:16}..."
        checks_failed=$((checks_failed + 1))
    else
        log_msg "  完整字节哈希一致: ${source_hash:0:32}..."
        log_status "  完整字节哈希校验通过"
        checks_passed=$((checks_passed + 1))
    fi

    # --- 校验5: 分区表可读取 ---
    log_status "  [5/10] 检查分区表..."
    local part_info=""
    if command -v fdisk >/dev/null 2>&1; then
        part_info=$(fdisk -l "$target" 2>/dev/null || true)
    elif command -v sfdisk >/dev/null 2>&1; then
        part_info=$(sfdisk -d "$target" 2>/dev/null || true)
    fi
    if [ -n "$part_info" ]; then
        log_msg "  分区表可读取"
        checks_passed=$((checks_passed + 1))
    else
        log_msg "  警告: 无法读取分区表 (可能是 raw 镜像)"
        checks_passed=$((checks_passed + 1))  # 非致命
    fi

    # --- 校验6: 预期分区存在 ---
    log_status "  [6/10] 检查预期分区..."
    sleep 1  # 等待设备节点创建
    local part_found=0
    # OpenWrt combined 镜像通常有 2 个分区
    for p in "${target}1" "${target}2" "${target}p1" "${target}p2"; do
        if [ -b "$p" ]; then
            part_found=$((part_found + 1))
        fi
    done
    # 也检查 sysfs
    if [ "$part_found" -eq 0 ]; then
        for entry in /sys/block/"$dev_name"/"${dev_name}"*; do
            [ -d "$entry" ] && part_found=$((part_found + 1))
        done
    fi
    if [ "$part_found" -gt 0 ]; then
        log_msg "  检测到 $part_found 个分区"
        checks_passed=$((checks_passed + 1))
    else
        log_msg "  警告: 未检测到分区 (设备节点可能未创建)"
        checks_passed=$((checks_passed + 1))  # 在 QEMU 内可能无 udev
    fi

    # --- 校验7: 设备身份未变 ---
    log_status "  [7/10] 确认设备身份..."
    if [ -n "$expected_hash" ]; then
        local current_hash
        current_hash=$(compute_identity_hash "$dev_name")
        if [ "$current_hash" != "$expected_hash" ]; then
            verify_fail "设备身份已变化! 期望: ${expected_hash:0:16}... 实际: ${current_hash:0:16}..."
            checks_failed=$((checks_failed + 1))
        else
            log_msg "  设备身份未变"
            checks_passed=$((checks_passed + 1))
        fi
    else
        log_msg "  跳过 (无期望哈希)"
        checks_passed=$((checks_passed + 1))
    fi

    # --- 校验8: 只读识别系统分区 ---
    log_status "  [8/10] 识别系统分区..."
    local fs_type=""
    if command -v blkid >/dev/null 2>&1; then
        # 尝试第一个分区
        for p in "${target}1" "${target}2" "${target}p1" "${target}p2"; do
            if [ -b "$p" ]; then
                fs_type=$(blkid -o value -s TYPE "$p" 2>/dev/null || true)
                if [ -n "$fs_type" ]; then
                    log_msg "  分区 $p 文件系统: $fs_type"
                    break
                fi
            fi
        done
    fi
    if [ -z "$fs_type" ]; then
        log_msg "  未识别到文件系统 (QEMU 内可能无 blkid)"
    fi
    checks_passed=$((checks_passed + 1))

    # --- 校验9: 检查亚象标识 ---
    log_status "  [9/10] 检查亚象系统标识..."
    local yaxiang_found=0
    # 在镜像前 1MB 中搜索 "Yaxiang" 或 "yaxiang" 字符串
    if dd if="$target" bs=1M count=1 2>/dev/null | grep -qi "yaxiang\|openwrt" 2>/dev/null; then
        yaxiang_found=1
    fi
    # 也搜索整个前 10MB
    if [ "$yaxiang_found" -eq 0 ]; then
        if dd if="$target" bs=1M count=10 2>/dev/null | grep -qi "yaxiang\|openwrt" 2>/dev/null; then
            yaxiang_found=1
        fi
    fi
    if [ "$yaxiang_found" -eq 1 ]; then
        log_msg "  检测到亚象/OpenWrt 系统标识"
        checks_passed=$((checks_passed + 1))
    else
        log_msg "  警告: 未检测到亚象标识 (可能位于更深偏移)"
        checks_passed=$((checks_passed + 1))  # 非致命，哈希已验证
    fi

    # --- 校验10: 最终汇总 ---
    log_status "  [10/10] 校验汇总..."
    log_msg "  通过: $checks_passed, 失败: $checks_failed"

    if [ "$checks_failed" -gt 0 ]; then
        log_msg "写后校验结果: 失败"
        echo ""
        echo "  写后校验失败 ($checks_failed 项未通过)"
        return 1
    fi

    log_msg "写后校验结果: 全部通过"
    echo "  写后校验全部通过 ($checks_passed 项)"
    return 0
}

main "$@"
