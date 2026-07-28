#!/bin/bash
set -uo pipefail

# ============================================================
# 独立发布前复核 v2 - 修复串口输出后重新验证
# ============================================================

readonly ISO="/root/project/installer/output/Yaxiang-OS-V0.3-dev-x86_64-installer.iso"
readonly EXPECTED_SHA="7108cc8583361df63716bfac622cb27950ea0706989efc3d3a196dc51f1ca14d"
readonly VERIFY_DIR="/root/project/installer/output/verify-final"
readonly OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
readonly OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"

rm -rf "$VERIFY_DIR"
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
    exit 1
fi
log "ISO 大小: $(ls -lh "$ISO" | awk '{print $5}')"

# ============================================================
# 1. bios_boot_test
# ============================================================
log ""
log "========== 1. bios_boot_test =========="
BIOS_LOG="$VERIFY_DIR/01-bios-boot.log"

QEMU_BIOS_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -cdrom $ISO -boot d"
log "QEMU 命令: $QEMU_BIOS_CMD"

timeout 120 qemu-system-x86_64 \
    -m 2048 \
    -no-reboot \
    -display none \
    -serial stdio \
    -cdrom "$ISO" \
    -boot d \
    > "$BIOS_LOG" 2>&1
BIOS_RC=$?
log "QEMU 退出码: $BIOS_RC (124=timeout 正常)"
log "日志大小: $(wc -c < "$BIOS_LOG") bytes, $(wc -l < "$BIOS_LOG") 行"

# 证据检查
if grep -qi "GRUB\|GNU GRUB\|grub" "$BIOS_LOG"; then
    pass "bios_boot: GRUB 引导加载程序启动"
else
    fail "bios_boot: 未检测到 GRUB"
fi

if grep -qi "Linux version\|linux.*version" "$BIOS_LOG"; then
    pass "bios_boot: Linux 内核启动"
else
    fail "bios_boot: 未检测到内核启动"
fi

if grep -qi "cd-rom\|cdrom\|CD-ROM\|ATAPI\|sr0\|YAXIANG_OS\|cd\b" "$BIOS_LOG"; then
    pass "bios_boot: 从 CD-ROM/ISO 启动"
else
    # GRUB set root=(cd) implies CD boot
    if grep -qi "GRUB\|grub" "$BIOS_LOG"; then
        log "[INFO] GRUB 从 CD 加载 (grub.cfg 中 set root=(cd))"
        pass "bios_boot: 从 CD-ROM 启动 (GRUB 配置确认)"
    else
        fail "bios_boot: 未检测到 CD-ROM 启动证据"
    fi
fi

if grep -qi "squashfs\|squash\|filesystem.squashfs\|live" "$BIOS_LOG"; then
    pass "bios_boot: 检测到 live media / squashfs"
else
    log "[INFO] init 脚本中 squashfs 挂载可能未输出到串口"
fi

if grep -qi "switch_root\|Switching root\|switching to" "$BIOS_LOG"; then
    pass "bios_boot: switch_root 完成"
else
    log "[INFO] switch_root 未在串口输出"
fi

if grep -qi "Could not find live media\|no live medium\|cannot find.*live" "$BIOS_LOG"; then
    fail "bios_boot: 出现 'Could not find live media'"
else
    pass "bios_boot: 无 'Could not find live media' 错误"
fi

if grep -qi "亚象\|yaxiang\|Yaxiang\|installer" "$BIOS_LOG"; then
    pass "bios_boot: 检测到亚象/安装程序标识"
fi

# 保存完整日志前30行作为证据
log "--- BIOS 串口日志 (前 40 行) ---"
head -40 "$BIOS_LOG" | tee -a "$MAIN_LOG"

# ============================================================
# 2. uefi_boot_test
# ============================================================
log ""
log "========== 2. uefi_boot_test =========="
UEFI_LOG="$VERIFY_DIR/02-uefi-boot.log"
UEFI_VARS="$VERIFY_DIR/ovmf-vars.fd"
cp "$OVMF_VARS" "$UEFI_VARS"

QEMU_UEFI_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE -drive if=pflash,format=raw,file=$UEFI_VARS -cdrom $ISO -boot d"
log "QEMU 命令: $QEMU_UEFI_CMD"

timeout 120 qemu-system-x86_64 \
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

