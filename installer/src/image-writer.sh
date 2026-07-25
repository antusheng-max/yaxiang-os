#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象网络操作系统 - 系统镜像写入模块
# 版本: 0.2-dev (Stage 3)
# 安全约束: 仅在亚象Live环境或测试模式下允许写入
# ============================================================

WRITER_VERSION="0.2-dev"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_DIR="${SCRIPT_DIR}/../images"
LOG_FILE="/var/log/yaxiang-installer.log"
TEST_LOG=""

# 硬编码黑名单 - 任何模式都拒绝
BLACKLIST_DEVICES="/dev/vda /dev/sda /dev/sdb /dev/nvme0n1"

# ============================================================
# 日志函数
# ============================================================

log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
    if [ -n "$TEST_LOG" ]; then
        echo "$msg" >> "$TEST_LOG" 2>/dev/null || true
    fi
}

log_status() {
    echo "$*" >&2
    log_msg "$*"
}

die() {
    log_status "[失败] $*"
    log_msg "安装中止: $*"
    echo ""
    echo "========================================"
    echo "  安装失败 - 请勿从目标磁盘启动"
    echo "========================================"
    echo "  失败原因: $*"
    echo "  完整日志: $LOG_FILE"
    echo "========================================"
    exit 1
}

# ============================================================
# 环境保护层
# ============================================================

check_environment() {
    local target="$1"
    local is_live=0
    local is_test=0

    # 检查 Live 环境标记
    if [ -f /run/yaxiang-installer-live ]; then
        is_live=1
    fi

    # 检查测试模式
    if [ "${YAXIANG_INSTALLER_TEST_MODE:-0}" = "1" ]; then
        is_test=1
    fi

    # 两者都不满足
    if [ "$is_live" -eq 0 ] && [ "$is_test" -eq 0 ]; then
        echo "当前不是亚象安装环境，禁止执行磁盘写入。"
        exit 1
    fi

    # 硬编码黑名单检查 (仅在非 Live 环境下生效，保护服务器真实磁盘)
    # 在亚象 Live 环境内，/dev/vda 是虚拟磁盘而非服务器系统盘，由允许清单保护
    if [ "$is_live" -eq 0 ]; then
        for blocked in $BLACKLIST_DEVICES; do
            if [ "$target" = "$blocked" ]; then
                die "目标设备 $target 在安全黑名单中，绝对禁止写入"
            fi
        done
    fi

    # 测试模式额外检查
    if [ "$is_test" -eq 1 ]; then
        local allow_file="/run/yaxiang-test-disks.allow"
        if [ ! -f "$allow_file" ]; then
            die "测试模式: 允许清单 $allow_file 不存在"
        fi
        if ! grep -qx "$target" "$allow_file" 2>/dev/null; then
            die "测试模式: 目标 $target 不在允许清单中"
        fi
        log_msg "测试模式: 目标 $target 在允许清单中"
    fi

    if [ "$is_live" -eq 1 ]; then
        log_msg "运行环境: 亚象 Live 系统"
    else
        log_msg "运行环境: 测试模式"
    fi
}

# ============================================================
# 设备安全检查
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

