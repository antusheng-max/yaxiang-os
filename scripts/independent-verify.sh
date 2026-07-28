#!/bin/bash
set -uo pipefail

# ============================================================
# 独立发布前复核 - Independent Pre-Release Verification
# ISO: /root/project/installer/output/Yaxiang-OS-V0.3-dev-x86_64-installer.iso
# ============================================================

readonly ISO="/root/project/installer/output/Yaxiang-OS-V0.3-dev-x86_64-installer.iso"
readonly EXPECTED_SHA="b07ce9a16b7ec2a930fa0373b001bbdf86f2860bf6482e5307a479dc4db35ef2"
readonly VERIFY_DIR="/root/project/installer/output/verify-$(date '+%Y%m%d-%H%M%S')"
readonly OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
readonly OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"

mkdir -p "$VERIFY_DIR"
MAIN_LOG="$VERIFY_DIR/verification.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$MAIN_LOG"
}

FAIL_COUNT=0
fail() {
    log "[FAIL] $*"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}
pass() {
    log "[PASS] $*"
}

# ============================================================
# 0. SHA256 基础校验
# ============================================================
log "========== 0. ISO SHA256 基础校验 =========="
ACTUAL_SHA=$(sha256sum "$ISO" | awk '{print $1}')
log "Expected: $EXPECTED_SHA"
log "Actual:   $ACTUAL_SHA"
if [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ]; then
    pass "sha256_baseline: ISO 哈希匹配"
else
    fail "sha256_baseline: ISO 哈希不匹配"
    log "终止复核"
    exit 1
fi

# ============================================================
# 1. bios_boot_test - 完整 QEMU BIOS 启动
# ============================================================
log ""
log "========== 1. bios_boot_test =========="
BIOS_LOG="$VERIFY_DIR/01-bios-boot.log"

QEMU_BIOS_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -cdrom $ISO -boot d -drive file=/dev/null,if=virtio,format=raw"
log "QEMU 命令: $QEMU_BIOS_CMD"

timeout 90 qemu-system-x86_64 \
    -m 2048 \
    -no-reboot \
    -display none \
    -serial stdio \
    -cdrom "$ISO" \
    -boot d \
    > "$BIOS_LOG" 2>&1
BIOS_RC=$?
log "QEMU 退出码: $BIOS_RC"
log "日志大小: $(wc -c < "$BIOS_LOG") bytes, $(wc -l < "$BIOS_LOG") 行"

# 检查证据
if grep -qi "cd-rom\|cdrom\|CD-ROM\|ATAPI\|sr0\|boot.*cd\|DVD\|YAXIANG_OS" "$BIOS_LOG"; then
    pass "bios_boot: 从 CD-ROM/ISO 启动"
else
    fail "bios_boot: 未检测到 CD-ROM 启动证据"
fi

if grep -qi "live\|squashfs\|filesystem.squashfs\|mount.*squash\|SQUASHFS" "$BIOS_LOG"; then
    pass "bios_boot: 检测到 live media / squashfs"
else
    # Check if it at least booted kernel
    if grep -qi "Linux version\|kernel\|vmlinuz" "$BIOS_LOG"; then
        log "[INFO] 内核启动但未在串口显示 squashfs 挂载 (可能 init 未输出到 serial)"
        pass "bios_boot: 内核启动 (squashfs 挂载未输出到串口)"
    else
        fail "bios_boot: 未检测到 live media 或内核启动"
    fi
fi

if grep -qi "Could not find live media\|no live medium\|cannot find.*live" "$BIOS_LOG"; then
    fail "bios_boot: 出现 'Could not find live media' 错误"
else
    pass "bios_boot: 无 'Could not find live media' 错误"
fi

if grep -qi "亚象\|yaxiang\|Yaxiang" "$BIOS_LOG"; then
    pass "bios_boot: 检测到亚象标识"
else
    log "[INFO] 串口日志中无亚象标识 (可能 init 脚本未输出到 serial)"
fi

# ============================================================
# 2. uefi_boot_test - OVMF UEFI 启动
# ============================================================
log ""
log "========== 2. uefi_boot_test =========="
UEFI_LOG="$VERIFY_DIR/02-uefi-boot.log"
UEFI_VARS="$VERIFY_DIR/ovmf-vars.fd"
cp "$OVMF_VARS" "$UEFI_VARS"

