# 亚象 OS 当前状态报告

> 生成时间：2026-07-28T16:40:00+08:00  
> 检查方式：只读检查（未删除文件、未启动编译）  
> 检查主机：香港 Ubuntu 22.04.5 LTS（Remote SSH）

---

## 1. Git 状态

| 项目 | 值 |
|------|-----|
| 当前分支 | `recovery/source-changes-20260728` |
| 当前 HEAD | `8cce2c1764a9840dbc30ac3a5ba425343b4a147a` |
| HEAD 提交信息 | `security: restore Linux 6.12 CVE patches and build config` |
| `origin/main` | `b7e19448ba6ec4e67f434cce9d5e47de956e78b9` |
| `origin/main` 提交信息 | `Merge pull request #1 from antusheng-max/recovery/pre-reset-20260728` |
| 本地相对 origin/main | **落后 1 提交**（缺少 merge commit `b7e1944`） |
| 本地相对 origin/main 独有 | 无（HEAD 是 origin/main 的祖先） |

### 本地分支

| 分支 | HEAD | 说明 |
|------|------|------|
| `recovery/source-changes-20260728` ★ | `8cce2c1` | 当前工作分支，承载未提交源码 |
| `recovery/pre-reset-20260728` | `8cce2c1` | 已合并到 origin/main 的恢复分支 |
| `main` | `9ffc084` | 落后 origin/main 2 提交 |

### 工作区变更统计

| 类型 | 数量 |
|------|------|
| 已修改 (M) | 14 |
| 已删除 (D) | 100 |
| 未跟踪 (??) | 91 |
| **合计** | **205 条变更** |

`git diff --check`：**无空白字符错误**

---

## 2. 磁盘占用

| 挂载点 | 总量 | 已用 | 可用 | 使用率 |
|--------|------|------|------|--------|
| `/` (`/dev/vda3`) | 40 GB | 12 GB | **26 GB** | 31% |

| 路径 | 大小 | 说明 |
|------|------|------|
| `/root/project` | 808 MB | 项目仓库 |
| `/root/project/repair-v0.3` | 694 MB | 审计/修复证据（含 OpenWrt 源码快照） |
| `/root/project/audit-v0.3` | 83 MB | 安全审计证据 |
| `/root/project/repair-v0.3-kernel` | 4.4 MB | 内核恢复文档 |
| `/root/project/openwrt` | 12 MB | 配置/补丁/overlay/packages |
| `/root/project/web` | 9.5 MB | Web 前端源码 |
| `/root/project/installer` | 1.2 MB | 安装器源码 |
| `/root/yaxiang-critical-backup-*` | 存在 | **禁止删除** |
| `/root/yaxiang-worktree-backup-*` | 存在 | **禁止删除** |

**构建空间评估**：可用 26 GB，高于 8 GB 启动阈值，可启动构建环境准备；完整 OpenWrt 源码编译预计需 15–25 GB，空间偏紧，需严格清理中间产物。

---

## 3. 主机环境

| 项目 | 值 |
|------|-----|
| 内核 | Linux 5.15.0-181-generic x86_64 |
| CPU | 2 核 |
| 内存 | 3.4 GB（可用约 2.3 GB） |
| QEMU | 6.2.0 ✓ |
| tmux | 已安装 ✓ |
| git | 已安装 ✓ |
| builder 用户 | **不存在** |
| `/home/builder/yaxiang-build` | **不存在** |
| OpenWrt ImageBuilder | **不存在**（旧 `/root/openwrt-imagebuilder-25.12.5-x86-64.Linux-x86_64` 已清理） |
| 残留 build_dir/staging_dir | **未发现**（项目内及 /home 均无） |

---

## 4. Linux 6.12 CVE 补丁状态

**路径**：`openwrt/kernel-patches/6.12/`  
**数量**：**11 / 11** ✓  
**origin/main 同步**：11 份均在 origin/main 上，SHA256 与本地一致 ✓

| 文件名 | SHA256 |
|--------|--------|
| `950-CVE-2026-45944-iommu-vtd-clear-present.patch` | `4cbf28232f7484099f01557bd998843cb43e4c5b4091a2199592804e37014e24` |
| `951-CVE-2026-46093-vmalloc-purge-lock.patch` | `0c064da94655e4e4fdac768415965eddcf005b31eba884f0fdf16e91aeac0480` |
| `952-CVE-2026-52988-nftables-splice-list-rcu.patch` | `8a9ae4a52cea385eca69edda53303f60ecb3d084d1f32e6db44a2d482c453fad` |
| `953-CVE-2026-52991-cgroup-security-fix.patch` | `0355aa485c618d2123b6c36d689f2ce512206ea73b9fe9283020eecdbec49431` |
| `954-CVE-2026-53078-net-core-filter-fix.patch` | `68c37c3c7cad1bcff0869f4d2d5b748f0216ca8ab3f396c4d45da2c163ee39e6` |
| `955-CVE-2026-53089-bpf-offload-fix.patch` | `5cfbb81d217abd94cadc0ca5a8c9317110da820a420cb3f3f6d9ffd3d6286006` |
| `956-CVE-2026-53341-fhandle-uaf-fix.patch` | `11c07e24d5024eb50b0c45ac5840f0ce94d1f069dd79617534e9a972279bb0a1` |
| `957-CVE-2026-53361-unix-gc-fix.patch` | `a70f937d7b8c2f3ba95409ae09f02e700b4868c6e441a02219685026f37a88ba` |
| `958-CVE-2026-53362-ipv6-fraggap-paged-allocation.patch` | `7691c0eb2e038a7bf7d8c3f1cf8904f0e26a5df352021fc09e4016a7e7a9eb6b` |
| `959-CVE-2026-53366-ipv4-output-fix.patch` | `fec41df729d1471cfb437f4ccb1d323d6b0f1cd1ddf1a1ef8c7201a427069421` |
| `999-CVE-2026-43083-ioam6-qdisc-lock.patch` | `7c756dc085df486c9a606613c3f770a0d4d0b2ba89ac1b566cbfc1724f23ab45` |