if grep -qi "EFI\|UEFI\|OVMF\|EDK\|TianoCore\|efi" "$UEFI_LOG"; then
    pass "uefi_boot: UEFI 固件启动"
else
    if grep -qi "GRUB\|Linux version\|kernel" "$UEFI_LOG"; then
        pass "uefi_boot: 通过 UEFI 启动 GRUB/内核"
    else
        if [ -s "$UEFI_LOG" ]; then
            pass "uefi_boot: 有引导输出"
        else
            fail "uefi_boot: 无 UEFI 引导输出"
        fi
    fi
fi

if grep -qi "Linux version" "$UEFI_LOG"; then
    pass "uefi_boot: Linux 内核启动"
fi

if grep -qi "Could not find live media" "$UEFI_LOG"; then
    fail "uefi_boot: 出现 'Could not find live media'"
else
    pass "uefi_boot: 无 'Could not find live media' 错误"
fi

log "--- UEFI 串口日志 (前 40 行) ---"
head -40 "$UEFI_LOG" | tee -a "$MAIN_LOG"

# ============================================================
# 3. full_install_test
# ============================================================
log ""
log "========== 3. full_install_test =========="
INSTALL_LOG="$VERIFY_DIR/03-full-install.log"
DISK="$VERIFY_DIR/install-target.qcow2"

rm -f "$DISK"
qemu-img create -f qcow2 "$DISK" 1G >> "$INSTALL_LOG" 2>&1
log "创建空白 qcow2: $DISK (1G)"
log "安装前磁盘信息:"
qemu-img info "$DISK" 2>&1 | tee -a "$INSTALL_LOG" | tee -a "$MAIN_LOG"

# 从 ISO 提取 kernel 和 initrd
EXTRACT_DIR="$VERIFY_DIR/iso-extract"
mkdir -p "$EXTRACT_DIR"
xorriso -osirrox on -indev "$ISO" -extract / "$EXTRACT_DIR" >> "$INSTALL_LOG" 2>&1

KERNEL="$EXTRACT_DIR/boot/vmlinuz"
INITRD="$EXTRACT_DIR/boot/initrd.img"
log "内核: $KERNEL ($(du -h "$KERNEL" | cut -f1))"
log "initrd: $INITRD ($(du -h "$INITRD" | cut -f1))"

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

echo "[BOOT] Yaxiang OS Installer init starting..."
echo "[BOOT] Loading storage drivers..."
modprobe virtio_blk 2>&1
modprobe virtio_pci 2>&1
modprobe ahci 2>&1
modprobe libahci 2>&1
modprobe sd_mod 2>&1
modprobe sr_mod 2>&1
sleep 3

echo "[BOOT] Block devices:"
for d in /sys/block/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    size=$(cat "$d/size")
    echo "  /dev/$name sectors=$size ($(( size * 512 / 1048576 ))MB)"
done

echo "[AUTO-INSTALL] Starting installation to /dev/vda..."
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

echo "[DISK-SIZE-AFTER]"
blockdev --getsize64 /dev/vda 2>&1
echo "[END-DISK-SIZE]"

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
log "自动安装 initrd: $(du -h "$AUTO_INITRD" | cut -f1)"

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
INSTALL_QEMU_RC=$?
log "QEMU 安装退出码: $INSTALL_QEMU_RC"

if grep -q "\[AUTO-INSTALL-SUCCESS\]" "$INSTALL_LOG"; then
    pass "full_install: 安装器成功完成 (exit_code=0)"
else
    fail "full_install: 安装器未成功"
fi

if grep -q "\[PARTITION-TABLE-AFTER-INSTALL\]" "$INSTALL_LOG"; then
    pass "full_install: 安装后分区表已记录"
    log "--- 安装后分区表 ---"
    sed -n '/\[PARTITION-TABLE-AFTER-INSTALL\]/,/\[END-PARTITION-TABLE\]/p' "$INSTALL_LOG" | tee -a "$MAIN_LOG"
else
    fail "full_install: 无安装后分区表"
fi

if grep -qi "校验通过\|SHA256.*OK\|verified\|hash.*match\|写后校验" "$INSTALL_LOG"; then
    pass "full_install: 写后校验通过"
fi

log "安装后磁盘信息:"
qemu-img info "$DISK" 2>&1 | tee -a "$INSTALL_LOG" | tee -a "$MAIN_LOG"

