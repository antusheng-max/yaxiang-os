#!/bin/bash
# 亚象 OS 构建控制脚本
# 25 阶段流水线，状态写入 build/BUILD-STATE.json
# 长时间任务请在 tmux 会话 yaxiang-build 中运行
set -euo pipefail

readonly VERSION="V0.3-dev"
readonly PROJECT_DIR="/root/project"
readonly BUILD_ROOT="/home/builder/yaxiang-build"
readonly OPENWRT_COMMIT="f5dae5ece4805730c5e2850f8aa84765af2f6b32"
readonly LOG_DIR="${PROJECT_DIR}/logs"
readonly ARTIFACT_DIR="${PROJECT_DIR}/artifacts"
readonly RELEASE_DIR="${PROJECT_DIR}/release/${VERSION}"
readonly STATE_FILE="${PROJECT_DIR}/build/BUILD-STATE.json"
readonly TMUX_SESSION="yaxiang-build"
readonly MIN_DISK_GB=8
readonly STOP_DISK_GB=5
readonly MAKE_JOBS=1

STAGES=(
  01-preflight
  02-host-dependencies
  03-source-checkout
  04-feeds
  05-config-import
  06-download
  07-tools
  08-toolchain
  09-kernel-prepare
  10-kernel-compile
  11-kernel-modules
  12-openwrt-image
  13-web-build
  14-rootfs-integration
  15-installer-build
  16-iso-build
  17-qemu-boot
  18-qemu-install
  19-uefi-test
  20-disk-test
  21-five-reboot-test
  22-security-scan
  23-sbom
  24-release-validation
  25-release-package
)

usage() {
  cat <<EOF
用法: $(basename "$0") <command> [stage]

命令:
  list              列出所有阶段及状态
  run [stage]       从指定阶段顺序执行（默认 01-preflight）
  run-one <stage>   仅执行单个阶段
  status            显示 BUILD-STATE.json 摘要
  check-disk        检查磁盘空间

环境:
  构建目录: ${BUILD_ROOT}
  OpenWrt:  25.12.5 @ ${OPENWRT_COMMIT}
  tmux:     ${TMUX_SESSION}
EOF
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_disk() {
  local avail_kb
  avail_kb=$(df -k / | awk 'NR==2 {print $4}')
  local avail_gb=$((avail_kb / 1024 / 1024))
  log "磁盘可用: ${avail_gb} GB"
  if [ "$avail_gb" -lt "$STOP_DISK_GB" ]; then
    log "FATAL: 可用空间 ${avail_gb}GB < ${STOP_DISK_GB}GB，立即停止"
    exit 1
  fi
  if [ "$avail_gb" -lt "$MIN_DISK_GB" ]; then
    log "WARN: 可用空间 ${avail_gb}GB < ${MIN_DISK_GB}GB，禁止启动大型构建"
    return 1
  fi
  return 0
}

update_state() {
  local stage="$1" status="$2" exit_code="${3:-0}"
  local log_path="${LOG_DIR}/${stage}.log"
  local now
  now=$(date -Iseconds)
  python3 - "$STATE_FILE" "$stage" "$status" "$now" "$exit_code" "$log_path" <<'PY'
import json, sys
path, stage, status, ts, exit_code, log_path = sys.argv[1:7]
with open(path) as f:
    data = json.load(f)
s = data["stages"][stage]
s["status"] = status
if status == "running":
    s["started_at"] = ts
elif status in ("passed", "failed", "skipped"):
    s["finished_at"] = ts
    s["exit_code"] = int(exit_code)
    s["log_path"] = log_path
data["updated_at"] = ts
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

run_stage() {
  local stage="$1"
  local log_path="${LOG_DIR}/${stage}.log"
  mkdir -p "$LOG_DIR" "$ARTIFACT_DIR"
  check_disk || return 1

  update_state "$stage" "running"
  log "=== 开始阶段: ${stage} ===" | tee "$log_path"

  local rc=0
  case "$stage" in
    01-preflight)
      {
        echo "HEAD: $(git -C "$PROJECT_DIR" rev-parse HEAD)"
        echo "Branch: $(git -C "$PROJECT_DIR" branch --show-current)"
        echo "Patches: $(ls "$PROJECT_DIR/openwrt/kernel-patches/6.12/"*.patch | wc -l)"
        sha256sum "$PROJECT_DIR/openwrt/kernel-patches/6.12/"*.patch
        test -f "$PROJECT_DIR/openwrt/configs/x86_64-security.config"
        df -h /
      } >> "$log_path" 2>&1
      ;;
    02-host-dependencies)
      echo "TODO: apt install build dependencies" >> "$log_path"
      rc=0
      ;;
    03-source-checkout)
      echo "TODO: create builder user and clone OpenWrt @ ${OPENWRT_COMMIT}" >> "$log_path"
      rc=0
      ;;
    *)
      echo "TODO: stage ${stage} not yet implemented" >> "$log_path"
      rc=0
      ;;
  esac

  if [ "$rc" -eq 0 ]; then
    update_state "$stage" "passed" "$rc"
    log "=== 阶段通过: ${stage} ==="
  else
    update_state "$stage" "failed" "$rc"
    log "=== 阶段失败: ${stage} (rc=${rc}) ==="
    return "$rc"
  fi
}

cmd="${1:-status}"
case "$cmd" in
  list)
    python3 - "$STATE_FILE" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for sid, info in data["stages"].items():
    print(f"{sid:25s} {info['status']}")
PY
    ;;
  status) cat "$STATE_FILE" ;;
  check-disk) check_disk ;;
  run-one)
    shift
    run_stage "${1:?stage required}"
    ;;
  run)
    shift
    start="${1:-01-preflight}"
    found=0
    for stage in "${STAGES[@]}"; do
      [ "$found" -eq 1 ] || [ "$stage" = "$start" ] && found=1
      [ "$found" -eq 1 ] || continue
      run_stage "$stage" || exit 1
    done
    ;;
  *)
    usage
    exit 1
    ;;
esac