---

## 5. OpenWrt 安全配置

| 文件 | 状态 |
|------|------|
| `openwrt/configs/x86_64-security.config` | ✓ 存在，7886 行 |
| origin/main 同步 | ✓ 已合并 |

**固定 OpenWrt 版本**（来自 repair 文档，待构建时验证）：

- 版本：OpenWrt **25.12.5**
- 修订：`r33051-f5dae5ece4`
- Git HEAD：`f5dae5ece4805730c5e2850f8aa84765af2f6b32`
- 目标内核：Linux **6.12.x**

---

## 6. 项目目录结构

```
/root/project/
├── docs/               # 文档（architecture, handover, recovery, reports）
├── installer/          # 安装器（src, scripts, grub, initramfs, assets）
├── openwrt/            # OpenWrt 定制
│   ├── configs/            # x86_64-security.config
│   ├── kernel-patches/6.12/  # 11 份 CVE 补丁
│   ├── files-overlay/      # 运行时文件覆盖
│   ├── files/              # 基础文件
│   ├── packages/           # 自定义 package（yaxiang, linehubd）
│   └── scripts/            # build-openwrt.sh 等
├── web/                # Vue 3 前端源码
├── scripts/            # 构建/验收/验证脚本
├── tests/              # 测试
├── audit-v0.3/         # 审计证据（未跟踪，83 MB）
├── repair-v0.3/        # 修复证据（未跟踪，694 MB）
├── repair-v0.3-kernel/ # 内核恢复文档（未跟踪，4.4 MB）
├── build/              # 构建状态（新建）
├── logs/               # 构建日志（新建）
├── artifacts/          # 中间产物（新建）
└── release/            # 发布目录（新建，.gitignore）
```

---

## 7. 未提交源码分类

### 类别 1：OpenWrt overlay 和自定义 package

**已修改：**

- `openwrt/files-overlay/etc/uci-defaults/10-yaxiang-setup`
- `openwrt/files-overlay/usr/bin/yaxiang-console`
- `openwrt/files-overlay/usr/libexec/rpcd/yaxiang_network`
- `openwrt/files-overlay/usr/libexec/rpcd/yaxiang_system2`
- `openwrt/files-overlay/www/index.html`
- `openwrt/packages/yaxiang/yaxiang-api/Makefile`
- `openwrt/packages/yaxiang/yaxiang-console/files/usr/bin/yaxiang-console`
- `openwrt/packages/yaxiang/yaxiang-defaults/Makefile`
- `openwrt/packages/yaxiang/yaxiang-defaults/files/etc/uci-defaults/10-yaxiang-setup`

**已删除（重构/合并 rpcd）：**

- `yaxiang_advanced`, `yaxiang_firewall`, `yaxiang_lanwan`, `yaxiang_monitor`, `yaxiang_vlan_pppoe`（rpcd 脚本）
- `yaxiang-admin.json`（ACL，替换为 system2 ACL）
- 旧版 `www/assets/*.js`（87 个文件，Vite 重新构建后 hash 变更）

**未跟踪（新增）：**

- `openwrt/files-overlay/etc/init.d/yaxiang-security-gate`
- `openwrt/files-overlay/usr/sbin/yaxiang-enable-management`, `yaxiang-security-gate-apply`
- `openwrt/files-overlay/usr/share/rpcd/acl.d/yaxiang-system2.json`
- `openwrt/files-overlay/www-init/`（Web 初始化 CGI）
- `openwrt/files-overlay/www/assets/*.js`（87 个新 hash 文件）
- `openwrt/packages/yaxiang/yaxiang-api/files/usr/libexec/rpcd/yaxiang_system2`
- `openwrt/packages/yaxiang/yaxiang-api/files/usr/share/rpcd/acl.d/yaxiang-system2.json`
- `openwrt/packages/yaxiang/yaxiang-defaults/files/etc/init.d/yaxiang-security-gate`
- `openwrt/packages/yaxiang/yaxiang-defaults/files/usr/`, `www-init/`