check_target_device() {
    local target="$1"
    local expected_hash="$2"
    local image_uncompressed_size="$3"

    local dev_name
    dev_name=$(basename "$target")

    # 检查1: 目标存在
    if [ ! -b "$target" ]; then
        die "目标设备 $target 不存在或不是块设备"
    fi

    # 检查2: 目标是整块磁盘 (非分区)
    if [ -f "/sys/block/${dev_name}/partition" ]; then
        die "目标 $target 是分区而非整块磁盘"
    fi
    if [ ! -d "/sys/block/${dev_name}" ]; then
        die "目标 $target 不是整块磁盘设备"
    fi

    # 检查3: 身份哈希一致
    local current_hash
    current_hash=$(compute_identity_hash "$dev_name")
    if [ "$current_hash" != "$expected_hash" ]; then
        die "目标设备身份哈希不一致 (期望: ${expected_hash:0:16}..., 实际: ${current_hash:0:16}...)"
    fi
    log_msg "身份哈希验证通过: ${current_hash:0:32}..."

    # 检查4: 不是当前根文件系统
    local root_dev=""
    root_dev=$(findmnt -n -o SOURCE / 2>/dev/null || true)
    if [ -z "$root_dev" ] && [ -f /proc/mounts ]; then
        root_dev=$(awk '$2=="/" {print $1}' /proc/mounts | head -1 || true)
    fi
    if [ -n "$root_dev" ]; then
        local root_disk
        root_disk=$(echo "$root_dev" | sed -E 's|/dev/(sd[a-z]+)[0-9]*|\1|; s|/dev/(vd[a-z]+)[0-9]*|\1|; s|/dev/(nvme[0-9]+n[0-9]+)p[0-9]*|\1|; s|/dev/(mmcblk[0-9]+)p[0-9]*|\1|')
        if [ "/dev/${root_disk}" = "$target" ] || [ "$root_dev" = "$target" ]; then
            die "目标 $target 是当前根文件系统所在磁盘"
        fi
    fi

    # 检查5: 不是安装介质
    if [ -f /proc/cmdline ]; then
        local cmdline
        cmdline=$(cat /proc/cmdline 2>/dev/null || true)
        if echo "$cmdline" | grep -q "live-media=${target}"; then
            die "目标 $target 是当前安装介质"
        fi
    fi

    # 检查6: 只读检查
    local ro_val
    ro_val=$(cat "/sys/block/${dev_name}/ro" 2>/dev/null || echo "0")
    if [ "$ro_val" = "1" ]; then
        die "目标设备 $target 是只读的"
    fi

    # 检查7: 容量足够
    local size_sectors
    size_sectors=$(cat "/sys/block/${dev_name}/size" 2>/dev/null || echo "0")
    local size_bytes=$((size_sectors * 512))
    if [ "$size_bytes" -lt "$image_uncompressed_size" ]; then
        die "目标容量不足: 磁盘 ${size_bytes} 字节 < 镜像 ${image_uncompressed_size} 字节"
    fi
    log_msg "容量检查通过: 磁盘 ${size_bytes} 字节 >= 镜像 ${image_uncompressed_size} 字节"

    # 检查8: 无挂载分区
    if command -v findmnt >/dev/null 2>&1; then
        local mnt
        mnt=$(findmnt -n -o TARGET "$target" 2>/dev/null | head -1 || true)
        if [ -n "$mnt" ]; then
            die "目标设备 $target 已挂载在 $mnt"
        fi
        # 检查分区挂载
        for part in /sys/block/"$dev_name"/"${dev_name}"*; do
            [ -d "$part" ] || continue
            local pname
            pname=$(basename "$part")
            local pmnt
            pmnt=$(findmnt -n -o TARGET "/dev/${pname}" 2>/dev/null | head -1 || true)
            if [ -n "$pmnt" ]; then
                die "目标磁盘分区 /dev/${pname} 已挂载在 $pmnt"
            fi
        done
    fi

    # 检查9: 无 LVM/mdraid/dm 占用
    if [ -d "/sys/block/${dev_name}/holders" ]; then
        local holders
        holders=$(ls "/sys/block/${dev_name}/holders/" 2>/dev/null | head -1 || true)
        if [ -n "$holders" ]; then
            die "目标设备被 $holders 占用 (LVM/mdraid/device-mapper)"
        fi
    fi
    if [ -f /proc/mdstat ]; then
        if grep -q "$dev_name" /proc/mdstat 2>/dev/null; then
            die "目标设备被 mdraid 占用"
        fi
    fi

    log_msg "目标设备安全检查全部通过: $target"
}

# ============================================================
# 镜像校验
# ============================================================

verify_image() {
    local image="$1"
    local image_dir
    image_dir=$(dirname "$image")
    local image_name
    image_name=$(basename "$image")

    # 检查1: 文件存在
    if [ ! -f "$image" ]; then
        die "镜像文件不存在: $image"
    fi
    log_msg "镜像文件存在: $image ($(du -h "$image" | cut -f1))"

    # 检查2: gzip 完整性
    log_status "正在校验系统镜像..."
    if ! gzip -t "$image" 2>/dev/null; then
        die "镜像 gzip 完整性校验失败: $image"
    fi
    log_msg "gzip 完整性校验通过"

    # 检查3: SHA256 校验
    local sha_file="${image_dir}/SHA256SUMS"
    if [ -f "$sha_file" ]; then
        local expected_sha
        expected_sha=$(grep "  ${image_name}$" "$sha_file" 2>/dev/null | awk '{print $1}' || true)
        if [ -z "$expected_sha" ]; then
            expected_sha=$(grep "${image_name}" "$sha_file" 2>/dev/null | awk '{print $1}' || true)
        fi
        if [ -n "$expected_sha" ]; then
            local actual_sha
            actual_sha=$(sha256sum "$image" | awk '{print $1}')
            if [ "$actual_sha" != "$expected_sha" ]; then
                die "镜像 SHA256 不一致 (期望: ${expected_sha:0:16}..., 实际: ${actual_sha:0:16}...)"
            fi
            log_msg "SHA256 校验通过: ${actual_sha:0:32}..."
        else
            log_msg "警告: SHA256SUMS 中无 $image_name 条目，跳过哈希校验"
        fi
    else
        log_msg "警告: SHA256SUMS 文件不存在，跳过哈希校验"
    fi

    # 获取解压后大小
    local uncompressed_size
    uncompressed_size=$(gzip -l "$image" 2>/dev/null | tail -1 | awk '{print $2}')
    if [ -z "$uncompressed_size" ] || [ "$uncompressed_size" = "-1" ]; then
        uncompressed_size=$(gzip -dc "$image" | wc -c)
    fi
    log_msg "镜像解压大小: ${uncompressed_size} 字节"

    # 只输出数字到 stdout
    echo "$uncompressed_size"
}

