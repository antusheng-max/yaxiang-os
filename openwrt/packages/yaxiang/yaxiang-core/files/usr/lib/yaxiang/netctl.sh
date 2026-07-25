#!/bin/sh
# ============================================================
# 亚象网络操作系统 - 网络控制底座 (netctl)
# 版本: 0.2-dev
# 功能: UCI读取/修改/备份/验证/应用/回滚/锁/日志/dry-run
# 安全: 参数白名单/命令注入防护/权限校验/文件锁
# ============================================================

NETCTL_VERSION="0.2-dev"
NETCTL_LOCK_FILE="/var/lock/yaxiang-netctl.lock"
NETCTL_BACKUP_DIR="/tmp/yaxiang-backup"
NETCTL_LOG_FILE="/var/log/yaxiang/netctl.log"
NETCTL_DRY_RUN="${YAXIANG_NETCTL_DRY_RUN:-0}"

# 参数白名单: 允许的UCI配置名
ALLOWED_CONFIGS="network firewall dhcp system"
# 允许的选项名模式
ALLOWED_OPTIONS_PATTERN="^[a-zA-Z_][a-zA-Z0-9_]*$"
# 允许的值模式 (防注入: 不允许 ; | & $ ` 等)
FORBIDDEN_CHARS=';|&$`\\(){}!><'

# ============================================================
# JSON 响应
# ============================================================

netctl_json_ok() {
    local data="${1:-{}}"
    printf '{"success":true,"data":%s,"error":""}\n' "$data"
}

netctl_json_err() {
    local msg="${1:-unknown error}"
    printf '{"success":false,"data":null,"error":"%s"}\n' "$msg"
}

# ============================================================
# 日志
# ============================================================

netctl_log() {
    local action="$1"
    local detail="$2"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
    mkdir -p "$(dirname "$NETCTL_LOG_FILE")" 2>/dev/null
    echo "[$ts] [$action] $detail" >> "$NETCTL_LOG_FILE" 2>/dev/null
}

# ============================================================
# 文件锁
# ============================================================

netctl_lock() {
    local timeout="${1:-10}"
    local waited=0
    while [ "$waited" -lt "$timeout" ]; do
        if mkdir "$NETCTL_LOCK_FILE" 2>/dev/null; then
            echo $$ > "$NETCTL_LOCK_FILE/pid" 2>/dev/null
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    netctl_log "LOCK_FAIL" "无法获取锁 (等待${timeout}秒)"
    return 1
}

netctl_unlock() {
    rm -rf "$NETCTL_LOCK_FILE" 2>/dev/null
}

# ============================================================
# 权限校验
# ============================================================

netctl_check_permission() {
    # 必须是root或rpcd session
    if [ "$(id -u 2>/dev/null)" != "0" ]; then
        netctl_json_err "权限不足: 需要root权限"
        return 1
    fi
    return 0
}

# ============================================================
# 参数验证 (防注入)
# ============================================================

netctl_validate_param() {
    local param="$1"
    local param_name="$2"

    # 检查空值
    if [ -z "$param" ]; then
        netctl_json_err "参数 ${param_name} 不能为空"
        return 1
    fi

    # 检查非法字符
    case "$param" in
        *";"*|*"|"*|*"&"*|*'$'*|*'`'*|*'\'*|*"("*|*")"*|*"{"*|*"}"*|*"!"*|*">"*|*"<"*)
            netctl_json_err "参数 ${param_name} 包含非法字符"
            netctl_log "INJECT_BLOCK" "参数注入尝试被阻止: ${param_name}=${param}"
            return 1
            ;;
    esac

    # 检查选项名格式
    if ! echo "$param" | grep -qE "$ALLOWED_OPTIONS_PATTERN" 2>/dev/null; then
        netctl_json_err "参数 ${param_name} 格式不合法"
        return 1
    fi

    return 0
}

netctl_validate_config() {
    local config="$1"
    local found=0
    for c in $ALLOWED_CONFIGS; do
        [ "$c" = "$config" ] && found=1 && break
    done
    if [ "$found" -eq 0 ]; then
        netctl_json_err "不允许的配置: $config (允许: $ALLOWED_CONFIGS)"
        return 1
    fi
    return 0
}

# ============================================================
# UCI 读取
# ============================================================

