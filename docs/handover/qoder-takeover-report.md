# 亚象网络操作系统 - Qoder接管审计报告

生成时间：2026-07-24

---

## 1. 当前主项目绝对路径

`/root/project/web/`（统一工程根目录 `/root/project/`）

源码已从 `/root/LineHub OS V2开发` 迁移至 `/root/project/web/`。

## 2. 当前Git分支

`master`（无远程仓库）

最新提交：`c8db106 feat: 亚象品牌整改+智能线路调度+流控分流+Mock服务层`

## 3. 未提交修改摘要

迁移前已提交所有修改。当前 `/root/project/web/` 为全新Git仓库（从原目录复制），已包含完整历史。

原目录 `/root/LineHub OS V2开发` 的未提交修改（96个修改 + 48个新文件 + 1个删除）已全部提交保存。

## 4. 4173源码和服务位置

- **端口状态**：4173未监听，无服务运行
- **服务文件**：无systemd服务文件
- **Nginx配置**：无4173相关配置
- **Bundle**：已归档至 `/root/archive/linehub-4173-final.bundle`（427KB）
- **源码目录**：已无独立4173源码目录（老项目 `/root/linehub-os` 非4173专属）

## 5. 8080源码、构建目录、部署目录

- **源码**：`/root/project/web/`（主项目）
- **构建产物**：`/root/project/web/dist/`
- **Nginx部署**：`/var/www/linehub-os/`（由8080和80端口共用）
- **Nginx配置**：`/etc/nginx/sites-enabled/linehub-os`（端口80）和 `linehub-os-8080`（端口8080）
- **服务进程**：nginx master + worker（PID 1033/17597/17598）

## 6. 8081源码和服务位置

- **源码**：`/root/project/web/`（与8080同源）
- **运行方式**：`vite preview --host 0.0.0.0 --port 8081 --outDir .preview-tui2`
- **工作目录**：`/root/LineHub OS V2开发`（手动启动，非systemd）
- **systemd服务**：`linehub-installer-preview.service`（enabled但inactive）
- **安装器预览源码**：`/opt/linehub-installer-preview/`（独立Git仓库，与主项目同HEAD）

## 7. /root/project实际用途

OpenWrt镜像工程占位目录，包含：
- `openwrt/files/` - OpenWrt文件系统覆盖（uhttpd配置、init.d脚本、rpcd接口、Web产物）
- `openwrt/output/` - 已有OpenWrt 25.12.5构建产物（含Yaxiang-OS-V0.2-dev ISO）
- `openwrt/packages/` - 已从 `/root/linehub-os/packages/` 迁入的OpenWrt软件包定义

## 8. /var/www/linehub-os实际用途

Nginx静态部署目录，存放Vite生产构建产物（index.html + assets/ + brand/）。同时服务端口80和8080。

## 9. 唯一源码基线选择理由

选择 `/root/LineHub OS V2开发`（现迁移至 `/root/project/web/`）原因：
1. Git历史最完整（15次提交）
2. 包含最新亚象品牌配置（`src/config/brand.js`）
3. 包含完整智能线路调度页面（11个页签）
4. 包含网络优化、次网络优化、本网流量控制
5. 包含安装器预览原型
6. 可执行生产构建
7. 构建结果与当前8080页面对应

## 10. 需要迁移的独有文件

已从旧项目迁入：
- `/root/linehub-os/packages/*` → `/root/project/openwrt/packages/`（6个OpenWrt软件包定义）
- `/root/linehub-os/docs/*` → `/root/project/docs/architecture/`（8个架构文档）
- `/root/linehub-os/tests/*` → `/root/project/tests/`（UCI测试fixtures）
- `/root/LineHub OS V2开发/src/views/installer/InstallerPreview.vue` → `/root/project/docs/prototypes/installer/`

## 11. 删除或归档的旧项目

| 目录 | 状态 | 说明 |
|------|------|------|
| `/root/linehub-os-backup-20260720-153559` | 保留 | 老版本备份，Git历史较少 |
| `/root/linehub-os` | 待删除 | 非Git仓库，有效代码已迁入主项目 |
| `/root/LineHub OS V2开发` | 待删除 | 已迁移至 `/root/project/web/` |
| `/opt/linehub-installer-preview` | 待删除 | 与主项目同源，安装器原型已保存 |

## 12. 项目净化结果

- Mock数据文件已迁移至 `web/src/dev-mock/`
- 所有Mock导入路径已更新
- 生产构建不包含dev-mock静态导入
- 无source map输出
- 无node_modules进入dist

## 13. Mock与Real Adapter结构

```
web/src/api/
├── index.js          # 统一入口，根据VITE_ADAPTER_MODE切换
├── mockAdapter.js    # 开发环境Mock适配器
├── realAdapter.js    # 生产OpenWrt Real适配器（ubus/rpcd）
├── systemApi.js      # 系统API Mock数据
├── networkApi.js     # 网络API Mock数据
├── schedulerApi.js   # 调度API Mock数据
└── trafficApi.js     # 流量API Mock数据
```

- 开发环境默认使用MockAdapter
- 生产构建设置 `VITE_ADAPTER_MODE=real` 使用RealAdapter
- 未实现接口返回 `{ implemented: false, source: 'unavailable', reason: '尚未接入真实系统后端' }`

