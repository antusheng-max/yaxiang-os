#!/bin/bash
# 亚象网络操作系统 - 项目恢复脚本
# 用途: 快速检查项目状态，帮助开发者恢复上下文

set -euo pipefail

PROJECT_DIR="/root/project"

echo "=========================================="
echo "  亚象网络操作系统 - 项目状态检查"
echo "=========================================="
echo ""

# 1. 检查项目目录
echo "[1] 项目目录结构"
if [ -d "$PROJECT_DIR" ]; then
    echo "  项目根目录: $PROJECT_DIR (存在)"
else
    echo "  [错误] 项目根目录不存在: $PROJECT_DIR"
    exit 1
fi

# 2. 检查 Git 状态
echo ""
echo "[2] Git 状态"
if [ -d "$PROJECT_DIR/.git" ]; then
    cd "$PROJECT_DIR"
    echo "  分支: $(git branch --show-current 2>/dev/null || echo '未知')"
    echo "  最新提交: $(git log --oneline -1 2>/dev/null || echo '无')"
    echo "  未提交修改: $(git status --short 2>/dev/null | wc -l) 个文件"
else
    echo "  项目不是 Git 仓库"
fi

# 3. 检查安装器状态
echo ""
echo "[3] 安装器状态"
INSTALLER="$PROJECT_DIR/installer/src/yaxiang-installer"
if [ -f "$INSTALLER" ]; then
    echo "  安装器: $INSTALLER ($(wc -l < "$INSTALLER") 行)"
    STAGE=$(grep "INSTALLER_STAGE=" "$INSTALLER" | head -1 | cut -d'"' -f2)
    echo "  当前阶段: Stage $STAGE"
else
    echo "  [警告] 安装器不存在"
fi

# 4. 检查系统镜像
echo ""
echo "[4] 系统镜像"
for img in "$PROJECT_DIR"/installer/images/*.img.gz; do
    [ -f "$img" ] || continue
    echo "  $(basename "$img"): $(du -h "$img" | cut -f1)"
done

# 5. 检查 Live 环境
echo ""
echo "[5] Live 环境"
SQUASHFS="$PROJECT_DIR/installer/output/iso-staging/live/filesystem.squashfs"
if [ -f "$SQUASHFS" ]; then
    echo "  SquashFS: $(du -h "$SQUASHFS" | cut -f1)"
else
    echo "  [警告] SquashFS 不存在"
fi

KERNEL="$PROJECT_DIR/installer/output/iso-staging/boot/vmlinuz"
if [ -f "$KERNEL" ]; then
    echo "  内核: $(du -h "$KERNEL" | cut -f1)"
else
    echo "  [警告] 内核不存在"
fi

# 6. 检查报告文件
echo ""
echo "[6] 阶段报告"
for report in "$PROJECT_DIR"/installer/output/stage*-report.md; do
    [ -f "$report" ] || continue
    echo "  $(basename "$report")"
done

# 7. 检查构建工具
echo ""
echo "[7] 构建工具"
for tool in qemu-system-x86_64 qemu-img xorriso grub-mkimage cpio; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  $tool: 可用"
    else
        echo "  $tool: 不可用"
    fi
done

# 8. 检查运行中的服务
echo ""
echo "[8] 相关进程"
if pgrep -f "qemu-system" >/dev/null 2>&1; then
    echo "  QEMU: 运行中"
else
    echo "  QEMU: 未运行"
fi

if pgrep -f "nginx" >/dev/null 2>&1; then
    echo "  Nginx: 运行中"
else
    echo "  Nginx: 未运行"
fi

# 9. 下一步任务
echo ""
echo "[9] 下一步任务"
NEXT_TASK="$PROJECT_DIR/docs/handover/NEXT_TASK.md"
if [ -f "$NEXT_TASK" ]; then
    head -5 "$NEXT_TASK" | tail -3
else
    echo "  无 NEXT_TASK.md"
fi

echo ""
echo "=========================================="
echo "  检查完成"
echo "=========================================="