**变更摘要**：rpcd 后端从 7 脚本精简为 2 脚本（network + system2），新增 security-gate 启动流程。

### 类别 2：安装器源码和脚本

**已修改：**

- `installer/scripts/prepare-live-rootfs.sh`
- `installer/src/image-writer.sh`
- `installer/src/yaxiang-installer`

**未跟踪：**

- `installer/grub/fonts/`（GRUB 字体）
- `installer/initramfs/init`（12 KB initramfs 入口）

**已删除（验证日志，原被 Git 跟踪）：**

- `installer/output/final-release-verification/`（10 文件）
- `installer/output/verification-logs/`（12 文件）

> 验证日志属于构建产物，应留在 `.gitignore` 范围，删除跟踪是正确的。

### 类别 3：Web 前端源码

**已修改：**

- `web/src/views/system/Settings.vue`

**关联产物（overlay 内，由 Web 构建生成）：**

- 87 个新 `www/assets/*.js` + `index.html` 更新

### 类别 4：测试、文档和构建脚本

**已修改：**

- `scripts/build-acceptance-pipeline-v2.sh`（+346 行，流水线增强）

**未跟踪：**

- `scripts/build-acceptance-pipeline.sh`（v1 旧版）
- `scripts/independent-verify.sh`, `independent-verify-v2.sh`
- `scripts/retest-uefi-network.sh`, `test-network-web-final.sh`

**已有文档：**

- `docs/recovery/RECOVERY-20260728.md`（已在 HEAD 提交中）

### 类别 5：审计证据和生成文件（**不应进入普通 Git**）

| 路径 | 大小 | 建议 |
|------|------|------|
| `audit-v0.3/` | 83 MB | 保留本地或归档，不提交 |
| `repair-v0.3/` | 694 MB | 含 OpenWrt 源码快照，**禁止提交** |
| `repair-v0.3-kernel/` | 4.4 MB | 可选：提取文档后提交，源码快照不提交 |

---

## 8. 敏感信息扫描

| 检查项 | 结果 |
|--------|------|
| `.env`, `*.pem`, `*.key`, `credentials*` | 未发现 |
| 真实私钥/Token | 未发现 |
| Web UI 模拟密码（`pass123456` 等） | 存在于 `Wan.vue` 等演示数据，**非真实凭据** |
| 旧流水线引用 ImageBuilder 路径 | `/root/openwrt-imagebuilder-25.12.5-x86-64.Linux-x86_64`（已不存在，需更新） |

---

## 9. 构建脚本和安装器状态

| 组件 | 状态 |
|------|------|
| `scripts/yaxiang-build.sh` | **待创建**（新 25 阶段流水线） |
| `scripts/build-acceptance-pipeline-v2.sh` | 存在，引用旧 ImageBuilder 路径 |
| `openwrt/scripts/build-openwrt.sh` | 存在，基于 ImageBuilder（需迁移到 Buildroot） |
| `installer/src/yaxiang-installer` | 有未提交修改 |
| `installer/src/image-writer.sh` | 有未提交修改 |
| OpenWrt Buildroot | **不存在**，需全新克隆到 `/home/builder/yaxiang-build` |

---

## 10. 备份状态

| 备份 | 状态 |
|------|------|
| `/root/yaxiang-critical-backup-20260728-150109` | ✓ 存在 |
| `/root/yaxiang-critical-backup-20260728-150109.tar.gz` | ✓ 存在（含 .sha256） |
| `/root/yaxiang-worktree-backup-20260728-155134` | ✓ 存在 |
| `/root/yaxiang-worktree-backup-20260728-155134.tar.gz` | ✓ 存在（含 .sha256） |

---

## 11. 当前版本信息

- 产品版本：**Yaxiang OS V0.3-dev**
- README 记录的旧 ISO SHA256：`cb4d479aacab6bc678010f25517ce1e905d4b62d4944ec94ac65140d40a06cc0`
- 新构建目标：完整 OpenWrt Buildroot 编译（非 ImageBuilder 快捷路径）

---

## 12. 阻塞项与风险

1. **builder 用户未创建** — 构建必须在非 root 用户下进行
2. **OpenWrt Buildroot 不存在** — 需克隆并固定到 `f5dae5ece4`
3. **磁盘空间偏紧** — 26 GB 可用，完整编译 + QEMU 测试可能接近上限
4. **内存仅 3.4 GB** — 并行编译 `-j2` 可能 OOM，建议 `-j1` 或增加 swap
5. **本地分支落后 origin/main** — 提交前应 rebase/merge `b7e1944`
6. **旧 ImageBuilder 路径引用** — 多个脚本需更新为新 Buildroot 路径

---

## 13. 下一步行动（本次不执行）

1. 分类提交未提交源码到恢复分支（5 类分别提交）
2. 创建 builder 用户和 `/home/builder/yaxiang-build`
3. 执行 `01-preflight` → `02-host-dependencies`
4. 克隆 OpenWrt 25.12.5 @ `f5dae5ece4` 并导入配置/补丁/overlay
