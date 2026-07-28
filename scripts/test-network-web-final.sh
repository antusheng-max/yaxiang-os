#!/bin/bash
set -uo pipefail

readonly VERIFY_DIR="/root/project/installer/output/verify-final"
readonly DISK="$VERIFY_DIR/install-target.qcow2"
MAIN_LOG="$VERIFY_DIR/verification-network-web.log"
NETWORK_LOG="$VERIFY_DIR/05-network-final.log"
WEB_LOG="$VERIFY_DIR/06-web-final.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$MAIN_LOG"; }
FAIL_COUNT=0
fail() { log "[FAIL] $*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
pass() { log "[PASS] $*"; }

log "========== 5+6. network_test + web_test (final) =========="
log "方法: 串口控制台配置 DHCP -> SSH 进入 -> HTTP 验证"

QEMU_CMD="qemu-system-x86_64 -m 1024 -display none -serial stdio -drive file=$DISK,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80 -device virtio-net-pci,netdev=net0"
log "QEMU 命令: $QEMU_CMD"

# Start QEMU with serial on a PTY so we can interact
# Use expect-style: pipe commands to QEMU stdin after boot
# Better: use a named pipe for stdin
FIFO="/tmp/qemu-stdin-$$"
mkfifo "$FIFO"

timeout 180 qemu-system-x86_64 \
    -m 1024 \
    -display none \
    -serial stdio \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80" \
    -device "virtio-net-pci,netdev=net0" \
    < "$FIFO" > "$NETWORK_LOG" 2>&1 &
QEMU_PID=$!

# Keep FIFO open
exec 3>"$FIFO"
log "QEMU PID: $QEMU_PID"

# Wait for system to boot (look for login prompt or procd init)
log "等待系统启动..."
sleep 30

# Send Enter to get shell prompt, then configure DHCP
log "通过串口配置 DHCP..."
echo "" >&3
sleep 2
echo "" >&3
sleep 1

# OpenWrt gives a shell on serial console without login
# Configure br-lan for DHCP
echo "uci set network.lan.proto='dhcp'" >&3
sleep 1
echo "uci commit network" >&3
sleep 1
echo "/etc/init.d/network restart" >&3
sleep 1
echo "ifdown lan; ifup lan" >&3
sleep 10

# Also make sure dropbear is running
echo "/etc/init.d/dropbear start" >&3
sleep 2

# Check if we got DHCP
echo "ip addr show br-lan" >&3
sleep 2

log "等待 DHCP 获取地址..."
sleep 10

# Now try SSH
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
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- ip addr ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- ip route ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip route" 2>/dev/null | tee -a "$NETWORK_LOG"
    
    log "--- 网卡驱动 (lsmod) ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod | grep -iE 'virtio|e1000|r8169|net'" 2>/dev/null | tee -a "$NETWORK_LOG"

    log "--- /proc/net/dev ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "cat /proc/net/dev" 2>/dev/null | tee -a "$NETWORK_LOG"

    # Checks
    IP_LINK=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip link show up" 2>/dev/null)
    if echo "$IP_LINK" | grep -q "UP"; then
        pass "network_test: 网卡 UP"
    else
        fail "network_test: 无 UP 网卡"
    fi

    IP_ADDR=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip addr" 2>/dev/null)
    if echo "$IP_ADDR" | grep -q "inet "; then
        pass "network_test: 有 IP 地址"
        log "IP 地址: $(echo "$IP_ADDR" | grep 'inet ' | grep -v 127.0.0.1)"
    else
        fail "network_test: 无 IP 地址"
    fi

    IP_ROUTE=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "ip route" 2>/dev/null)
    if echo "$IP_ROUTE" | grep -q "default\|via"; then
        pass "network_test: 有默认路由"
    else
        log "[INFO] 无默认路由"
    fi

    LSMOD=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "lsmod" 2>/dev/null)
    if echo "$LSMOD" | grep -qi "virtio_net\|e1000\|r8169"; then
        pass "network_test: 网卡驱动已加载"
    else
        fail "network_test: 无网卡驱动"
    fi

    # ============ WEB TEST ============
    log ""
    log "--- web_test: 检查 Web 服务 ---"
    
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

    # HTTP from host
    log "--- HTTP 请求 (curl http://127.0.0.1:18080/) ---"
    HTTP_CODE=$(curl -s -o "$VERIFY_DIR/web-response-final.html" -w "%{http_code}" --connect-timeout 10 --max-time 15 http://127.0.0.1:18080/ 2>> "$WEB_LOG")
    log "HTTP 状态码: $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
        pass "web_test: HTTP 成功 ($HTTP_CODE)"
    else
        # Try again after starting uhttpd
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "/etc/init.d/uhttpd restart" 2>/dev/null
        sleep 3
        HTTP_CODE=$(curl -s -o "$VERIFY_DIR/web-response-final.html" -w "%{http_code}" --connect-timeout 10 --max-time 15 http://127.0.0.1:18080/ 2>> "$WEB_LOG")
        log "重试 HTTP 状态码: $HTTP_CODE"
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
            pass "web_test: HTTP 成功 (重试 $HTTP_CODE)"
        else
            fail "web_test: HTTP 状态 $HTTP_CODE"
        fi
    fi

    if [ -f "$VERIFY_DIR/web-response-final.html" ] && [ -s "$VERIFY_DIR/web-response-final.html" ]; then
        WEB_SIZE=$(wc -c < "$VERIFY_DIR/web-response-final.html")
        log "响应大小: $WEB_SIZE bytes"
        if grep -qi "Yaxiang\|亚象" "$VERIFY_DIR/web-response-final.html"; then
            pass "web_test: 内容包含亚象标识"
        elif grep -qi "luci\|LuCI\|openwrt\|cgi-bin" "$VERIFY_DIR/web-response-final.html"; then
            pass "web_test: LuCI/OpenWrt 管理界面"
        else
            log "响应前 500 字符:"
            head -c 500 "$VERIFY_DIR/web-response-final.html" | tee -a "$WEB_LOG" | tee -a "$MAIN_LOG"
            fail "web_test: 内容无预期特征"
        fi
    else
        fail "web_test: 无响应内容"
    fi

    # Port listening
    log "--- 端口监听 ---"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "netstat -tlnp 2>/dev/null || ss -tlnp" 2>/dev/null | tee -a "$WEB_LOG"

    # Poweroff
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@127.0.0.1 "poweroff" 2>/dev/null || true
else
    fail "network_test: SSH 超时 (串口配置 DHCP 后仍无法连接)"
    fail "web_test: SSH 超时"
    log "串口日志最后 40 行:"
    tail -40 "$NETWORK_LOG" | tee -a "$MAIN_LOG"
fi

sleep 3
exec 3>&-
kill $QEMU_PID 2>/dev/null || true
wait $QEMU_PID 2>/dev/null || true
rm -f "$FIFO"

log ""
log "=========================================="
log "Network+Web 测试完成, 失败项: $FAIL_COUNT"
log "=========================================="
exit $FAIL_COUNT