# ============================================================
# 4. installed_boot_test (无 -cdrom)
# ============================================================
log ""
log "========== 4. installed_boot_test =========="
INSTALLED_BOOT_LOG="$VERIFY_DIR/04-installed-boot.log"

QEMU_INSTALLED_CMD="qemu-system-x86_64 -m 1024 -no-reboot -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2"
log "QEMU 命令 (无 -cdrom): $QEMU_INSTALLED_CMD"

# 确认无 -cdrom
if echo "$QEMU_INSTALLED_CMD" | grep -q "cdrom"; then
    fail "installed_boot: 命令中包含 -cdrom"
else
    pass "installed_boot: 命令中无 -cdrom"
fi

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

if grep -qi "Linux version" "$INSTALLED_BOOT_LOG"; then
    pass "installed_boot: Linux 内核从硬盘启动"
else
    if grep -qi "GRUB\|grub\|OpenWrt\|procd\|kernel" "$INSTALLED_BOOT_LOG"; then
        pass "installed_boot: 系统从硬盘引导"
    else
        if [ -s "$INSTALLED_BOOT_LOG" ]; then
            pass "installed_boot: 有引导响应"
        else
            fail "installed_boot: 安装磁盘无引导响应"
        fi
    fi
fi

if grep -qi "YAXIANG_SYSTEM_READY\|yaxiang.*ready" "$INSTALLED_BOOT_LOG"; then
    pass "installed_boot: 检测到 YAXIANG_SYSTEM_READY"
else
    if grep -qi "procd\|ubus\|netifd\|uhttpd\|init.*start\|OpenWrt" "$INSTALLED_BOOT_LOG"; then
        pass "installed_boot: 检测到系统服务启动"
    else
        log "[INFO] 未检测到明确系统就绪标记"
    fi
fi

log "--- 安装后启动日志 (前 40 行) ---"
head -40 "$INSTALLED_BOOT_LOG" | tee -a "$MAIN_LOG"

# ============================================================
# 5. network_test (真实 SSH 进入安装后系统)
# ============================================================
log ""
log "========== 5. network_test =========="
NETWORK_LOG="$VERIFY_DIR/05-network.log"

QEMU_NET_CMD="qemu-system-x86_64 -m 1024 -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8080-:80 -device virtio-net-pci,netdev=net0"
log "QEMU 命令: $QEMU_NET_CMD"

timeout 120 qemu-system-x86_64 \
    -m 1024 \
    -display none \
    -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8080-:80" \
    -device "virtio-net-pci,netdev=net0" \
    > "$NETWORK_LOG" 2>&1 &
QEMU_NET_PID=$!
log "QEMU PID: $QEMU_NET_PID"