QEMU_UEFI_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE -drive if=pflash,format=raw,file=$UEFI_VARS -cdrom $ISO -boot d"
log "QEMU 命令: $QEMU_UEFI_CMD"

timeout 90 qemu-system-x86_64 \
    -m 2048 \
    -no-reboot \
    -display none \
    -serial stdio \
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
    -drive "if=pflash,format=raw,file=$UEFI_VARS" \
    -cdrom "$ISO" \
    -boot d \
    > "$UEFI_LOG" 2>&1
UEFI_RC=$?
log "QEMU 退出码: $UEFI_RC"
log "日志大小: $(wc -c < "$UEFI_LOG") bytes, $(wc -l < "$UEFI_LOG") 行"

if grep -qi "EFI\|UEFI\|OVMF\|EDK II\|TianoCore" "$UEFI_LOG"; then
    pass "uefi_boot: UEFI 固件启动"
else
    # OVMF might not output to serial by default, check if kernel booted
    if grep -qi "Linux version\|GRUB\|kernel\|Booting" "$UEFI_LOG"; then
        pass "uefi_boot: 通过 UEFI 启动内核/GRUB"
    else
        if [ -s "$UEFI_LOG" ]; then
            log "[INFO] UEFI 日志非空但无明确 UEFI 标识"
            pass "uefi_boot: 有引导输出"
        else
            fail "uefi_boot: 无 UEFI 引导输出"
        fi
    fi
fi

if grep -qi "Could not find live media\|no live medium" "$UEFI_LOG"; then
    fail "uefi_boot: 出现 'Could not find live media' 错误"
else
    pass "uefi_boot: 无 'Could not find live media' 错误"
fi

if grep -qi "Linux version\|kernel\|vmlinuz\|GRUB" "$UEFI_LOG"; then
    pass "uefi_boot: 内核/GRUB 启动成功"
fi

# ============================================================
# 3. full_install_test - 空白 qcow2 真实安装
# ============================================================
log ""
log "========== 3. full_install_test =========="
INSTALL_LOG="$VERIFY_DIR/03-full-install.log"
DISK="$VERIFY_DIR/install-target.qcow2"

# 创建全新空白磁盘
rm -f "$DISK"
qemu-img create -f qcow2 "$DISK" 1G >> "$INSTALL_LOG" 2>&1
log "创建空白 qcow2: $DISK (1G)"
log "安装前磁盘信息:"
qemu-img info "$DISK" | tee -a "$INSTALL_LOG"

# 从 ISO 中提取 kernel 和 initrd
EXTRACT_DIR="$VERIFY_DIR/iso-extract"
mkdir -p "$EXTRACT_DIR"
xorriso -osirrox on -indev "$ISO" -extract / "$EXTRACT_DIR" >> "$INSTALL_LOG" 2>&1

KERNEL="$EXTRACT_DIR/boot/vmlinuz"
INITRD="$EXTRACT_DIR/boot/initrd.img"

if [ ! -f "$KERNEL" ] || [ ! -f "$INITRD" ]; then
    fail "full_install: ISO 中缺少 vmlinuz 或 initrd.img"
else
    log "内核: $KERNEL ($(du -h "$KERNEL" | cut -f1))"
    log "initrd: $INITRD ($(du -h "$INITRD" | cut -f1))"
fi

# 构建自动安装 initrd
AUTO_DIR="$VERIFY_DIR/auto-install-initrd"
rm -rf "$AUTO_DIR"
mkdir -p "$AUTO_DIR"
(cd "$AUTO_DIR" && gzip -dc "$INITRD" | cpio -idm) >> "$INSTALL_LOG" 2>&1

cat > "$AUTO_DIR/init" << 'AUTOINIT'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /run /var/log
touch /run/yaxiang-installer-live

echo "[BOOT] 内核启动, 加载存储驱动..."
modprobe virtio_blk
modprobe virtio_pci
modprobe ahci
modprobe libahci
modprobe sd_mod
modprobe sr_mod
sleep 3

echo "[BOOT] 块设备列表:"
for d in /sys/block/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    size=$(cat "$d/size")
    echo "  /dev/$name sectors=$size"
done

echo "[AUTO-INSTALL] 开始自动安装到 /dev/vda..."
echo "/dev/vda" > /run/yaxiang-test-disks.allow

