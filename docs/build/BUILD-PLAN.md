# 亚象 OS 构建计划

> 版本：Yaxiang OS V0.3-dev  
> 创建时间：2026-07-28T16:40:00+08:00  
> 状态：**规划阶段**（尚未启动编译）

---

## 1. 目标

从干净的 OpenWrt Buildroot 出发，完整编译 Linux 6.12 内核（含 11 份 CVE 补丁）、内核模块和系统镜像，构建安装 ISO，通过 QEMU 全量测试，生成可发布到 GitHub Release 的制品包。

---

## 2. 构建环境规范

### 2.1 目录布局

| 路径 | 用途 | 所有者 |
|------|------|--------|
| `/root/project` | Git 版本库（源码、配置、脚本） | root |
| `/home/builder/yaxiang-build` | OpenWrt Buildroot 唯一构建树 | builder |
| `/root/project/logs/` | 各阶段日志 | root |
| `/root/project/artifacts/` | 中间产物（内核、rootfs、initramfs） | root |
| `/root/project/release/<版本>/` | 最终发布目录 | root |

### 2.2 OpenWrt 源码固定

```
版本：OpenWrt 25.12.5
修订：r33051-f5dae5ece4
Git：  f5dae5ece4805730c5e2850f8aa84765af2f6b32
目标： x86_64 generic
内核： Linux 6.12.x
```

**禁止**自动切换到最新 OpenWrt 版本。

### 2.3 从项目导入的资源

| 源路径 | 目标位置（Buildroot 内） |
|--------|--------------------------|
| `openwrt/configs/x86_64-security.config` | `.config` |
| `openwrt/kernel-patches/6.12/*.patch` | `target/linux/generic/pending-6.12/` |
| `openwrt/files-overlay/` | `files/`（或 package overlay） |
| `openwrt/packages/yaxiang/` | `package/yaxiang/` |
| `openwrt/packages/linehubd/` | `package/linehubd/` |

### 2.4 磁盘与资源限制

- 构建前检查 `df -h /`
- 可用 < 8 GB：禁止启动大型构建阶段
- 可用 < 5 GB：立即停止流水线
- 不启用 ccache
- 只允许一份 Buildroot、一份 build_dir、一份 staging_dir
- QEMU 磁盘使用 qcow2 稀疏格式
- 编译并行度：`-j1`（2 核 / 3.4 GB 内存环境）

### 2.5 长时间任务

- 所有构建在 tmux 会话 `yaxiang-build` 中运行
- 日志实时写入 `logs/<阶段>.log`
- Cursor 断线不影响构建

---

## 3. 构建阶段（25 步，严格顺序）

控制脚本：`scripts/yaxiang-build.sh`  
状态文件：`build/BUILD-STATE.json`

| # | 阶段 ID | 名称 | 主要操作 | 预估耗时 |
|---|---------|------|----------|----------|
| 01 | `01-preflight` | 预检 | 磁盘/内存/Git/补丁 SHA256/空间阈值 | 1 min |
| 02 | `02-host-dependencies` | 主机依赖 | 安装 build-essential、flex、bison 等 | 5 min |
| 03 | `03-source-checkout` | 源码检出 | 创建 builder 用户；克隆 OpenWrt @ f5dae5ece4 | 10 min |
| 04 | `04-feeds` | Feeds 更新 | `./scripts/feeds update -a && install -a` | 15 min |
| 05 | `05-config-import` | 配置导入 | 复制 x86_64-security.config；导入 patches/overlay/packages | 2 min |
| 06 | `06-download` | 源码下载 | `make download` | 20 min |
| 07 | `07-tools` | 工具链工具 | `make tools/install -j1` | 30 min |
| 08 | `08-toolchain` | 交叉工具链 | `make toolchain/install -j1` | 45 min |
| 09 | `09-kernel-prepare` | 内核准备 | 应用 11 份 CVE 补丁；验证 patch 数量 | 5 min |
| 10 | `10-kernel-compile` | 内核编译 | `make target/linux/compile -j1 V=s` | 60 min |
| 11 | `11-kernel-modules` | 内核模块 | `make target/linux/install -j1` | 15 min |
| 12 | `12-openwrt-image` | 系统镜像 | `make -j1`（完整 OpenWrt 镜像） | 90 min |
| 13 | `13-web-build` | Web 构建 | `cd web && npm ci && npm run build` | 5 min |
| 14 | `14-rootfs-integration` | Rootfs 集成 | 复制 web dist 到 overlay；集成 yaxiang packages | 10 min |
| 15 | `15-installer-build` | 安装器构建 | 构建 initramfs + live rootfs | 15 min |
| 16 | `16-iso-build` | ISO 构建 | 生成 `Yaxiang-OS-V0.3-dev-x86_64-installer.iso` | 10 min |
| 17 | `17-qemu-boot` | QEMU 启动 | Legacy BIOS 启动 ISO | 5 min |
| 18 | `18-qemu-install` | QEMU 安装 | 完整安装到 qcow2 磁盘 | 15 min |
| 19 | `19-uefi-test` | UEFI 测试 | OVMF 启动 ISO 和已安装系统 | 10 min |
| 20 | `20-disk-test` | 磁盘测试 | SATA + NVMe 识别；安装介质排除 | 10 min |
| 21 | `21-five-reboot-test` | 五重启测试 | 连续 5 次重启 + 配置持久化 | 15 min |
| 22 | `22-security-scan` | 安全扫描 | 扫描产物中的密钥/密码/开发残留 | 10 min |
| 23 | `23-sbom` | SBOM 生成 | 生成 SPDX JSON | 5 min |
| 24 | `24-release-validation` | 发布验证 | SHA256 校验；manifest 完整性 | 5 min |
| 25 | `25-release-package` | 发布打包 | 组装 release/ 目录 | 5 min |

