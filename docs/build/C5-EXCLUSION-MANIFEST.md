# C5 排除清单与保留建议

> 生成时间：2026-07-28T16:50:00+08:00  
> 状态：**暂不提交 Git**

---

## 排除原因

以下内容为审计证据、构建日志、生成文件或大型源码快照，不应进入普通 Git 仓库。

---

## 1. 未跟踪目录

| 路径 | 大小 | 文件数（约） | 保留建议 |
|------|------|-------------|----------|
| `audit-v0.3/` | 83 MB | — | 保留本地；可归档为独立 tar.gz 存于 `/root/yaxiang-*-backup*` 同级 |
| `repair-v0.3/` | 694 MB | 10,948 | **禁止提交**；含 OpenWrt 源码快照，保留至构建验证完成 |
| `repair-v0.3-kernel/` | 4.4 MB | — | 保留本地；可提取文档部分后单独归档 |

## 2. 已删除但仍被 Git 跟踪的验证日志（22 文件）

路径：`installer/output/final-release-verification/`（10 文件）  
路径：`installer/output/verification-logs/`（12 文件）

| 建议 | 说明 |
|------|------|
| 后续单独提交删除 | 确认 `.gitignore` 已覆盖 `installer/output/` 后，提交 `git rm --cached` 停止跟踪 |
| 暂不恢复文件内容 | 日志属构建产物，无需回写磁盘 |

## 3. 明确排除的文件类型

- `*.iso`, `*.img`, `*.zip`, `*.tar.gz`, `*.qcow2`
- `node_modules/`, `build_dir/`, `staging_dir/`
- `*.log`（构建/验证日志）
- `/root/yaxiang-*-backup*`（服务器级备份，禁止删除）

## 4. 后续处理建议

1. 构建流水线完成后，将 `audit-v0.3/` 和 `repair-v0.3-kernel/` 文档提取至 `docs/audit/`
2. `repair-v0.3/` 在 OpenWrt Buildroot 克隆成功后，可移出项目目录至 `/root/archive/`
3. 提交一次 cleanup commit 移除 `installer/output/` 的 Git 跟踪（C5 完成后、构建开始前）