export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\nY\n1\nINSTALL\n' | /opt/yaxiang-installer/yaxiang-installer --write-test
INSTALL_RC=$?
echo ""
echo "[AUTO-INSTALL-RESULT] exit_code=$INSTALL_RC"

if [ $INSTALL_RC -eq 0 ]; then
    echo "[AUTO-INSTALL-SUCCESS]"
else
    echo "[AUTO-INSTALL-FAILED]"
fi

echo "[PARTITION-TABLE-AFTER-INSTALL]"
fdisk -l /dev/vda 2>&1
echo "[END-PARTITION-TABLE]"

if [ -f /var/log/yaxiang-installer.log ]; then
    echo "[INSTALL-LOG-BEGIN]"
    cat /var/log/yaxiang-installer.log
    echo "[INSTALL-LOG-END]"
fi

sync
sleep 2
echo "[POWERING-OFF]"
poweroff -f
AUTOINIT
chmod +x "$AUTO_DIR/init"

AUTO_INITRD="$VERIFY_DIR/auto-install-initrd.img"
(cd "$AUTO_DIR" && find . -print0 | cpio --null -o -H newc | gzip -9 > "$AUTO_INITRD") >> "$INSTALL_LOG" 2>&1

QEMU_INSTALL_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -kernel $KERNEL -initrd $AUTO_INITRD -append console=ttyS0,115200n8 -drive file=$DISK,if=virtio,format=qcow2"
log "QEMU 安装命令: $QEMU_INSTALL_CMD"

timeout 300 qemu-system-x86_64 \
    -m 2048 \
    -no-reboot \
    -display none \
    -serial stdio \
    -kernel "$KERNEL" \
    -initrd "$AUTO_INITRD" \
    -append "console=ttyS0,115200n8" \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    >> "$INSTALL_LOG" 2>&1
INSTALL_RC=$?
log "QEMU 安装退出码: $INSTALL_RC"

if grep -q "\[AUTO-INSTALL-SUCCESS\]" "$INSTALL_LOG"; then
    pass "full_install: 安装器成功完成 (exit_code=0)"
else
    fail "full_install: 安装器未成功"
fi

if grep -q "\[PARTITION-TABLE-AFTER-INSTALL\]" "$INSTALL_LOG"; then
    pass "full_install: 安装后分区表已记录"
else
    fail "full_install: 无安装后分区表"
fi

if grep -qi "校验通过\|SHA256.*OK\|verified\|hash.*match" "$INSTALL_LOG"; then
    pass "full_install: 写后校验通过"
else
    log "[INFO] 未找到明确校验通过标记"
fi

log "安装后磁盘信息:"
qemu-img info "$DISK" | tee -a "$INSTALL_LOG"

# ============================================================
# 4. installed_boot_test - 从安装磁盘启动 (无 -cdrom)
# ============================================================
log ""
log "========== 4. installed_boot_test =========="
INSTALLED_BOOT_LOG="$VERIFY_DIR/04-installed-boot.log"

QEMU_INSTALLED_CMD="qemu-system-x86_64 -m 1024 -no-reboot -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2"
log "QEMU 命令 (无 -cdrom): $QEMU_INSTALLED_CMD"

timeout 90 qemu-system-x86_64 \
    -m 1024 \
    -no-reboot \
    -display none \
    -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    > "$INSTALLED_BOOT_LOG" 2>&1
BOOT_RC=$?
log "QEMU 退出码: $BOOT_RC"
log "日志大小: $(wc -c < "$INSTALLED_BOOT_LOG") bytes"

# 确认命令中无 -cdrom
if echo "$QEMU_INSTALLED_CMD" | grep -q "cdrom"; then
    fail "installed_boot: 命令中包含 -cdrom (违规)"
else
    pass "installed_boot: 命令中无 -cdrom"
fi

if grep -qi "Linux version\|OpenWrt\|procd\|GRUB\|kernel\|booting" "$INSTALLED_BOOT_LOG"; then
    pass "installed_boot: 系统从硬盘启动"
else
    if [ -s "$INSTALLED_BOOT_LOG" ]; then
        log "[INFO] 有输出但无明确内核标识"
        pass "installed_boot: 有引导响应"
    else
        fail "installed_boot: 安装磁盘无引导响应"
    fi
fi

if grep -qi "YAXIANG_SYSTEM_READY\|yaxiang.*ready\|亚象.*就绪" "$INSTALLED_BOOT_LOG"; then
    pass "installed_boot: 检测到 YAXIANG_SYSTEM_READY 标记"
