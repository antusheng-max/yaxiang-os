# 亚象 OS 当前状态报告

> 更新时间：2026-07-28T16:55:00+08:00  
> 阶段：源码整理 + 01-preflight + 02-host-dependencies **已完成**

---

## 1. Git 状态

| 项目 | 值 |
|------|-----|
| 当前分支 | `recovery/source-changes-20260728` |
| 当前 HEAD | `cf703652948499fe03d969f9b8c01954b6a61f39` |
| `origin/main` | `b7e19448ba6ec4e67f434cce9d5e47de956e78b9` |
| 恢复分支推送 | ✅ 已推送至 `origin/recovery/source-changes-20260728` |

### 源码提交记录（C1–C4）

| 类别 | SHA（短） | 完整 SHA | 文件数 |
|------|-----------|----------|--------|
| C1 OpenWrt | `7826550` | `7826550095bb4b8d1f3bb0d8f0728e860bdb7668` | 101 |
| C2 安装器 | `ea286c0` | `ea286c0d5230863a94b974b20fab9ef298f36a0e` | 5 |
| C3 Web | `cdba3be` | `cdba3be7dc0006849d502f847a35dad16dee3162` | 1 |
| C4 构建控制 | `1cf715e` | `1cf715ec57c195a9cf48809291f50ded98c13797` | 12 |

### C5 未提交内容

- `audit-v0.3/`（83 MB）、`repair-v0.3/`（694 MB）、`repair-v0.3-kernel/`（4.4 MB）
- 22 个 `installer/output/` 验证日志删除项（仍显示为 D）

详见 `docs/build/C5-EXCLUSION-MANIFEST.md`。

---

## 2. 构建阶段状态

| 阶段 | 状态 | 日志 |
|------|------|------|
| C1–C4 源码整理 | ✅ passed | Git commits |
| C5 排除清单 | ✅ 已生成（证据未提交） | `C5-EXCLUSION-MANIFEST.md` |
| 01-preflight | ✅ passed | `logs/01-preflight.log` |
| 02-host-dependencies | ✅ passed | `logs/02-host-dependencies.log` |
| 03-source-checkout | ⏸ 待执行 | 需磁盘 ≥24GB |

---

## 3. 01-preflight 摘要

- PASS: 11，FAIL: 0
- 11/11 CVE 补丁 SHA256 已校验
- `x86_64-security.config` 7886 行
- Ubuntu 22.04.5 x86_64，2 核 / 3.4 GB RAM
- GitHub、OpenWrt git、Ubuntu archive 连通
- tmux 3.2a 可用，时区 Asia/Shanghai
- 构建路径无空格，可用磁盘 26 GB

---

## 4. 02-host-dependencies 摘要

- 38 个包一次性安装（新增 21 个：clang、cmake、dwarves、quilt 等）
- 全部必要命令验证通过（含 pahole）
- 安装后可用磁盘仍约 26 GB

---

## 5. 进入 03-source-checkout 条件

| 条件 | 状态 |
|------|------|
| 可用磁盘 ≥ 24 GB | ✅ 26 GB |
| 01-preflight 通过 | ✅ |
| 02-host-dependencies 通过 | ✅ |
| builder 用户 + Buildroot 目录 | ❌ 尚未创建（03 阶段任务） |

**结论：满足进入 `03-source-checkout` 的前置条件**（磁盘与依赖已就绪）。

---

## 6. 备份

`/root/yaxiang-*-backup*` 均保留，未删除。
