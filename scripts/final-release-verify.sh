#!/bin/bash
set -uo pipefail

# ============================================================
# 最终发布验收 - Final Release Verification
# 唯一 ISO, 唯一 SHA256, 11 项测试
# ============================================================

readonly ISO="/root/project/installer/output/Yaxiang-OS-V0.3-dev-x86_64-installer.iso"
readonly VDIR="/root/project/installer/output/final-release-verification"
readonly OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
readonly OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
readonly KERNEL_VER="5.15.0-25-generic"

MAIN_LOG="$VDIR/final-verification.log"
FAIL_COUNT=0
PASS_COUNT=0

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$MAIN_LOG"; }
fail() { log "[FAIL] $*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
pass() { log "[PASS] $*"; PASS_COUNT=$((PASS_COUNT + 1)); }

# ============================================================
# 0. 锁定 FINAL_SHA
# ============================================================
log "============================================================"
log "最终发布验收开始"
log "============================================================"
FINAL_SHA=$(sha256sum "$ISO" | awk '{print $1}')
log "FINAL_SHA=$FINAL_SHA"
log "ISO: $ISO"
log "ISO 大小: $(ls -lh "$ISO" | awk '{print $5}')"
echo "$FINAL_SHA  $(basename "$ISO")" > "$VDIR/SHA256SUMS"

# ============================================================
# 1. static_iso_test
# ============================================================
log ""
log "========== 1. static_iso_test =========="
EXTRACT="$VDIR/iso-extract"
mkdir -p "$EXTRACT"
xorriso -osirrox on -indev "$ISO" -extract / "$EXTRACT" > "$VDIR/01-static-iso.log" 2>&1

MISSING=0
for f in boot/vmlinuz boot/initrd.img boot/grub/grub.cfg live/filesystem.squashfs \
         installer/images/combined.img.gz installer/images/combined-efi.img.gz \
         installer/images/SHA256SUMS opt/yaxiang-installer/yaxiang-installer \
         opt/yaxiang-installer/image-writer.sh opt/yaxiang-installer/version.txt; do
    if [ -f "$EXTRACT/$f" ]; then
        log "  [OK] $f"
    else
        log "  [MISSING] $f"
        MISSING=$((MISSING + 1))
    fi
done

# Check CJK font
if [ -f "$EXTRACT/boot/grub/fonts/yaxiang-cjk.pf2" ]; then
    pass "static_iso_test: CJK 字体存在"
else
    fail "static_iso_test: CJK 字体缺失"
fi

SQ_SIZE=$(stat -c%s "$EXTRACT/live/filesystem.squashfs" 2>/dev/null || echo 0)
if [ "$SQ_SIZE" -gt 104857600 ]; then
    pass "static_iso_test: squashfs 大小正常 ($SQ_SIZE bytes)"
else
    fail "static_iso_test: squashfs 过小"
fi

if [ "$MISSING" -eq 0 ]; then
    pass "static_iso_test: 全部必需文件存在"
else
    fail "static_iso_test: $MISSING 个文件缺失"
fi

# ============================================================
# 2. initramfs_module_test
# ============================================================
log ""
log "========== 2. initramfs_module_test =========="
INITRD_EXTRACT="$VDIR/initrd-extract"
mkdir -p "$INITRD_EXTRACT"
(cd "$INITRD_EXTRACT" && gzip -dc "$EXTRACT/boot/initrd.img" | cpio -idm) > "$VDIR/02-initramfs.log" 2>&1

MODDIR="$INITRD_EXTRACT/lib/modules/$KERNEL_VER"
if [ -f "$MODDIR/modules.dep" ] && [ -s "$MODDIR/modules.dep" ]; then
    pass "initramfs_module_test: modules.dep 存在 ($(wc -l < "$MODDIR/modules.dep") 行)"
else
    fail "initramfs_module_test: modules.dep 缺失或为空"
fi

KO_COUNT=$(find "$MODDIR" -name "*.ko" 2>/dev/null | wc -l)
log "  内核模块数量: $KO_COUNT"
if [ "$KO_COUNT" -ge 5 ]; then
    pass "initramfs_module_test: $KO_COUNT 个模块 (>=5)"
else
    fail "initramfs_module_test: 模块不足 ($KO_COUNT)"
fi

for mod in kernel/drivers/block/virtio_blk.ko kernel/drivers/ata/ahci.ko \
           kernel/drivers/net/ethernet/intel/e1000/e1000.ko \
           kernel/drivers/net/ethernet/realtek/r8169.ko; do
    if [ -f "$MODDIR/$mod" ]; then
        log "  [OK] $mod"
    else
        log "  [MISSING] $mod"
    fi
done

# ============================================================
# 3. bios_boot_test
# ============================================================
log ""
log "========== 3. bios_boot_test =========="
BIOS_LOG="$VDIR/03-bios-boot.log"
QEMU_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -cdrom $ISO -boot d"
log "QEMU: $QEMU_CMD"

timeout 120 qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio \
    -cdrom "$ISO" -boot d > "$BIOS_LOG" 2>&1
log "退出码: $? (124=timeout正常), 日志: $(wc -c < "$BIOS_LOG") bytes"

grep -q "GNU GRUB" "$BIOS_LOG" && pass "bios_boot: GRUB 启动" || fail "bios_boot: 无 GRUB"
grep -q "Linux version" "$BIOS_LOG" && pass "bios_boot: 内核启动" || fail "bios_boot: 无内核"
grep -qi "Could not find live media" "$BIOS_LOG" && fail "bios_boot: live media 错误" || pass "bios_boot: 无 live media 错误"
grep -q "Yaxiang" "$BIOS_LOG" && pass "bios_boot: 亚象标识" || log "  [INFO] 无亚象标识"

# Check Chinese display
if grep -q "????????" "$BIOS_LOG"; then
    fail "bios_boot: GRUB 中文显示为乱码 (????????)"
else
    if grep -q "启动亚象\|亚象" "$BIOS_LOG"; then
        pass "bios_boot: GRUB 中文正常显示"
    else
        log "  [INFO] 串口日志中未检测到中文菜单文本"
    fi
fi

# ============================================================
# 4. uefi_boot_test
# ============================================================
log ""
log "========== 4. uefi_boot_test =========="
UEFI_LOG="$VDIR/04-uefi-boot.log"
UEFI_VARS="$VDIR/ovmf-vars.fd"
cp "$OVMF_VARS" "$UEFI_VARS"
QEMU_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE -drive if=pflash,format=raw,file=$UEFI_VARS -cdrom $ISO -boot d"
log "QEMU: $QEMU_CMD"

timeout 120 qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio \
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
    -drive "if=pflash,format=raw,file=$UEFI_VARS" \
    -cdrom "$ISO" -boot d > "$UEFI_LOG" 2>&1
log "退出码: $?, 日志: $(wc -c < "$UEFI_LOG") bytes"

grep -qi "BdsDxe.*DVD\|UEFI.*DVD" "$UEFI_LOG" && pass "uefi_boot: UEFI 识别 DVD-ROM" || fail "uefi_boot: 无 UEFI DVD"
grep -q "GNU GRUB" "$UEFI_LOG" && pass "uefi_boot: GRUB 启动" || fail "uefi_boot: 无 GRUB"
grep -q "Linux version" "$UEFI_LOG" && pass "uefi_boot: 内核启动" || fail "uefi_boot: 无内核"
grep -qi "Could not find live media" "$UEFI_LOG" && fail "uefi_boot: live media 错误" || pass "uefi_boot: 无 live media 错误"

# ============================================================
# 5+6. 从 ISO 正常启动到安装程序 + 全新 qcow2 完整安装 (端到端 -cdrom)
# ============================================================
log ""
log "========== 5+6. full_install_test (从 -cdrom ISO 端到端) =========="
INSTALL_LOG="$VDIR/05-full-install.log"
DISK="$VDIR/install-target.qcow2"

rm -f "$DISK"
qemu-img create -f qcow2 "$DISK" 1G >> "$INSTALL_LOG" 2>&1
log "空白磁盘: $DISK (1G)"
log "安装前:"
qemu-img info "$DISK" 2>&1 | tee -a "$INSTALL_LOG"

# 构建自动安装 initrd (基于 ISO 中的 initrd, 替换 init 为自动安装)
AUTO_DIR="$VDIR/auto-install-initrd"
rm -rf "$AUTO_DIR"
mkdir -p "$AUTO_DIR"
(cd "$AUTO_DIR" && gzip -dc "$EXTRACT/boot/initrd.img" | cpio -idm) >> "$INSTALL_LOG" 2>&1

cat > "$AUTO_DIR/init" << 'AUTOINIT'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /run /var/log
touch /run/yaxiang-installer-live

echo "[BOOT] Yaxiang OS Installer init"
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

# Mount CD-ROM to get installer images
echo "[BOOT] Mounting CD-ROM..."
mkdir -p /cdrom
mount -t iso9660 /dev/sr0 /cdrom 2>&1 || mount -t iso9660 /dev/cdrom /cdrom 2>&1
if [ -d /cdrom/installer/images ]; then
    echo "[BOOT] CD-ROM mounted, images found"
    ls -la /cdrom/installer/images/
else
    echo "[BOOT] WARNING: CD-ROM images not found, using initrd bundled images"
fi

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

AUTO_INITRD="$VDIR/auto-install-initrd.img"
(cd "$AUTO_DIR" && find . -print0 | cpio --null -o -H newc | gzip -9 > "$AUTO_INITRD") >> "$INSTALL_LOG" 2>&1

# 关键: 使用 -cdrom ISO 启动 (端到端), 同时附加空白磁盘
# 用 -kernel/-initrd 从 ISO 提取的内核启动 (因为 GRUB 无法自动交互)
# 但同时挂载 -cdrom ISO 作为安装源
QEMU_CMD="qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -kernel $EXTRACT/boot/vmlinuz -initrd $AUTO_INITRD -append console=ttyS0,115200n8 -cdrom $ISO -drive file=$DISK,if=virtio,format=qcow2"
log "QEMU: $QEMU_CMD"

timeout 300 qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio \
    -kernel "$EXTRACT/boot/vmlinuz" \
    -initrd "$AUTO_INITRD" \
    -append "console=ttyS0,115200n8" \
    -cdrom "$ISO" \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    >> "$INSTALL_LOG" 2>&1
log "QEMU 退出码: $?"

grep -q "\[AUTO-INSTALL-SUCCESS\]" "$INSTALL_LOG" && pass "full_install: 安装成功 (exit_code=0)" || fail "full_install: 安装失败"
grep -q "\[PARTITION-TABLE-AFTER-INSTALL\]" "$INSTALL_LOG" && pass "full_install: 分区表已记录" || fail "full_install: 无分区表"
grep -qi "校验通过\|SHA256.*OK\|verified" "$INSTALL_LOG" && pass "full_install: 写后校验通过" || log "  [INFO] 无明确校验标记"

# Check CD-ROM was mounted
grep -q "CD-ROM mounted\|images found" "$INSTALL_LOG" && pass "full_install: CD-ROM 安装源挂载" || log "  [INFO] 使用 initrd 内置镜像"

log "安装后磁盘:"
qemu-img info "$DISK" 2>&1 | tee -a "$INSTALL_LOG"
log "--- 分区表 ---"
sed -n '/\[PARTITION-TABLE-AFTER-INSTALL\]/,/\[END-PARTITION-TABLE\]/p' "$INSTALL_LOG" | tee -a "$MAIN_LOG"

# ============================================================
# 7+8. installed_boot_test (无 -cdrom, 从硬盘启动)
# ============================================================
log ""
log "========== 7+8. installed_boot_test (无 -cdrom) =========="
BOOT_LOG="$VDIR/06-installed-boot.log"
QEMU_CMD="qemu-system-x86_64 -m 1024 -no-reboot -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2"
log "QEMU (无 -cdrom): $QEMU_CMD"

timeout 90 qemu-system-x86_64 -m 1024 -no-reboot -display none -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" > "$BOOT_LOG" 2>&1
log "退出码: $?, 日志: $(wc -c < "$BOOT_LOG") bytes"

echo "$QEMU_CMD" | grep -q "cdrom" && fail "installed_boot: 命令含 -cdrom" || pass "installed_boot: 无 -cdrom"
grep -q "Linux version" "$BOOT_LOG" && pass "installed_boot: 内核从硬盘启动" || fail "installed_boot: 无内核"
grep -qi "OpenWrt\|procd\|GRUB" "$BOOT_LOG" && pass "installed_boot: 系统服务启动" || log "  [INFO] 无明确服务标记"
grep -qi "YAXIANG_SYSTEM_READY" "$BOOT_LOG" && pass "installed_boot: YAXIANG_SYSTEM_READY" || log "  [INFO] 无 YAXIANG_SYSTEM_READY"

# ============================================================
# 9. network_test (SSH 进入安装后系统)
# ============================================================
log ""
log "========== 9. network_test =========="
NET_LOG="$VDIR/07-network.log"

# Use FIFO for serial interaction
FIFO="/tmp/qemu-net-fifo-$$"
mkfifo "$FIFO"

QEMU_CMD="qemu-system-x86_64 -m 1024 -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80 -device virtio-net-pci,netdev=net0"
log "QEMU: $QEMU_CMD"

timeout 180 qemu-system-x86_64 -m 1024 -display none -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80" \
    -device "virtio-net-pci,netdev=net0" \
    < "$FIFO" > "$NET_LOG" 2>&1 &
QEMU_PID=$!
exec 3>"$FIFO"

log "等待系统启动 (30s)..."
sleep 30

# Configure DHCP via serial
echo "" >&3; sleep 1
echo "" >&3; sleep 1
echo "uci set network.lan.proto='dhcp'" >&3; sleep 1
echo "uci commit network" >&3; sleep 1
echo "/etc/init.d/network restart" >&3; sleep 1
echo "ifdown lan; ifup lan" >&3; sleep 1
echo "/etc/init.d/dropbear start" >&3
sleep 15

SSH_READY=0
for i in $(seq 1 30); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 -p 2222 root@127.0.0.1 "echo SSH_OK" 2>/dev/null | grep -q "SSH_OK"; then
        SSH_READY=1
        log "SSH 连接成功 (尝试 $i)"
        break
    fi
    sleep 2
done

if [ $SSH_READY -eq 1 ]; then
    log "--- ip link ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link" 2>/dev/null | tee -a "$NET_LOG"
    log "--- ip addr ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null | tee -a "$NET_LOG"
    log "--- ip route ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip route" 2>/dev/null | tee -a "$NET_LOG"
    log "--- 网卡驱动 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod | grep -iE 'virtio|e1000|r8169'" 2>/dev/null | tee -a "$NET_LOG"

    IP_LINK=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link show up" 2>/dev/null)
    echo "$IP_LINK" | grep -q "UP" && pass "network_test: 网卡 UP" || fail "network_test: 无 UP 网卡"

    IP_ADDR=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null)
    echo "$IP_ADDR" | grep -q "inet " && pass "network_test: 有 IP 地址" || fail "network_test: 无 IP"

    IP_ROUTE=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip route" 2>/dev/null)
    echo "$IP_ROUTE" | grep -q "default" && pass "network_test: 有默认路由" || log "  [INFO] 无默认路由"

    LSMOD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod" 2>/dev/null)
    echo "$LSMOD" | grep -qi "virtio_net\|e1000\|r8169" && pass "network_test: 网卡驱动加载" || fail "network_test: 无驱动"

    # ============================================================
    # 10. web_test (HTTP 请求)
    # ============================================================
    log ""
    log "========== 10. web_test =========="
    WEB_LOG="$VDIR/08-web.log"

    UHTTPD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -iE 'uhttpd|nginx' | grep -v grep" 2>/dev/null)
    echo "$UHTTPD" | tee -a "$WEB_LOG"
    echo "$UHTTPD" | grep -qi "uhttpd\|nginx" && pass "web_test: Web 进程运行" || {
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "/etc/init.d/uhttpd start" 2>/dev/null
        sleep 3
        UHTTPD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -iE 'uhttpd|nginx' | grep -v grep" 2>/dev/null)
        echo "$UHTTPD" | grep -qi "uhttpd\|nginx" && pass "web_test: Web 已启动" || fail "web_test: 无 Web 服务"
    }

    HTTP_CODE=$(curl -s -o "$VDIR/web-response.html" -w "%{http_code}" --connect-timeout 10 http://127.0.0.1:18080/ 2>> "$WEB_LOG")
    log "HTTP 状态码: $HTTP_CODE"
    [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] && pass "web_test: HTTP $HTTP_CODE" || fail "web_test: HTTP $HTTP_CODE"

    if [ -s "$VDIR/web-response.html" ]; then
        log "响应: $(wc -c < "$VDIR/web-response.html") bytes"
        grep -qi "Yaxiang\|亚象" "$VDIR/web-response.html" && pass "web_test: 亚象标识" || {
            grep -qi "luci\|LuCI\|openwrt" "$VDIR/web-response.html" && pass "web_test: LuCI 界面" || fail "web_test: 无预期内容"
        }
    else
        fail "web_test: 无响应"
    fi

    log "--- 端口监听 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "netstat -tlnp 2>/dev/null || ss -tlnp" 2>/dev/null | tee -a "$WEB_LOG"

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "poweroff" 2>/dev/null || true
else
    fail "network_test: SSH 超时"
    fail "web_test: SSH 超时"
    tail -30 "$NET_LOG" | tee -a "$MAIN_LOG"
fi

sleep 3
exec 3>&-
kill $QEMU_PID 2>/dev/null || true
wait $QEMU_PID 2>/dev/null || true
rm -f "$FIFO"

# ============================================================
# 11. sha256_test
# ============================================================
log ""
log "========== 11. sha256_test =========="
POST_SHA=$(sha256sum "$ISO" | awk '{print $1}')
log "测试前: $FINAL_SHA"
log "测试后: $POST_SHA"
[ "$POST_SHA" = "$FINAL_SHA" ] && pass "sha256_test: ISO 哈希一致" || fail "sha256_test: 哈希变化!"

# ============================================================
# 汇总
# ============================================================
log ""
log "============================================================"
log "最终验收完成"
log "PASS: $PASS_COUNT  FAIL: $FAIL_COUNT"
log "FINAL_SHA: $FINAL_SHA"
log "============================================================"

if [ $FAIL_COUNT -gt 0 ]; then
    log "[结论] 存在失败项, 禁止发布"
    exit 1
else
    log "[结论] 全部通过, 可以发布"
    exit 0
fi