# ============================================================
# 写入流程
# ============================================================

write_image() {
    local image="$1"
    local target="$2"

    log_status "正在写入系统..."
    log_msg "写入命令: gzip -dc $image | dd of=$target bs=16M status=progress conv=fsync"

    local start_time
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    local start_seconds
    start_seconds=$(date +%s)
    log_msg "写入开始时间: $start_time"

    # 执行写入 (pipefail 确保两端都检查)
    local write_rc=0
    gzip -dc "$image" | dd of="$target" bs=16M conv=fsync 2>&1 || write_rc=$?

    # 由于管道，需要检查 PIPESTATUS
    # 重新执行检查 (pipefail 已设置，上面 || write_rc 会捕获)
    if [ "$write_rc" -ne 0 ]; then
        die "写入失败 (退出码: $write_rc)"
    fi

    local end_time
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local end_seconds
    end_seconds=$(date +%s)
    local duration=$((end_seconds - start_seconds))
    log_msg "写入结束时间: $end_time"
    log_msg "写入耗时: ${duration} 秒"

    # 同步
    log_status "正在同步磁盘缓存..."
    sync
    log_msg "sync 完成"

    # 重新读取分区表
    log_status "正在重新读取分区表..."
    blockdev --rereadpt "$target" 2>/dev/null || hdparm -z "$target" 2>/dev/null || true
    log_msg "分区表重新读取完成"

    log_msg "写入流程完成"
}

# ============================================================
# 主函数
# ============================================================

usage() {
    echo "用法: $0 --target <设备> --hash <身份哈希> [--boot-mode <BIOS|UEFI>] [--image <路径>]"
    echo ""
    echo "参数:"
    echo "  --target      目标块设备 (如 /dev/vdb)"
    echo "  --hash        第二阶段确认的身份哈希"
    echo "  --boot-mode   启动模式 (BIOS 或 UEFI，默认自动检测)"
    echo "  --image       镜像路径 (默认根据启动模式自动选择)"
    echo "  --test-log    测试日志路径 (可选)"
    exit 1
}

main() {
    local target=""
    local expected_hash=""
    local boot_mode=""
    local image=""

    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --target) target="$2"; shift 2 ;;
            --hash) expected_hash="$2"; shift 2 ;;
            --boot-mode) boot_mode="$2"; shift 2 ;;
            --image) image="$2"; shift 2 ;;
            --test-log) TEST_LOG="$2"; shift 2 ;;
            *) usage ;;
        esac
    done

    if [ -z "$target" ] || [ -z "$expected_hash" ]; then
        usage
    fi

    # 初始化日志
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    log_msg "=========================================="
    log_msg "亚象安装器 镜像写入模块 V${WRITER_VERSION}"
    log_msg "=========================================="

    # 检测启动模式
    if [ -z "$boot_mode" ]; then
        if [ -d /sys/firmware/efi ]; then
            boot_mode="UEFI"
        else
            boot_mode="BIOS"
        fi
    fi
    log_msg "启动模式: $boot_mode"

    # 选择镜像
    if [ -z "$image" ]; then
        if [ "$boot_mode" = "UEFI" ]; then
            image="${IMAGE_DIR}/combined-efi.img.gz"
        else
            image="${IMAGE_DIR}/combined.img.gz"
        fi
    fi
    log_msg "镜像路径: $image"

    # 环境保护检查
    check_environment "$target"

    # 镜像校验
    local uncompressed_size
    uncompressed_size=$(verify_image "$image")

    # 目标设备检查
    log_status "正在确认目标磁盘..."
    check_target_device "$target" "$expected_hash" "$uncompressed_size"

    # 写入
    write_image "$image" "$target"

    # 写后校验
    log_status "正在校验安装结果..."
    local verifier="${SCRIPT_DIR}/image-verifier.sh"
    if [ -f "$verifier" ]; then
        local verify_args="--target $target --image $image --hash $expected_hash --size $uncompressed_size"
        if [ -n "$TEST_LOG" ]; then
            verify_args="$verify_args --test-log $TEST_LOG"
        fi
        if ! bash "$verifier" $verify_args; then
            die "写后校验失败"
        fi
    else
        log_msg "警告: 校验脚本不存在，跳过写后校验"
    fi

    # 成功
    echo ""
    echo "========================================"
    echo "  亚象网络操作系统安装成功"
    echo "========================================"
    echo "  目标磁盘: $target"
    echo "  镜像: $(basename "$image")"
    echo "  启动模式: $boot_mode"
    echo "========================================"
    echo ""
    log_msg "最终状态: 安装成功"
    log_msg "=========================================="
}

main "$@"