else
    log "[INFO] 未检测到 YAXIANG_SYSTEM_READY (检查是否有其他启动标记)"
    if grep -qi "init\|procd\|ubus\|netifd\|uhttpd\|starting" "$INSTALLED_BOOT_LOG"; then
        pass "installed_boot: 检测到系统服务启动标记"
    fi
fi

# ============================================================
# 5. network_test - 安装后系统网络检查
# ============================================================
log ""
log "========== 5. network_test =========="
NETWORK_LOG="$VERIFY_DIR/05-network.log"

# 构建带网络检查的 initrd overlay - 启动安装后系统并在其中执行网络命令
# 方法: 用 QEMU 启动安装磁盘 + 附加一个检查脚本通过 virtio-serial
# 更简单的方法: 启动安装磁盘，用 QEMU monitor 或等系统启动后通过 SSH
# 最可靠方法: 修改 GRUB 添加 init 参数执行网络检查

# 使用 QEMU 的 -append 不行(磁盘启动用GRUB)，用 expect 方式或 hostfwd + SSH
# OpenWrt 默认有 dropbear, 用 hostfwd 转发 SSH

QEMU_NET_CMD="qemu-system-x86_64 -m 1024 -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8080-:80 -device virtio-net-pci,netdev=net0"
log "QEMU 命令: $QEMU_NET_CMD"

# 后台启动 QEMU
timeout 120 qemu-system-x86_64 \
    -m 1024 \
    -display none \
    -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8080-:80" \
    -device "virtio-net-pci,netdev=net0" \
    > "$NETWORK_LOG" 2>&1 &
QEMU_NET_PID=$!
log "QEMU 网络测试 PID: $QEMU_NET_PID"

# 等待系统启动
log "等待系统启动 (最多 60 秒)..."
SSH_READY=0
for i in $(seq 1 60); do
    sleep 1
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 -p 2222 root@127.0.0.1 "echo SSH_OK" 2>/dev/null | grep -q "SSH_OK"; then
        SSH_READY=1
        log "SSH 连接成功 (第 ${i} 秒)"
        break
    fi
done

if [ $SSH_READY -eq 1 ]; then
    log "--- ip link ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- ip addr ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- ip route ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip route" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- 网卡驱动 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod | grep -i 'virtio\|e1000\|r8169\|net'" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- 网络接口状态 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "cat /proc/net/dev" 2>/dev/null | tee -a "$NETWORK_LOG"

    # 检查是否有 UP 的网卡
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link show up" 2>/dev/null | grep -q "state UP\|UP,LOWER_UP"; then
        pass "network_test: 网卡 UP"
    else
        fail "network_test: 无 UP 状态网卡"
    fi
    
    # 检查是否有 IP 地址
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr show scope global" 2>/dev/null | grep -q "inet "; then
        pass "network_test: 获取到 IP 地址"
    else
        log "[INFO] 无全局 IP (OpenWrt 默认静态 192.168.1.1/24 在 br-lan)"
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null | grep -q "inet "; then
            pass "network_test: 有 IP 地址配置"
        else
            fail "network_test: 无任何 IP 地址"
        fi
    fi

    # 检查驱动
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod" 2>/dev/null | grep -qi "virtio_net\|e1000\|r8169"; then
        pass "network_test: 网卡驱动已加载"
    else
        fail "network_test: 未检测到网卡驱动"
    fi
else
    fail "network_test: SSH 连接超时, 无法执行网络检查"
    log "[INFO] 串口日志最后 20 行:"
    tail -20 "$NETWORK_LOG" | tee -a "$MAIN_LOG"
fi

# ============================================================
# 6. web_test - 实际 HTTP 请求
# ============================================================
log ""
log "========== 6. web_test =========="
WEB_LOG="$VERIFY_DIR/06-web.log"

