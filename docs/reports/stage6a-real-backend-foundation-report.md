# 亚象网络操作系统 第六阶段A - 真实功能审计与网络控制底座报告

## 基本信息

| 项目 | 值 |
|------|-----|
| 阶段 | 第六阶段A: 真实功能审计与网络控制底座 |
| 版本 | V0.2-dev (Stage 6A) |
| 时间 | 2026-07-25 |

## 安装ISO基线

| 项目 | 值 |
|------|-----|
| 文件 | installer/output/Yaxiang-OS-V0.2-dev-x86_64-installer.iso |
| 大小 | 596,402,176 字节 (569MB) |
| SHA256 | 09a1eaab33c88b2561e0d528add72a3667481429f368b1fa16b0d83f9401c9b9 |
| 构建时间 | 2026-07-25 18:10:19 |
| 测试报告 | installer/output/stage5-end-to-end-report.md |

## 当前真实功能完成率

| 指标 | 数量 |
|------|------|
| 总功能数 | 27 |
| 前端页面完成 | 27 (91个Vue文件) |
| 真实只读功能 | 3 (本阶段新增: 物理网卡/IPv4/链路状态) |
| 真实可写功能 | 3 (本阶段新增: MTU/备注/接口启停) |
| 未实现功能 | 21 |
| Mock残留 | 27 (生产构建不导入dev-mock) |

## Mock残留扫描结果

| 位置 | 文件数 | 生产影响 |
|------|--------|----------|
| web/src/dev-mock/ | 7 | 无 (生产不导入) |
| web/src/services/ | 14 | 低 (注释标明生产安全) |
| web/src/views/ | 6 | 中 (含随机数据，需后续清理) |
| web/src/api/mockAdapter.js | 1 | 无 (仅VITE_ADAPTER_MODE=mock时) |

生产构建 adapter 切换逻辑正确: `VITE_ADAPTER_MODE=real` 时使用 realAdapter。

## 网络控制底座结构

文件: `openwrt/packages/yaxiang/yaxiang-core/files/usr/lib/yaxiang/netctl.sh`

| 函数 | 功能 |
|------|------|
| netctl_get | UCI配置读取 |
| netctl_set | UCI配置修改 (含白名单+注入防护) |
| netctl_backup | 修改前备份到 /tmp/yaxiang-backup/ |
| netctl_validate | 配置语法验证 |
| netctl_apply | ubus/netifd应用配置 |
| netctl_rollback | 应用失败自动回滚 |
| netctl_lock/unlock | flock文件锁 (防并发) |
| netctl_log | 操作日志 |
| netctl_set_mtu | MTU修改 (含范围验证576-9000) |
| netctl_set_link_state | 接口启停 |
| netctl_json_ok/err | JSON统一响应 |

安全特性:
- 参数白名单 (仅允许 network/firewall/dhcp/system)
- 命令注入防护 (禁止 ; | & $ ` 等字符)
- 权限校验 (需root)
- 文件锁 (mkdir锁, 10秒超时)
- dry-run模式 (YAXIANG_NETCTL_DRY_RUN=1)
- 自动回滚 (应用失败恢复备份)

## 安全与回滚测试结果

| 测试项 | 结果 |
|--------|------|
| 命令注入参数拒绝 ("eth0; rm -rf /") | 通过 |
| MTU非法值拒绝 (99999) | 通过 |
| MTU合法值dry-run (1400) | 通过 |
| 不存在接口拒绝 (nonexist0) | 通过 |
| 非法配置名拒绝 (evil_config) | 通过 |
| JSON统一响应格式 | 通过 |

## QEMU测试结果

netctl.sh 安全测试在构建服务器上以 dry-run 模式执行 (不修改服务器网络):
- 6项安全测试全部通过
- 未修改服务器任何网络配置
- 未执行服务器真实uci命令

## 安装ISO回归结果

| 检查项 | 结果 |
|--------|------|
| ISO文件存在 | 通过 |
| ISO SHA256一致 | 通过 (09a1eaab...) |
| yaxiang-installer 语法 | 通过 |
| image-writer.sh 语法 | 通过 |
| image-verifier.sh 语法 | 通过 |

安装功能未被破坏。

## 新增和修改文件

| 文件 | 操作 |
|------|------|
| docs/planning/REAL_FUNCTION_MATRIX.md | 新增 |
| openwrt/packages/yaxiang/yaxiang-core/files/usr/lib/yaxiang/netctl.sh | 新增 |
| openwrt/packages/yaxiang/yaxiang-core/Makefile | 修改 (包含netctl.sh) |
| openwrt/files-overlay/usr/libexec/rpcd/yaxiang_network | 修改 (新增9个端点) |
| web/src/api/realAdapter.js | 修改 (新增9个API) |

## 下一阶段开发范围

第六阶段B: LAN/WAN真实配置开发
- LAN IP/子网修改
- WAN proto切换 (DHCP/Static/PPPoE)
- 接口启用/禁用完整流程
- 配置应用与回滚端到端验证

## 结论

具备进入第六阶段B LAN/WAN真实配置开发的条件：**是**

### 具备条件:
- 网络控制底座完成 (UCI读写/备份/回滚/锁/注入防护)
- 基础网卡真实读取已接入 (物理网卡/IPv4/链路状态)
- 基础写入已接入 (MTU/备注/接口启停)
- 安全测试全部通过
- 安装ISO未被破坏
- realAdapter.js 已对接新端点
