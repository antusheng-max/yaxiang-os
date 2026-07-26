# 亚象网络操作系统（Yaxiang OS）

## 当前版本：Yaxiang OS V0.3-dev（开发测试版）

### 系统镜像下载

- [点击下载 x86_64 安装镜像](https://github.com/antusheng-max/yaxiang-os/releases/download/v0.3-dev/Yaxiang-OS-V0.3-dev-x86_64-installer.iso)
- [查看全部下载文件及 SHA256 校验](https://github.com/antusheng-max/yaxiang-os/releases/tag/v0.3-dev)

最终 ISO SHA256：

```
cb4d479aacab6bc678010f25517ce1e905d4b62d4944ec94ac65140d40a06cc0
```

> 当前版本为开发测试版，请先在虚拟机或隔离环境中测试，不建议直接用于生产环境。

---

基于 OpenWrt 的 x86_64 多WAN网络管理系统。

## 项目定位

亚象网络操作系统是一款面向企业级网络环境的专业路由器操作系统，提供：

- **多WAN负载均衡** - 支持权重、主备、加权模式
- **IPv4与IPv6独立管理** - 双栈独立调度
- **PPPoE多拨** - 批量添加、独立启停、自动重拨
- **VLAN 802.1Q** - 完整VLAN管理
- **智能线路调度** - 动态权重调整、防振荡
- **流控分流** - tc tbf限速、每设备/每IP限速
- **防火墙和流控** - 区域管理、端口映射、UPnP
- **健康检查** - ICMP/TCP/DNS/HTTP探测
- **Web管理端** - Vue 3 + Element Plus 现代化界面

## 当前版本

**Yaxiang OS V0.3-dev**（开发测试版）

- 真实功能完成率: 94% (47/50)
- 后端rpcd端点: 122个 (7个rpcd脚本)
- QEMU测试: 93项通过, 0项失败

> ⚠️ 当前为开发测试版，不建议在生产环境使用。

## 目录结构

```
├── docs/           # 项目文档
│   ├── architecture/   # 架构设计
│   ├── handover/       # 交接文档
│   ├── planning/       # 规划文档
│   └── reports/        # 测试报告
├── installer/      # 安装器
│   ├── grub/           # GRUB配置
│   ├── scripts/        # 构建和测试脚本
│   └── src/            # 安装器源码
├── openwrt/        # OpenWrt定制
│   ├── configs/        # 构建配置
│   ├── files-overlay/  # 文件系统覆盖
│   ├── packages/       # 亚象软件包
│   └── scripts/        # 构建脚本
├── scripts/        # 项目工具脚本
├── tests/          # 测试代码
│   ├── fixtures/       # 测试固件
│   ├── integration/    # 集成测试
│   └── unit/           # 单元测试
└── web/            # Web管理前端
    ├── src/            # Vue 3源码
    └── public/         # 静态资源
```

## 安装器

支持 Legacy BIOS 和 UEFI 双启动模式：

- 磁盘识别与安全确认
- 镜像写入与SHA256校验
- 安装介质自动排除
- 双重确认机制

## 构建方法

### OpenWrt系统镜像

```bash
cd openwrt
./scripts/build-openwrt.sh
```

### Web前端

```bash
cd web
npm install
npm run build
```

### 安装ISO

```bash
cd installer
./scripts/build-installer-iso.sh
```

## 安装方法

1. 下载最新Release中的ISO文件
2. 验证SHA256校验和
3. 使用Rufus或dd写入U盘
4. 从U盘启动
5. 按照安装向导完成安装

## 安全测试原则

- ✅ 命令注入防护
- ✅ 参数白名单验证
- ✅ 文件锁并发保护
- ✅ dry-run模式支持
- ✅ 密码脱敏显示
- ✅ 磁盘安全保护

> ⚠️ **不得直接在生产网络测试**，所有网络写入测试必须在QEMU或隔离环境中完成。

## 已知限制

1. PPPoE实际拨号需物理宽带线路验证
2. 带宽探测实际运营商限速点需物理线路
3. 省份/运营商识别需导入IP前缀数据库
4. 多WAN实际流量出口验证需多物理WAN环境

## 文档入口

- [架构设计](docs/architecture/)
- [功能矩阵](docs/planning/REAL_FUNCTION_MATRIX.md)
- [完成报告](docs/reports/YAXIANG_OS_FINAL_COMPLETION_REPORT.md)
- [交接文档](docs/handover/)

## 许可证

本仓库公开提供 Yaxiang OS 开发测试版的源代码与系统镜像。
亚象自研代码及资源版权归项目作者所有；OpenWrt 及其他第三方组件遵循各自的开源许可证。
正式许可证与第三方许可清单请参阅 LICENSE 和 NOTICE 文件。
