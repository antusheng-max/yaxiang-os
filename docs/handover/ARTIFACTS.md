# 构建产物

## V0.3-dev 最终交付

### 安装ISO
| 文件 | 大小 | SHA256 |
|------|------|--------|
| installer/output/Yaxiang-OS-V0.3-dev-x86_64-installer.iso | 572MB | 24069c88135c90d4... |

### 系统镜像
| 文件 | SHA256 |
|------|--------|
| openwrt/output/v0.3-dev/Yaxiang-OS-V0.3-dev-x86_64-combined.img.gz | 59065ebe1f01cca9... |
| openwrt/output/v0.3-dev/Yaxiang-OS-V0.3-dev-x86_64-combined-efi.img.gz | de0a5a2558d16ab9... |

### 后端rpcd脚本 (7个, 122端点)
| 文件 | 端点 | 功能 |
|------|------|------|
| yaxiang_network | 17 | 物理网卡/IPv4/IPv6/MTU |
| yaxiang_lanwan | 25 | LAN/WAN CRUD |
| yaxiang_firewall | 11 | 防火墙/NAT/UPnP |
| yaxiang_system2 | 16 | 系统管理 |
| yaxiang_monitor | 9 | 实时监控 |
| yaxiang_vlan_pppoe | 14 | VLAN/PPPoE多拨 |
| yaxiang_advanced | 30 | 多WAN/健康检查/tc/调度/带宽/运营商 |

### 核心模块
| 文件 | 用途 |
|------|------|
| openwrt/packages/yaxiang/yaxiang-core/files/usr/lib/yaxiang/netctl.sh | 网络控制底座 |
| web/src/api/realAdapter.js | 前端真实API适配 |
| web/dist/ | 生产构建产物 |

### 报告
| 文件 | 用途 |
|------|------|
| docs/reports/YAXIANG_OS_FINAL_COMPLETION_REPORT.md | 最终报告 |
| docs/planning/REAL_FUNCTION_MATRIX.md | 功能矩阵(50项) |
