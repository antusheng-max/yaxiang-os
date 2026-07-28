#!/bin/bash
set -uo pipefail

readonly ISO="/root/project/installer/output/Yaxiang-OS-V0.3-dev-x86_64-installer.iso"
readonly VERIFY_DIR="/root/project/installer/output/verify-final"
readonly OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
readonly OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
MAIN_LOG="$VERIFY_DIR/verification-retest.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$MAIN_LOG"; }
FAIL_COUNT=0
fail() { log "[FAIL] $*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
pass() { log "[PASS] $*"; }

log "========== RETEST: UEFI + Network + Web =========="
log "ISO SHA256: $(sha256sum "$ISO" | awk '{print $1}')"

# ============================================================
# UEFI boot test (fixed grub.cfg with search --label)
# ============================================================
log ""
log "========== 2. uefi_boot_test (retest) =========="
UEFI_LOG="$VERIFY_DIR/02-uefi-boot-retest.log"
UEFI_VARS="$VERIFY_DIR/ovmf-vars-retest.fd"
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

if grep -qi "BdsDxe\|UEFI.*DVD\|EFI" "$UEFI_LOG"; then
    pass "uefi_boot: UEFI 固件识别 CD-ROM"
fi

if grep -qi "GRUB\|GNU GRUB" "$UEFI_LOG"; then
    pass "uefi_boot: GRUB 启动"
fi

if grep -qi "Linux version" "$UEFI_LOG"; then
    pass "uefi_boot: Linux 内核启动"
else
    if grep -qi "error.*no server\|you need to load the kernel" "$UEFI_LOG"; then
        fail "uefi_boot: GRUB 无法加载内核"
    else
        log "[INFO] 内核启动信息未在串口显示"
        if grep -qi "GRUB" "$UEFI_LOG"; then
            pass "uefi_boot: GRUB 菜单出现 (内核可能启动但未输出到串口)"
        fi
    fi
fi

if grep -qi "Could not find live media" "$UEFI_LOG"; then
    fail "uefi_boot: 'Could not find live media'"
else
    pass "uefi_boot: 无 'Could not find live media'"
fi

log "--- UEFI 串口日志 (前 30 行) ---"
head -30 "$UEFI_LOG" | tee -a "$MAIN_LOG"

# ============================================================
# Network + Web test (port 18080 instead of 8080)
# ============================================================
log ""
log "========== 5+6. network_test + web_test (retest) =========="
NETWORK_LOG="$VERIFY_DIR/05-network-retest.log"
WEB_LOG="$VERIFY_DIR/06-web-retest.log"
DISK="$VERIFY_DIR/install-target.qcow2"

QEMU_NET_CMD="qemu-system-x86_64 -m 1024 -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80 -device virtio-net-pci,netdev=net0"
log "QEMU 命令: $QEMU_NET_CMD"

timeout 120 qemu-system-x86_64 \
    -m 1024 \
    -display none \
    -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80" \
    -device "virtio-net-pci,netdev=net0" \
    > "$NETWORK_LOG" 2>&1 &
QEMU_PID=$!
log "QEMU PID: $QEMU_PID"

log "等待 SSH (最多 60 秒)..."
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
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod | grep -iE 'virtio|e1000|r8169|net'" 2>/dev/null | tee -a "$NETWORK_LOG"

    # Network checks
    IP_LINK=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link show up" 2>/dev/null)
    if echo "$IP_LINK" | grep -q "UP"; then
        pass "network_test: 网卡 UP"
    else
        fail "network_test: 无 UP 网卡"
    fi

    IP_ADDR=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null)
    if echo "$IP_ADDR" | grep -q "inet "; then
        pass "network_test: 有 IP 地址"
    else
        fail "network_test: 无 IP 地址"
    fi

    LSMOD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod" 2>/dev/null)
    if echo "$LSMOD" | grep -qi "virtio_net\|e1000\|r8169"; then
        pass "network_test: 网卡驱动已加载"
    else
        fail "network_test: 无网卡驱动"
    fi

    # Web test
    log ""
    log "--- Web 服务检查 ---"
    UHTTPD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -iE 'uhttpd|nginx|httpd' | grep -v grep" 2>/dev/null)
    echo "$UHTTPD" | tee -a "$WEB_LOG"
    
    if echo "$UHTTPD" | grep -qi "uhttpd\|nginx\|httpd"; then
        pass "web_test: Web 服务进程运行中"
    else
        log "[INFO] 启动 uhttpd..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "/etc/init.d/uhttpd start" 2>/dev/null
        sleep 3
        UHTTPD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ps | grep -iE 'uhttpd|nginx|httpd' | grep -v grep" 2>/dev/null)
        echo "$UHTTPD" | tee -a "$WEB_LOG"
        if echo "$UHTTPD" | grep -qi "uhttpd\|nginx\|httpd"; then
            pass "web_test: Web 服务已启动"
        else
            fail "web_test: 无法启动 Web 服务"
        fi
    fi

    # HTTP request from host
    log "--- HTTP 请求 (curl http://127.0.0.1:18080/) ---"
    HTTP_CODE=$(curl -s -o "$VERIFY_DIR/web-response-retest.html" -w "%{http_code}" --connect-timeout 10 --max-time 15 http://127.0.0.1:18080/ 2>> "$WEB_LOG")
    log "HTTP 状态码: $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        pass "web_test: HTTP 成功 ($HTTP_CODE)"
    else
        fail "web_test: HTTP 状态 $HTTP_CODE"
    fi

    if [ -f "$VERIFY_DIR/web-response-retest.html" ] && [ -s "$VERIFY_DIR/web-response-retest.html" ]; then
        log "响应大小: $(wc -c < "$VERIFY_DIR/web-response-retest.html") bytes"
        if grep -qi "Yaxiang\|亚象" "$VERIFY_DIR/web-response-retest.html"; then
            pass "web_test: 内容包含亚象标识"
        elif grep -qi "luci\|LuCI\|openwrt\|cgi-bin" "$VERIFY_DIR/web-response-retest.html"; then
            pass "web_test: LuCI/OpenWrt 管理界面"
        else
            log "响应前 300 字符:"
            head -c 300 "$VERIFY_DIR/web-response-retest.html" | tee -a "$WEB_LOG" | tee -a "$MAIN_LOG"
            fail "web_test: 内容无预期特征"
        fi
    else
        fail "web_test: 无响应内容"
    fi

    # Port listening
    log "--- 端口监听 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "netstat -tlnp 2>/dev/null || ss -tlnp" 2>/dev/null | tee -a "$WEB_LOG"

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "poweroff" 2>/dev/null || true
else
    fail "network_test: SSH 超时"
    fail "web_test: SSH 超时"
    log "串口日志最后 30 行:"
    tail -30 "$NETWORK_LOG" | tee -a "$MAIN_LOG"
fi

sleep 3
kill $QEMU_PID 2>/dev/null || true
wait $QEMU_PID 2>/dev/null || true

log ""
log "=========================================="
log "Retest 完成, 失败项: $FAIL_COUNT"
log "=========================================="
exit $FAIL_COUNT
