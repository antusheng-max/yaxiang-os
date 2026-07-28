# 亚象 OS 当前状态报告

> 更新时间：2026-07-28T16:52:00+08:00  
> 阶段：源码整理完成，preflight/deps 进行中

---

## 1. Git 状态

| 项目 | 值 |
|------|-----|
| 当前分支 | `recovery/source-changes-20260728` |
| 当前 HEAD | `1cf715ec57c195a9cf48809291f50ded98c13797` |
| `origin/main` | `b7e19448ba6ec4e67f434cce9d5e47de956e78b9` |

### 源码提交记录（C1–C4）

| 类别 | SHA | 文件数 | 提交信息 |
|------|-----|--------|----------|
| C1 OpenWrt | `7826550` | 101 | feat(openwrt): restore overlay and yaxiang packages |
| C2 安装器 | `ea286c0` | 5 | feat(installer): restore installer sources and initramfs |
| C3 Web | `cdba3be` | 1 | feat(web): update system settings view |
| C4 构建控制 | `1cf715e` | 12 | chore(build): add build control docs and scripts |

### 剩余未提交（C5）

| 类型 | 数量 | 说明 |
|------|------|------|
| 已删除 (D) | 22 | `installer/output/` 验证日志 |
| 未跟踪 (??) | 3 目录 | `audit-v0.3/`, `repair-v0.3/`, `repair-v0.3-kernel/` |

详见 `docs/build/C5-EXCLUSION-MANIFEST.md`。

---

## 2. 构建阶段状态

| 阶段 | 状态 |
|------|------|
| 源码整理 C1–C4 | ✅ 完成 |
| C5 排除清单 | ✅ 已生成（未提交证据目录） |
| 01-preflight | ⏳ 执行中 |
| 02-host-dependencies | ⏳ 待执行 |
| 03-source-checkout | ⏸ 需磁盘 ≥24GB |

---

## 3. CVE 补丁

11/11 存在，`x86_64-security.config` 7886 行。

---

## 4. 磁盘

可用约 26 GB（构建前检查）。

---

## 5. 备份

`/root/yaxiang-*-backup*` 均保留，未删除。