netctl_get() {
    local config="$1"
    local section="$2"
    local option="$3"

    netctl_validate_config "$config" || return 1
    netctl_validate_param "$section" "section" || return 1

    local value
    if [ -n "$option" ]; then
        netctl_validate_param "$option" "option" || return 1
        value=$(uci get "${config}.${section}.${option}" 2>/dev/null)
    else
        value=$(uci get "${config}.${section}" 2>/dev/null)
    fi

    if [ $? -eq 0 ]; then
        netctl_json_ok "{\"value\":\"${value}\"}"
        return 0
    else
        netctl_json_err "配置不存在: ${config}.${section}.${option}"
        return 1
    fi
}

# 获取整个section
netctl_get_section() {
    local config="$1"
    local section="$2"

    netctl_validate_config "$config" || return 1
    netctl_validate_param "$section" "section" || return 1

    local result
    result=$(uci show "${config}.${section}" 2>/dev/null)
    if [ $? -eq 0 ]; then
        # 转换为JSON
        local json="{"
        local first=1
        echo "$result" | while IFS= read -r line; do
            local key val
            key=$(echo "$line" | cut -d= -f1 | sed "s/${config}.${section}.//")
            val=$(echo "$line" | cut -d= -f2- | tr -d "'")
            [ $first -eq 0 ] && json="${json},"
            json="${json}\"${key}\":\"${val}\""
            first=0
        done
        json="${json}}"
        netctl_json_ok "$json"
    else
        netctl_json_err "section不存在: ${config}.${section}"
        return 1
    fi
}

# ============================================================
# 备份
# ============================================================

netctl_backup() {
    local config="$1"
    mkdir -p "$NETCTL_BACKUP_DIR" 2>/dev/null
    local backup_file="${NETCTL_BACKUP_DIR}/${config}.$(date +%s 2>/dev/null || echo 0).bak"
    cp "/etc/config/${config}" "$backup_file" 2>/dev/null
    echo "$backup_file"
    netctl_log "BACKUP" "备份 ${config} -> ${backup_file}"
}

# ============================================================
# UCI 修改
# ============================================================

netctl_set() {
    local config="$1"
    local section="$2"
    local option="$3"
    local value="$4"

    netctl_validate_config "$config" || return 1
    netctl_validate_param "$section" "section" || return 1
    netctl_validate_param "$option" "option" || return 1

    # 值的安全检查
    case "$value" in
        *";"*|*"|"*|*"&"*|*'$'*|*'`'*|*'\'*)
            netctl_json_err "值包含非法字符"
            netctl_log "INJECT_BLOCK" "值注入尝试: ${config}.${section}.${option}=${value}"
            return 1
            ;;
    esac

    # dry-run 模式
    if [ "$NETCTL_DRY_RUN" = "1" ]; then
        netctl_log "DRY_RUN" "set ${config}.${section}.${option}=${value}"
        netctl_json_ok "{\"dry_run\":true,\"action\":\"set\",\"target\":\"${config}.${section}.${option}\",\"value\":\"${value}\"}"
        return 0
    fi

    # 获取锁
    netctl_lock || { netctl_json_err "无法获取配置锁"; return 1; }

    # 备份
    netctl_backup "$config" >/dev/null

    # 执行修改
    uci set "${config}.${section}.${option}=${value}" 2>/dev/null
    if [ $? -ne 0 ]; then
        netctl_unlock
        netctl_json_err "UCI设置失败: ${config}.${section}.${option}"
        return 1
    fi

    uci commit "${config}" 2>/dev/null
    netctl_unlock

    netctl_log "SET" "${config}.${section}.${option}=${value}"
    netctl_json_ok "{\"action\":\"set\",\"target\":\"${config}.${section}.${option}\",\"value\":\"${value}\"}"
    return 0
}

# ============================================================
# 配置验证
# ============================================================

netctl_validate() {
    local config="$1"
    netctl_validate_config "$config" || return 1

    # 使用 uci 验证语法
    if uci changes "${config}" >/dev/null 2>&1; then
        netctl_json_ok "{\"valid\":true}"
        return 0
    else
        netctl_json_err "配置语法错误: ${config}"
        return 1
    fi
}

# ============================================================
# 应用配置
# ============================================================