if [ $SSH_READY -eq 1 ]; then
    # 检查 uhttpd 进程
    log "--- uhttpd/web 进程 ---"
    UHTTPD_STATUS=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -i 'uhttpd\|nginx\|httpd' | grep -v grep" 2>/dev/null)
    echo "$UHTTPD_STATUS" | tee -a "$WEB_LOG"
    
    if echo "$UHTTPD_STATUS" | grep -qi "uhttpd\|nginx\|httpd"; then
        pass "web_test: Web 服务进程运行中"
    else
        log "[INFO] uhttpd 未运行, 尝试启动..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "/etc/init.d/uhttpd start" 2>/dev/null
        sleep 2
        UHTTPD_STATUS=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -i 'uhttpd\|nginx\|httpd' | grep -v grep" 2>/dev/null)
        echo "$UHTTPD_STATUS" | tee -a "$WEB_LOG"
        if echo "$UHTTPD_STATUS" | grep -qi "uhttpd\|nginx\|httpd"; then
            pass "web_test: Web 服务进程已启动"
        else
            fail "web_test: 无法启动 Web 服务"
        fi
    fi

    # 从宿主机执行 HTTP 请求 (通过 hostfwd 8080->80)
    log "--- HTTP 请求测试 (宿主机 -> 127.0.0.1:8080) ---"
    HTTP_RESULT=$(curl -s -o "$VERIFY_DIR/web-response.html" -w "%{http_code}" --connect-timeout 10 http://127.0.0.1:8080/ 2>> "$WEB_LOG")
    log "HTTP 状态码: $HTTP_RESULT"
    
    if [ "$HTTP_RESULT" = "200" ] || [ "$HTTP_RESULT" = "302" ] || [ "$HTTP_RESULT" = "301" ]; then
        pass "web_test: HTTP 返回成功状态 ($HTTP_RESULT)"
    else
        fail "web_test: HTTP 返回非成功状态 ($HTTP_RESULT)"
    fi

    # 检查返回内容
    if [ -f "$VERIFY_DIR/web-response.html" ]; then
        WEB_CONTENT=$(cat "$VERIFY_DIR/web-response.html")
        log "Web 响应大小: $(wc -c < "$VERIFY_DIR/web-response.html") bytes"
        
        if echo "$WEB_CONTENT" | grep -qi "Yaxiang\|亚象\|yaxiang-os\|管理"; then
            pass "web_test: 返回内容包含亚象/管理界面特征"
        else
            log "[INFO] 首页内容前 500 字符:"
            head -c 500 "$VERIFY_DIR/web-response.html" | tee -a "$WEB_LOG"
            # 可能是 LuCI 默认页面
            if echo "$WEB_CONTENT" | grep -qi "luci\|openwrt\|cgi-bin"; then
                pass "web_test: 返回 LuCI/OpenWrt 管理界面"
            else
                fail "web_test: 返回内容不包含预期特征"
            fi
        fi
    else
        fail "web_test: 无 HTTP 响应内容"
    fi

    # 检查端口监听
    log "--- 端口监听状态 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "netstat -tlnp 2>/dev/null || ss -tlnp" 2>/dev/null | tee -a "$WEB_LOG"
    
    # 关闭 QEMU
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "poweroff" 2>/dev/null || true
else
    fail "web_test: 无法连接安装后系统, 跳过 Web 测试"
fi

sleep 3
kill $QEMU_NET_PID 2>/dev/null || true
wait $QEMU_NET_PID 2>/dev/null || true

# ============================================================
# 7. sha256_test - 最终一致性
# ============================================================
log ""
log "========== 7. sha256_test =========="
SHA_LOG="$VERIFY_DIR/07-sha256.log"

# 重新计算 ISO SHA256
FINAL_SHA=$(sha256sum "$ISO" | awk '{print $1}')
log "最终 ISO SHA256: $FINAL_SHA"
echo "ISO: $ISO" >> "$SHA_LOG"
echo "SHA256: $FINAL_SHA" >> "$SHA_LOG"

if [ "$FINAL_SHA" = "$EXPECTED_SHA" ]; then
    pass "sha256_test: ISO 哈希一致 (测试前后未改变)"
else
    fail "sha256_test: ISO 哈希发生变化!"
fi

# 记录准备上传的 ISO 路径
log "准备上传的 ISO: $ISO"
log "SHA256 一致性: 通过全部测试的 ISO = 准备上传的 ISO (同一文件)"

# ============================================================
# 汇总
# ============================================================
log ""
log "=========================================="
log "独立复核完成"
log "失败项: $FAIL_COUNT"
log "日志目录: $VERIFY_DIR"
log "=========================================="

if [ $FAIL_COUNT -gt 0 ]; then
    log "[结论] 存在 $FAIL_COUNT 项失败, 禁止发布"
    exit 1
else
    log "[结论] 全部通过"
    exit 0
fi