**总预估**：约 6–8 小时（受 CPU/内存/磁盘 IO 影响）

---

## 4. 失败处理策略

1. 阶段失败 → **立即停止**后续阶段
2. 记录：开始/完成时间、命令、返回码、日志路径
3. 分析**第一个真实错误**（不猜测性连锁修复）
4. 修复前检查 Buildroot 依赖关系和当前 build_dir 状态
5. 修复后**仅重跑**失败阶段及其必要前置阶段
6. 禁止：`缺 flex → 修 m4 → 修 bison → 修 gcc` 式逐项猜测

---

## 5. 源码提交计划（构建前）

在 `recovery/source-changes-20260728` 分支上，分 5 类独立提交：

| 提交序 | 类别 | 路径范围 | 分支策略 |
|--------|------|----------|----------|
| C1 | OpenWrt overlay + packages | `openwrt/files-overlay/`, `openwrt/packages/yaxiang/` | recovery 分支 |
| C2 | 安装器 | `installer/src/`, `installer/scripts/`, `installer/initramfs/`, `installer/grub/` | recovery 分支 |
| C3 | Web 前端 | `web/src/` | recovery 分支 |
| C4 | 构建/测试脚本 | `scripts/`, `docs/build/` | recovery 分支 |
| C5 | 删除跟踪的验证日志 | `installer/output/` 删除确认 | recovery 分支 |

**不提交**：`audit-v0.3/`, `repair-v0.3/`, `repair-v0.3-kernel/`（证据/archive）  
**每次提交前**：`git diff --check` + 文件清单输出

---

## 6. 测试验收标准

| 测试项 | 阶段 | 通过条件 |
|--------|------|----------|
| Legacy BIOS 启动 | 17 | GRUB 菜单可见，可进入安装器 |
| UEFI 启动 | 19 | OVMF 下正常启动 |
| SATA 磁盘识别 | 20 | /dev/sda 可见且可选为目标 |
| NVMe 磁盘识别 | 20 | /dev/nvme0n1 可见且可选为目标 |
| 安装介质排除 | 20 | ISO 设备不在可写目标列表 |
| 安装目标确认 | 18 | 写入前需用户确认 |
| SHA256 校验 | 24 | ISO hash 与 BUILD-MANIFEST 一致 |
| 安装后启动 | 18 | 安装完成可正常启动 |
| Web 管理界面 | 21 | HTTP 200，无开发服务器残留 |
| 配置持久化 | 21 | 重启后 UCI 配置保留 |
| 连续 5 次重启 | 21 | 5/5 成功启动 |
| 无测试密码/私钥 | 22 | 安全扫描零命中 |
| 不误写安装介质 | 20 | image-writer 拒绝 ISO 设备 |

---

## 7. 发布目录结构

```
release/V0.3-dev/
├── Yaxiang-OS-V0.3-dev-x86_64-installer.iso
├── SHA256SUMS
├── BUILD-MANIFEST.json
├── SOURCE-COMMIT.txt
├── OPENWRT-COMMIT.txt
├── KERNEL-PATCHES-SHA256.txt
├── SBOM.spdx.json
├── SECURITY-REPORT.md
├── TEST-REPORT.md
└── RELEASE-NOTES.md
```

**发布规则**：

- 全部 25 阶段 + 测试通过后才创建 Release
- GitHub Release 先创建 **draft + prerelease**
- 上传后重新下载验证 SHA256
- 需用户明确确认后才转正式发布

---

## 8. 当前执行进度

| 阶段 | 状态 |
|------|------|
| 只读检查 | ✅ 完成 |
| 文档创建 | ✅ 完成 |
| 源码分类提交 | ⏳ 待执行 |
| 构建环境搭建 | ⏳ 待执行 |
| 01-preflight | ⏳ 下一步 |

详见 `build/BUILD-STATE.json`。

---

## 9. 与旧流水线的差异

| 项目 | 旧方案 | 新方案 |
|------|--------|--------|
| 构建方式 | ImageBuilder 快捷路径 | 完整 OpenWrt Buildroot |
| 构建目录 | `/root/openwrt-imagebuilder-*` | `/home/builder/yaxiang-build` |
| 内核补丁 | 未打入正式内核 | 11 份 CVE 补丁编译进内核 |
| 构建用户 | root | builder |
| 控制脚本 | `build-acceptance-pipeline-v2.sh` | `yaxiang-build.sh`（25 阶段） |
| 状态追踪 | 无 | `BUILD-STATE.json` |

旧脚本 `build-acceptance-pipeline-v2.sh` 保留供参考，新构建统一使用 `yaxiang-build.sh`。