netctl_apply() {
    local config="${1:-network}"

    if [ "$NETCTL_DRY_RUN" = "1" ]; then
        netctl_log "DRY_RUN" "apply ${config}"
        netctl_json_ok "{\"dry_run\":true,\"action\":\"apply\",\"config\":\"${config}\"}"
        return 0
    fi

    netctl_lock || { netctl_json_err "无法获取配置锁"; return 1; }

    # 备份当前配置
    local backup_file
    backup_file=$(netctl_backup "$config")

    # 应用
    local apply_rc=0
    case "$config" in
        network)
            ubus call network reload 2>/dev/null || /etc/init.d/network reload 2>/dev/null || apply_rc=1
            ;;
        firewall)
            /etc/init.d/firewall reload 2>/dev/null || apply_rc=1
            ;;
        dhcp)
            /etc/init.d/dnsmasq restart 2>/dev/null || apply_rc=1
            ;;
        *)
            /etc/init.d/"$config" reload 2>/dev/null || apply_rc=1
            ;;
    esac

    if [ "$apply_rc" -ne 0 ]; then
        # 自动回滚
        netctl_log "APPLY_FAIL" "应用失败，执行回滚: ${config}"
        netctl_rollback "$config" "$backup_file"
        netctl_unlock
        netctl_json_err "应用失败，已自动回滚"
        return 1
    fi

    netctl_unlock
    netctl_log "APPLY" "配置已应用: ${config}"
    netctl_json_ok "{\"action\":\"apply\",\"config\":\"${config}\"}"
    return 0
}

# ============================================================
# 回滚
# ============================================================

netctl_rollback() {
    local config="$1"
    local backup_file="$2"

    if [ -z "$backup_file" ]; then
        # 找最近的备份
        backup_file=$(ls -t "${NETCTL_BACKUP_DIR}/${config}."*.bak 2>/dev/null | head -1)
    fi

    if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
        netctl_log "ROLLBACK_FAIL" "无可用备份: ${config}"
        return 1
    fi

    cp "$backup_file" "/etc/config/${config}" 2>/dev/null
    netctl_log "ROLLBACK" "已回滚: ${config} <- ${backup_file}"
    return 0
}

# ============================================================
# MTU 修改 (带验证)
# ============================================================

netctl_set_mtu() {
    local interface="$1"
    local mtu="$2"

    netctl_validate_param "$interface" "interface" || return 1

    # MTU 范围验证
    if ! echo "$mtu" | grep -qE '^[0-9]+$' 2>/dev/null; then
        netctl_json_err "MTU必须是数字"
        return 1
    fi
    if [ "$mtu" -lt 576 ] || [ "$mtu" -gt 9000 ]; then
        netctl_json_err "MTU超出范围 (576-9000): ${mtu}"
        return 1
    fi

    # 检查接口存在
    if [ ! -d "/sys/class/net/${interface}" ]; then
        netctl_json_err "接口不存在: ${interface}"
        return 1
    fi

    netctl_set "network" "$interface" "mtu" "$mtu"
}

# ============================================================
# 接口启停
# ============================================================

netctl_set_link_state() {
    local interface="$1"
    local state="$2"  # up / down

    netctl_validate_param "$interface" "interface" || return 1

    if [ "$state" != "up" ] && [ "$state" != "down" ]; then
        netctl_json_err "状态必须是 up 或 down"
        return 1
    fi

    if [ "$NETCTL_DRY_RUN" = "1" ]; then
        netctl_json_ok "{\"dry_run\":true,\"action\":\"link_${state}\",\"interface\":\"${interface}\"}"
        return 0
    fi

    netctl_lock || { netctl_json_err "无法获取配置锁"; return 1; }

    if [ "$state" = "up" ]; then
        ubus call network.interface."$interface" up 2>/dev/null || ifup "$interface" 2>/dev/null
    else
        ubus call network.interface."$interface" down 2>/dev/null || ifdown "$interface" 2>/dev/null
    fi

    netctl_unlock
    netctl_log "LINK" "${interface} -> ${state}"
    netctl_json_ok "{\"action\":\"link_${state}\",\"interface\":\"${interface}\"}"
    return 0
}

# ============================================================
# 导出 (供其他脚本 source)
# ============================================================
# 用法: . /usr/lib/yaxiang/netctl.sh