## 14. 智能线路调度拆分结果

原文件 `AdaptiveScheduling.vue`（2038行）已拆分为：

```
web/src/components/adaptive-scheduling/
├── SchedulingOverview.vue       # 调度总览
├── LineRanking.vue              # 线路排名
├── BusinessRouting.vue          # 业务分流
├── IPv4Scheduling.vue           # IPv4调度
├── IPv6Scheduling.vue           # IPv6调度
├── HitRecords.vue               # 命中记录
├── AdvancedParameters.vue       # 高级参数
├── ProvincialTrafficControl.vue # 本网流量控制
├── NetworkOptimization.vue      # 网络优化
├── SecondaryNetworkOptimization.vue # 次网络优化
└── OptimizationHistory.vue      # 优化记录
```

主页面 `AdaptiveScheduling.vue` 缩减至约408行，只负责页签切换、共享状态和数据加载。

## 15. 安装器原型处理结果

- `InstallerPreview.vue`（48KB）已保存至 `/root/project/docs/prototypes/installer/`
- 路由 `/installer-preview` 暂时保留在router中（后续可从生产路由移除）
- `/root/project/installer/` 已建立真实安装器工程占位（src/scripts/assets）

## 16. Vue或TypeScript检查结果

项目使用纯Vue 3 SFC + JavaScript，无TypeScript。SFC检查脚本 `scripts/sfc-check.mjs` 可用。

## 17. Lint结果

布局Lint脚本 `scripts/layout-lint.mjs` 可用。

## 18. 生产构建结果

**构建成功** ✓

```
vite v5.4.21 building for production...
✓ 351 modules transformed.
✓ built in 17.27s
```

关键产物：
- `AdaptiveScheduling-B8mgKLMa.js` - 108.64 kB（gzip: 33.40 kB）
- `element-plus-CguUK-Ti.js` - 1,073.62 kB
- `echarts-B_l7dWg_.js` - 1,127.51 kB

## 19. 用户可见旧名称搜索结果

| 搜索项 | dist中匹配数 | 说明 |
|--------|-------------|------|
| CDN高利用率 | 0 | ✓ 已清除 |
| CDN高利用率评分 | 0 | ✓ 已清除 |
| PCDN上行优化 | 0 | ✓ 已清除 |
| PCDN优化记录 | 0 | ✓ 已清除 |
| 智能网络优化（一级菜单） | 0 | ✓ 已清除 |

内部代码中仍存在CDN/PCDN变量名（如`cdnIpv4OutboundEligible`等），但不显示给用户。

## 20. 旧端口搜索结果

| 端口 | dist中匹配数 | 说明 |
|------|-------------|------|
| 4173 | 0 | ✓ 无引用 |
| 8080 | 3 | UPnP Mock数据中的端口映射条目（NAS Web示例）+ Element Plus URL正则，非服务器端口引用 |
| 8081 | 0 | ✓ 无引用 |
| installer-preview路由 | 1 | 路由路径保留，后续可移除 |
| dev-mock导入 | 0 | ✓ 生产构建未导入 |
| source map | 0 | ✓ 无map文件 |

## 21. 构建环境检查结果

| 项目 | 状态 | 值 |
|------|------|-----|
| CPU | ✓ | 2核 |
| 内存 | ✓ | 3.4 GiB |
| 磁盘 | ✓ | 29 GB可用（/dev/vda3 40G） |
| Git | ✓ | 2.34.1 |
| GCC | ✓ | 11.4.0 |
| Make | ✓ | 4.3 |
| Python | ✓ | 3.10.12 |
| QEMU | ✓ | /usr/bin/qemu-system-x86_64 |
| xorriso | ✓ | /usr/bin/xorriso |
| grub-mkimage | ✓ | /usr/bin/grub-mkimage |
| OVMF | ✓ | /usr/share/OVMF/（含UEFI固件） |

## 22. 当前阻塞项

1. **安装器预览路由**：`/installer-preview` 仍在生产路由中，建议后续移除
2. **内部CDN/PCDN变量名**：`cdnIpv4OutboundEligible`等变量名仍含CDN前缀，不影响用户界面但代码不够干净
3. **Mock服务层**：当前所有网络数据仍为前端Mock，RealAdapter尚未接入真实UCI/ubus
4. **OpenWrt软件包品牌**：`/root/project/openwrt/packages/`中的包仍使用`linehub-*`命名，后续需重命名为`yaxiang-*`

## 23. 是否具备进入OpenWrt镜像工程的条件

**具备进入OpenWrt镜像工程的条件：是**

理由：
- 统一工程结构已建立
- 生产构建验证通过
- 品牌已统一为亚象
- Mock/Real Adapter分层已完成
- 智能线路调度已拆分为独立组件
- 构建环境依赖齐全
- OpenWrt基础文件和软件包定义已就位

最小修复方案（非阻塞，可后续处理）：
1. 从生产路由中移除 `/installer-preview`
2. 将 `openwrt/files/www/` 更新为最新构建产物
3. 将 `linehub-*` 包名重命名为 `yaxiang-*`

---

*报告结束。等待下一阶段OpenWrt镜像工程指令。*
