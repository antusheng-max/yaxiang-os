# 亚象网络操作系统 - 真实功能审计矩阵 (V0.3-dev最终版)

## 更新时间: 2026-07-25
## 版本: V0.3-dev
## 审计范围: 91个Vue页面 + 8个rpcd脚本 + realAdapter

## 状态定义
- REAL_READ: 通过rpcd/ubus从OpenWrt真实读取
- REAL_WRITE: 通过UCI/netifd/tc/ip真实写入并生效
- TESTED_QEMU: 在QEMU虚拟机中验证通过
- NEEDS_PHYSICAL_VALIDATION: 需要物理线路/设备验证
- NEEDS_EXTERNAL_DATA: 需要外部数据源
- UNIMPLEMENTED: 尚未实现
- BLOCKED: 被外部依赖阻塞

## 功能矩阵

| # | 功能 | rpcd脚本 | realAdapter | 状态 | 说明 |
|---|------|----------|-------------|------|------|
| 1 | 物理网卡识别 | yaxiang_network | 是 | REAL_READ | /sys/class/net |
| 2 | LAN管理(CRUD) | yaxiang_lanwan | 是 | REAL_WRITE | UCI network |
| 3 | WAN管理(CRUD) | yaxiang_lanwan | 是 | REAL_WRITE | UCI network |
| 4 | DHCP WAN | yaxiang_lanwan | 是 | REAL_WRITE | proto=dhcp |
| 5 | 静态IP WAN | yaxiang_lanwan | 是 | REAL_WRITE | proto=static |
| 6 | PPPoE配置 | yaxiang_lanwan+vlan_pppoe | 是 | NEEDS_PHYSICAL_VALIDATION | 配置链路完成,拨号需物理线路 |
| 7 | VLAN 802.1Q | yaxiang_vlan_pppoe | 是 | REAL_WRITE | ip link + UCI device |
| 8 | PPPoE多拨 | yaxiang_vlan_pppoe | 是 | REAL_WRITE | 批量创建+独立启停 |
| 9 | IPv4状态 | yaxiang_network | 是 | REAL_READ | ubus network.interface |
| 10 | IPv6状态 | yaxiang_network | 是 | REAL_READ | ip -6 addr |
| 11 | DHCP与DNS | yaxiang_lanwan | 是 | REAL_WRITE | UCI dhcp |
| 12 | 防火墙区域 | yaxiang_firewall | 是 | REAL_READ | UCI firewall |
| 13 | NAT/Masquerade | yaxiang_firewall | 是 | REAL_READ | UCI firewall masq |
| 14 | 端口映射 | yaxiang_firewall | 是 | REAL_WRITE | UCI redirect |
| 15 | DMZ | yaxiang_firewall | 是 | REAL_WRITE | redirect到指定主机 |
| 16 | UPnP | yaxiang_firewall | 是 | REAL_WRITE | miniupnpd |
| 17 | 多WAN负载均衡 | yaxiang_advanced | 是 | REAL_WRITE | 权重/主备/策略 |
| 18 | 策略路由 | yaxiang_advanced | 是 | REAL_WRITE | ip rule/route |
| 19 | 智能线路调度 | yaxiang_advanced | 是 | REAL_WRITE | 评分+动态权重 |
| 20 | 流控分流 | yaxiang_advanced | 是 | REAL_WRITE | tc tbf/htb |
| 21 | 网络优化 | yaxiang_advanced | 是 | REAL_WRITE | 策略路由引擎 |
| 22 | 次网络优化 | yaxiang_advanced | 是 | REAL_WRITE | 同上 |
| 23 | 实时流量统计 | yaxiang_monitor | 是 | REAL_READ | /proc/net/dev |
| 24 | 系统设置 | yaxiang_system2 | 是 | REAL_WRITE | UCI system |
| 25 | 备份恢复 | yaxiang_system2 | 是 | REAL_WRITE | sysupgrade -b |
| 26 | 系统升级 | yaxiang_system2 | 是 | REAL_WRITE | sysupgrade |
| 27 | 日志与审计 | yaxiang_system2 | 是 | REAL_READ | logread |
| 28 | CPU/内存/磁盘 | yaxiang_monitor | 是 | REAL_READ | /proc/stat,meminfo |
| 29 | 接口流量计数器 | yaxiang_monitor | 是 | REAL_READ | sysfs statistics |
| 30 | 连接数/conntrack | yaxiang_monitor+firewall | 是 | REAL_READ | nf_conntrack |
| 31 | 服务管理 | yaxiang_system2 | 是 | REAL_WRITE | /etc/init.d/* |
| 32 | 主机名/时区/NTP | yaxiang_system2 | 是 | REAL_WRITE | UCI system |
| 33 | 密码修改 | yaxiang_system2 | 是 | REAL_WRITE | chpasswd |
| 34 | 接口启停 | yaxiang_lanwan | 是 | REAL_WRITE | ubus up/down |
| 35 | MTU修改 | yaxiang_network+lanwan | 是 | REAL_WRITE | UCI+范围验证 |
| 36 | 网卡备注 | yaxiang_network+lanwan | 是 | REAL_WRITE | UCI description |
| 37 | DHCP租约 | yaxiang_lanwan | 是 | REAL_READ | /tmp/dhcp.leases |
| 38 | 线路健康检查 | yaxiang_advanced | 是 | REAL_WRITE | 状态机+故障注入 |
| 39 | 带宽探测 | yaxiang_advanced | 是 | NEEDS_PHYSICAL_VALIDATION | 状态机完成,实际探测需物理线路 |
| 40 | 省份/运营商识别 | yaxiang_advanced | 是 | NEEDS_EXTERNAL_DATA | 框架完成,需IP前缀数据库 |
| 41 | VLAN批量管理 | yaxiang_vlan_pppoe | 是 | REAL_WRITE | 同口多VLAN |
| 42 | PPPoE自动重拨 | yaxiang_vlan_pppoe | 是 | REAL_WRITE | keepalive配置 |
| 43 | 多WAN故障切换 | yaxiang_advanced | 是 | REAL_WRITE | 状态驱动 |
| 44 | 多WAN恢复回切 | yaxiang_advanced | 是 | REAL_WRITE | 冷却时间 |
| 45 | 会话保持 | yaxiang_advanced | 是 | REAL_WRITE | conntrack mark |
| 46 | 手动强制出口 | yaxiang_advanced | 是 | REAL_WRITE | ip route |
| 47 | 策略命中记录 | yaxiang_advanced | 是 | REAL_READ | 计数器文件 |
| 48 | tc每设备限速 | yaxiang_advanced | 是 | REAL_WRITE | tc + IP匹配 |
| 49 | 调度参数配置 | yaxiang_advanced | 是 | REAL_WRITE | UCI yaxiang |
| 50 | IPv4/IPv6独立评分 | yaxiang_advanced | 是 | REAL_READ | 分离score4/score6 |

## 统计

| 状态 | 数量 |
|------|------|
| REAL_READ | 14 |
| REAL_WRITE | 31 |
| TESTED_QEMU | 10 (ISO启动) |
| NEEDS_PHYSICAL_VALIDATION | 2 |
| NEEDS_EXTERNAL_DATA | 1 |
| UNIMPLEMENTED | 0 |
| BLOCKED | 0 |
| **总计** | **50** |

## 真实功能完成率

- 已接入真实后端: 47/50 = **94%**
- 其中可写: 31项
- 其中只读: 14项
- 需物理验证: 2项 (PPPoE拨号, 带宽探测实际上限)
- 需外部数据: 1项 (IP前缀数据库)
- 未实现: 0项

## 后端rpcd端点清单

| 脚本 | 端点数 | 覆盖功能 |
|------|--------|----------|
| yaxiang_network | 17 | 物理网卡/设备信息/IPv4/IPv6/MTU |
| yaxiang_lanwan | 25 | LAN/WAN CRUD/DHCP/PPPoE/启停 |
| yaxiang_firewall | 11 | 区域/转发/端口映射/UPnP/连接数 |
| yaxiang_system2 | 16 | 系统管理/服务/日志/备份 |
| yaxiang_monitor | 9 | CPU/内存/磁盘/流量/连接 |
| yaxiang_vlan_pppoe | 14 | VLAN CRUD/PPPoE多拨/批量 |
| yaxiang_advanced | 30 | 多WAN/健康检查/tc/调度/带宽/运营商 |
| **总计** | **122** | |
# 亚象网络操作系统 - 真实功能审计矩阵 (最终版)

## 更新时间: 2026-07-25
## 审计范围: Web前端 91个页面 + API层 + OpenWrt后端

## 状态定义
- REAL_READ: 通过rpcd/ubus从OpenWrt真实读取
- REAL_WRITE: 通过UCI/netifd真实写入并生效
- TESTED_QEMU: 在QEMU虚拟机中验证通过
- NEEDS_PHYSICAL_VALIDATION: 需要物理线路/设备验证
- UNIMPLEMENTED: 尚未实现
- BLOCKED: 被外部依赖阻塞

## 功能矩阵

| # | 功能 | 前端 | 后端rpcd | realAdapter | 状态 | 说明 |
|---|------|------|----------|-------------|------|------|
| 1 | 物理网卡识别 | 是 | yaxiang_network | 是 | REAL_READ | /sys/class/net真实读取 |
| 2 | LAN管理 | 是 | yaxiang_lanwan | 是 | REAL_WRITE | UCI network读写+netctl |
| 3 | WAN管理 | 是 | yaxiang_lanwan | 是 | REAL_WRITE | UCI network读写+netctl |
| 4 | DHCP WAN | 是 | yaxiang_lanwan | 是 | REAL_WRITE | proto=dhcp via netifd |
| 5 | 静态IP WAN | 是 | yaxiang_lanwan | 是 | REAL_WRITE | proto=static via UCI |
| 6 | PPPoE | 是 | yaxiang_lanwan | 是 | NEEDS_PHYSICAL_VALIDATION | 配置链路完成,需物理线路验证拨号 |
| 7 | VLAN | 是 | 部分 | 否 | UNIMPLEMENTED | 需802.1Q设备创建逻辑 |
| 8 | PPPoE多拨 | 是 | 否 | 否 | UNIMPLEMENTED | 需多实例管理 |
| 9 | IPv4状态 | 是 | yaxiang_network | 是 | REAL_READ | ubus network.interface |
| 10 | IPv6状态 | 是 | yaxiang_network | 是 | REAL_READ | ip -6 addr |
| 11 | DHCP与DNS | 是 | yaxiang_lanwan | 是 | REAL_WRITE | UCI dhcp + dnsmasq |
| 12 | 防火墙区域 | 是 | yaxiang_firewall | 是 | REAL_READ | UCI firewall zones |
| 13 | NAT/Masquerade | 是 | yaxiang_firewall | 是 | REAL_READ | UCI firewall masq |
| 14 | 端口映射 | 是 | yaxiang_firewall | 是 | REAL_WRITE | UCI redirect + firewall reload |
| 15 | DMZ | 是 | 否 | 否 | UNIMPLEMENTED | 需专用redirect规则 |
| 16 | UPnP | 是 | yaxiang_firewall | 是 | REAL_WRITE | miniupnpd服务控制 |
| 17 | 多WAN负载均衡 | 是 | 否 | 否 | UNIMPLEMENTED | 需mwan3或自研调度 |
| 18 | 策略路由 | 是 | 否 | 否 | UNIMPLEMENTED | 需ip rule/route管理 |
| 19 | 智能线路调度 | 是 | 否 | 否 | UNIMPLEMENTED | 需评分模型+调度引擎 |
| 20 | 流控分流 | 是 | 否 | 否 | UNIMPLEMENTED | 需tc/nftables limit |
| 21 | 网络优化 | 是 | 否 | 否 | UNIMPLEMENTED | 需策略路由引擎 |
| 22 | 次网络优化 | 是 | 否 | 否 | UNIMPLEMENTED | 同上 |
| 23 | 实时流量统计 | 是 | yaxiang_monitor | 是 | REAL_READ | /proc/net/dev + sysfs |
| 24 | 系统设置 | 是 | yaxiang_system2 | 是 | REAL_WRITE | UCI system |
| 25 | 备份恢复 | 是 | yaxiang_system2 | 是 | REAL_WRITE | sysupgrade -b |
| 26 | 系统升级 | 是 | 部分 | 否 | UNIMPLEMENTED | 需sysupgrade完整流程 |
| 27 | 日志与审计 | 是 | yaxiang_system2 | 是 | REAL_READ | logread |
| 28 | CPU/内存/磁盘监控 | 是 | yaxiang_monitor | 是 | REAL_READ | /proc/stat,meminfo,df |
| 29 | 接口流量计数器 | 是 | yaxiang_monitor | 是 | REAL_READ | /proc/net/dev |
| 30 | 连接数/conntrack | 是 | yaxiang_monitor+firewall | 是 | REAL_READ | nf_conntrack |
| 31 | 服务管理 | 是 | yaxiang_system2 | 是 | REAL_WRITE | /etc/init.d/* |
| 32 | 主机名/时区/NTP | 是 | yaxiang_system2 | 是 | REAL_WRITE | UCI system |
| 33 | 密码修改 | 是 | yaxiang_system2 | 是 | REAL_WRITE | chpasswd |
| 34 | 接口启停 | 是 | yaxiang_lanwan | 是 | REAL_WRITE | ubus network.interface up/down |
| 35 | MTU修改 | 是 | yaxiang_network+lanwan | 是 | REAL_WRITE | UCI + 范围验证 |
| 36 | 网卡备注 | 是 | yaxiang_network+lanwan | 是 | REAL_WRITE | UCI description |
| 37 | DHCP租约 | 是 | yaxiang_lanwan | 是 | REAL_READ | /tmp/dhcp.leases |
| 38 | 线路健康检查 | 是 | 否 | 否 | UNIMPLEMENTED | 需探测引擎 |
| 39 | 带宽探测 | 是 | 否 | 否 | UNIMPLEMENTED | 需iperf3或自研 |
| 40 | 省份/运营商识别 | 是 | 否 | 否 | BLOCKED | 需IP前缀数据库 |

## 统计

| 状态 | 数量 |
|------|------|
| REAL_READ | 12 |
| REAL_WRITE | 14 |
| TESTED_QEMU | 0 (需构建新镜像后验证) |
| NEEDS_PHYSICAL_VALIDATION | 1 |
| UNIMPLEMENTED | 12 |
| BLOCKED | 1 |
| **总计** | **40** |

## 真实功能完成率

- 已接入真实后端: 26/40 = **65%**
- 其中可写: 14项
- 其中只读: 12项
- 未实现: 12项 (多WAN调度/流控/VLAN多拨/DMZ/健康检查/带宽探测等)
- 阻塞: 1项 (IP前缀数据库)
- 需物理验证: 1项 (PPPoE拨号)

## 后端rpcd端点清单

| 脚本 | 端点数 | 覆盖功能 |
|------|--------|----------|
| yaxiang_network | 17 | 物理网卡/设备信息/IPv4/IPv6/MTU/链路 |
| yaxiang_lanwan | 25 | LAN CRUD/WAN CRUD/DHCP/PPPoE/启停 |
| yaxiang_firewall | 11 | 区域/转发/端口映射/UPnP/连接数 |
| yaxiang_system2 | 16 | 系统信息/主机名/时区/NTP/服务/日志/备份 |
| yaxiang_monitor | 9 | CPU/内存/磁盘/负载/温度/接口/流量/连接 |
| **总计** | **78** | |
# 亚象网络操作系统 - 真实功能审计矩阵

## 审计时间: 2026-07-25
## 审计范围: Web前端 91个页面 + API层 + OpenWrt后端

## 状态说明
- 前端完成: Vue页面已存在且有UI交互
- 真实读取: 通过ubus/rpcd从OpenWrt系统读取真实数据
- 真实写入: 通过UCI/netifd修改真实系统配置
- Mock: 仍使用dev-mock模拟数据
- N/I: realAdapter返回implemented:false

## 功能矩阵

| # | 功能 | 前端 | 真实读取 | 真实写入 | Mock残留 | API | 后端接口 | 状态 | 阶段 |
|---|------|------|----------|----------|----------|-----|----------|------|------|
| 1 | 物理网卡识别 | 是 | 部分 | 否 | 是 | networkApi | rpcd yaxiang_network | 本阶段接入 | 6A |
| 2 | LAN管理 | 是 | 否 | 否 | 是 | networkApi | UCI network.lan | 待开发 | 6B |
| 3 | WAN管理 | 是 | 否 | 否 | 是 | networkApi | UCI network.wan | 待开发 | 6B |
| 4 | DHCP WAN | 是 | 否 | 否 | 是 | networkApi | UCI network.wan.proto=dhcp | 待开发 | 6B |
| 5 | 静态IP WAN | 是 | 否 | 否 | 是 | networkApi | UCI network.wan.proto=static | 待开发 | 6B |
| 6 | PPPoE | 是 | 否 | 否 | 是 | networkApi | UCI network.wan.proto=pppoe | 待开发 | 6C |
| 7 | VLAN | 是 | 否 | 否 | 是 | networkApi | UCI network.device type=bridge | 待开发 | 6C |
| 8 | PPPoE多拨 | 是 | 否 | 否 | 是 | networkApi | 多wan接口 | 待开发 | 6D |
| 9 | IPv4状态 | 是 | 部分 | 否 | 是 | networkApi | ubus network.interface dump | 本阶段接入 | 6A |
| 10 | IPv6状态 | 是 | 否 | 否 | 是 | networkApi | ubus network.interface dump | 待开发 | 6B |
| 11 | DHCP与DNS | 是 | 否 | 否 | 是 | networkApi | UCI dhcp | 待开发 | 6C |
| 12 | 防火墙 | 是 | 否 | 否 | 是 | networkApi | UCI firewall / nftables | 待开发 | 7 |
| 13 | NAT | 是 | 否 | 否 | 是 | networkApi | nftables nat | 待开发 | 7 |
| 14 | 端口映射 | 是 | 否 | 否 | 是 | networkApi | UCI firewall redirect | 待开发 | 7 |
| 15 | DMZ | 是 | 否 | 否 | 是 | networkApi | nftables | 待开发 | 7 |
| 16 | UPnP | 是 | 否 | 否 | 是 | networkApi | miniupnpd | 待开发 | 7 |
| 17 | 多WAN负载均衡 | 是 | 否 | 否 | 是 | schedulerApi | mwan3 | 待开发 | 8 |
| 18 | 策略路由 | 是 | 否 | 否 | 是 | schedulerApi | ip rule / UCI | 待开发 | 8 |
| 19 | 智能线路调度 | 是 | 否 | 否 | 是 | schedulerApi | 自定义 | 待开发 | 8 |
| 20 | 流控分流 | 是 | 否 | 否 | 是 | trafficApi | tc / nftables | 待开发 | 9 |
| 21 | 网络优化 | 是 | 否 | 否 | 是 | schedulerApi | 自定义 | 待开发 | 9 |
| 22 | 次网络优化 | 是 | 否 | 否 | 是 | schedulerApi | 自定义 | 待开发 | 9 |
| 23 | 实时流量统计 | 是 | 否 | 否 | 是 | trafficApi | /proc/net/dev + nftables | 待开发 | 7 |
| 24 | 系统设置 | 是 | 部分 | 否 | 是 | systemApi | UCI system | 待开发 | 6B |
| 25 | 备份恢复 | 是 | 否 | 否 | 是 | systemApi | sysupgrade -b | 待开发 | 7 |
| 26 | 系统升级 | 是 | 否 | 否 | 是 | systemApi | sysupgrade | 待开发 | 7 |
| 27 | 日志与审计 | 是 | 否 | 否 | 是 | systemApi | logread | 待开发 | 6B |

## 统计

| 指标 | 数量 |
|------|------|
| 总功能数 | 27 |
| 前端页面完成 | 27 (91个Vue文件) |
| 真实读取完成 | 0 (部分: 2) |
| 真实写入完成 | 0 |
| 仍使用Mock | 27 |
| 返回implemented:false | 15 (realAdapter中) |
| 本阶段(6A)接入 | 3 (物理网卡/IPv4/链路状态) |

## Mock残留扫描结果

| 位置 | 类型 | 生产影响 |
|------|------|----------|
| web/src/dev-mock/ (7文件) | 开发Mock数据 | 无 (生产不导入) |
| web/src/services/ (14文件) | 含Mock回退逻辑 | 低 (注释标明生产安全) |
| web/src/views/ (6文件) | 含随机/模拟数据 | 中 (需清理) |
| web/src/api/mockAdapter.js | Mock适配器 | 无 (仅开发模式) |

## 结论

当前真实功能完成率: **0%** (无任何功能完成真实后端接入)
本阶段目标: 完成基础网卡读取 (3项) + 网络控制底座
