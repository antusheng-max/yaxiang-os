#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象网络操作系统 - 安装 ISO 验证脚本
# 第四阶段: 验证 ISO 完整性和安全性
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${INSTALLER_DIR}/output"
ISO_NAME="Yaxiang-OS-V0.3-dev-x86_64-installer.iso"
ISO_PATH="${OUTPUT_DIR}/${ISO_NAME}"

CHECKS_PASSED=0
CHECKS_FAILED=0

pass() { CHECKS_PASSED=$((CHECKS_PASSED+1)); echo "  [通过] $*"; }
fail() { CHECKS_FAILED=$((CHECKS_FAILED+1)); echo "  [失败] $*"; }

echo "=========================================="
echo "  亚象安装 ISO 验证"
echo "=========================================="
echo ""

# 1. ISO 存在且非空
echo "[1] ISO 文件检查"
if [ -f "$ISO_PATH" ] && [ -s "$ISO_PATH" ]; then
    pass "ISO 存在且非空 ($(du -h "$ISO_PATH" | cut -f1))"
else
    fail "ISO 不存在或为空"
    echo "验证中止: ISO 文件不存在"
    exit 1
fi

# 2. ISO SHA256
echo "[2] ISO SHA256 校验"
if [ -f "${OUTPUT_DIR}/SHA256SUMS" ]; then
    if (cd "$OUTPUT_DIR" && sha256sum -c SHA256SUMS >/dev/null 2>&1); then
        pass "ISO SHA256 正确"
    else
        fail "ISO SHA256 不一致"
    fi
else
    fail "SHA256SUMS 文件不存在"
fi

# 3. 使用 xorriso 检查 ISO 内容
echo "[3] ISO 内容检查"
ISO_FILES=$(xorriso -indev "$ISO_PATH" -find / 2>/dev/null || true)

# BIOS 启动文件
if echo "$ISO_FILES" | grep -qi "boot/grub"; then
    pass "GRUB 启动文件存在"
else
    fail "GRUB 启动文件缺失"
fi

# UEFI 启动文件
if echo "$ISO_FILES" | grep -qi "efi"; then
    pass "UEFI 启动文件存在"
else
    fail "UEFI 启动文件缺失"
fi

# 内核和 initrd
if echo "$ISO_FILES" | grep -q "vmlinuz"; then
    pass "Live 内核存在"
else
    fail "Live 内核缺失"
fi

if echo "$ISO_FILES" | grep -q "initrd"; then
    pass "Live initrd 存在"
else
    fail "Live initrd 缺失"
fi

# 安装器
if echo "$ISO_FILES" | grep -q "yaxiang-installer"; then
    pass "亚象安装器存在"
else
    fail "亚象安装器缺失"
fi

# 系统镜像
if echo "$ISO_FILES" | grep -q "combined.img.gz"; then
    pass "BIOS 系统镜像存在"
else
    fail "BIOS 系统镜像缺失"
fi

if echo "$ISO_FILES" | grep -q "combined-efi.img.gz"; then
    pass "UEFI 系统镜像存在"
else
    fail "UEFI 系统镜像缺失"
fi

# 安全模块
if echo "$ISO_FILES" | grep -q "image-writer"; then
    pass "镜像写入模块存在"
else
    fail "镜像写入模块缺失"
fi

if echo "$ISO_FILES" | grep -q "image-verifier"; then
    pass "写后校验模块存在"
else
    fail "写后校验模块缺失"
fi

# 4. 安全检查 - 不包含开发文件
echo "[4] 安全性检查"
SENSITIVE=0
for pattern in "node_modules" ".git/" "source.map" ".map.js" "id_rsa" ".ssh/" ".env.local" ".env.production" "dev-mock" "package.json"; do
    if echo "$ISO_FILES" | grep -q "$pattern"; then
        fail "包含敏感文件: $pattern"
        SENSITIVE=1
    fi
done
if [ "$SENSITIVE" -eq 0 ]; then
    pass "不包含开发和敏感文件"
fi

# 5. El Torito 引导记录
echo "[5] 引导记录检查"
if xorriso -indev "$ISO_PATH" -report_el_torito plain 2>/dev/null | grep -qi "boot"; then
    pass "El Torito 引导记录存在"
else
    # 备用检查
    if xorriso -indev "$ISO_PATH" -report_system_area plain 2>/dev/null | grep -qi "GRUB\|MBR\|GPT"; then
        pass "系统引导区域存在"
    else
        fail "无引导记录"
    fi
fi

# 汇总
echo ""
echo "=========================================="
echo "  验证结果: 通过 $CHECKS_PASSED / 失败 $CHECKS_FAILED"
echo "=========================================="

[ "$CHECKS_FAILED" -eq 0 ]