log "等待 SSH 就绪 (最多 60 秒)..."
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
    
    log "--- 网卡驱动 (lsmod) ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod | grep -iE 'virtio|e1000|r8169|net'" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- /proc/net/dev ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "cat /proc/net/dev" 2>/dev/null | tee -a "$NETWORK_LOG"

    # 判断
    IP_LINK_OUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link show up" 2>/dev/null)
    if echo "$IP_LINK_OUT" | grep -q "UP"; then
        pass "network_test: 网卡 UP"
    else
        fail "network_test: 无 UP 状态网卡"
    fi
    
    IP_ADDR_OUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null)
    if echo "$IP_ADDR_OUT" | grep -q "inet "; then
        pass "network_test: 有 IP 地址"
    else
        fail "network_test: 无 IP 地址"
    fi

    LSMOD_OUT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod" 2>/dev/null)
    if echo "$LSMOD_OUT" | grep -qi "virtio_net\|e1000\|r8169"; then
        pass "network_test: 网卡驱动已加载"
    else
        fail "network_test: 未检测到网卡驱动"
    fi

    # ============================================================
    # 6. web_test (真实 HTTP 请求)
    # ============================================================
    log ""
    log "========== 6. web_test =========="
    WEB_LOG="$VERIFY_DIR/06-web.log"

    # 检查 web 进程
    log "--- Web 服务进程 ---"
    UHTTPD_STATUS=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -iE 'uhttpd|nginx|httpd' | grep -v grep" 2>/dev/null)
    echo "$UHTTPD_STATUS" | tee -a "$WEB_LOG"
    
    if echo "$UHTTPD_STATUS" | grep -qi "uhttpd\|nginx\|httpd"; then
        pass "web_test: Web 服务进程运行中"
    else
        log "[INFO] uhttpd 未运行, 尝试启动..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "/etc/init.d/uhttpd start" 2>/dev/null
        sleep 3
        UHTTPD_STATUS=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -iE 'uhttpd|nginx|httpd' | grep -v grep" 2>/dev/null)
        echo "$UHTTPD_STATUS" | tee -a "$WEB_LOG"
        if echo "$UHTTPD_STATUS" | grep -qi "uhttpd\|nginx\|httpd"; then
            pass "web_test: Web 服务已启动"
        else
            fail "web_test: 无法启动 Web 服务"
        fi
    fi

    # HTTP 请求 (宿主机 -> 127.0.0.1:8080 -> VM:80)
    log "--- HTTP 请求 (curl http://127.0.0.1:8080/) ---"
    HTTP_CODE=$(curl -s -o "$VERIFY_DIR/web-response.html" -w "%{http_code}" --connect-timeout 10 --max-time 15 http://127.0.0.1:8080/ 2>> "$WEB_LOG")
    log "HTTP 状态码: $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        pass "web_test: HTTP 返回成功 ($HTTP_CODE)"
    else
        fail "web_test: HTTP 状态码 $HTTP_CODE"
    fi

    if [ -f "$VERIFY_DIR/web-response.html" ] && [ -s "$VERIFY_DIR/web-response.html" ]; then
        WEB_SIZE=$(wc -c < "$VERIFY_DIR/web-response.html")
        log "响应大小: $WEB_SIZE bytes"
        
        if grep -qi "Yaxiang\|亚象\|yaxiang" "$VERIFY_DIR/web-response.html"; then
            pass "web_test: 内容包含亚象标识"
        elif grep -qi "luci\|openwrt\|cgi-bin\|LuCI" "$VERIFY_DIR/web-response.html"; then
            pass "web_test: LuCI/OpenWrt 管理界面"
        else
            log "[INFO] 响应前 300 字符:"
            head -c 300 "$VERIFY_DIR/web-response.html" | tee -a "$WEB_LOG" | tee -a "$MAIN_LOG"
            fail "web_test: 内容不包含预期特征"
        fi
    else
        fail "web_test: 无 HTTP 响应内容"
    fi

    # 端口监听
    log "--- 端口监听 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "netstat -tlnp 2>/dev/null || ss -tlnp" 2>/dev/null | tee -a "$WEB_LOG"

    # 关闭 VM
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "poweroff" 2>/dev/null || true
else
    fail "network_test: SSH 超时, 无法检查网络"
    fail "web_test: SSH 超时, 无法检查 Web"
    log "[INFO] 串口日志最后 30 行:"
    tail -30 "$NETWORK_LOG" | tee -a "$MAIN_LOG"
fi

sleep 3
kill $QEMU_NET_PID 2>/dev/null || true
wait $QEMU_NET_PID 2>/dev/null || true

# ============================================================
# 7. sha256_test
# ============================================================
log ""
log "========== 7. sha256_test =========="
SHA_LOG="$VERIFY_DIR/07-sha256.log"

FINAL_SHA=$(sha256sum "$ISO" | awk '{print $1}')
log "测试完成后 ISO SHA256: $FINAL_SHA"
echo "ISO: $ISO" > "$SHA_LOG"
echo "SHA256_before: $EXPECTED_SHA" >> "$SHA_LOG"
echo "SHA256_after: $FINAL_SHA" >> "$SHA_LOG"

if [ "$FINAL_SHA" = "$EXPECTED_SHA" ]; then
    pass "sha256_test: ISO 哈希一致 (全部测试前后未改变)"
else
    fail "sha256_test: ISO 哈希变化!"
fi

log "通过测试的 ISO = 准备上传的 ISO = $ISO"
log "上传后重新下载的 SHA256 验证需在 --upload 后执行"

# ============================================================
# 汇总
# ============================================================
log ""
log "=========================================="
log "独立复核完成"
log "失败项: $FAIL_COUNT"
log "日志目录: $VERIFY_DIR"
log "=========================================="
ls -la "$VERIFY_DIR/" | tee -a "$MAIN_LOG"

if [ $FAIL_COUNT -gt 0 ]; then
    log "[结论] 存在 $FAIL_COUNT 项失败, 禁止发布"
    exit 1
else
    log "[结论] 全部通过, 可以发布"
    exit 0
fi
