# 贡献指南

感谢你对亚象网络操作系统的关注！

## 分支规范

- `main` - 主分支，保持稳定
- `dev` - 开发分支
- `feature/*` - 功能分支
- `fix/*` - 修复分支
- `release/*` - 发布分支

## 提交规范

使用约定式提交格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型

- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式（不影响代码运行）
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建过程或辅助工具变动

### 示例

```
feat(network): 添加VLAN 802.1Q支持

实现VLAN创建、删除、VID验证功能。

Closes #123
```

## 测试要求

### 必须通过的测试

1. **单元测试** - 所有新增功能必须有对应单元测试
2. **QEMU测试** - 安装器相关修改必须通过QEMU测试
3. **安全测试** - 涉及用户输入的修改必须通过注入测试

### 运行测试

```bash
# 单元测试
cd tests/unit
python -m pytest

# 安装器QEMU测试
cd installer/scripts
./test-stage2-disk-safety.sh
./test-stage3-image-write.sh
```

## 安全红线

### 绝对禁止

- ❌ 修改构建服务器真实网络配置
- ❌ 在生产网络环境进行测试
- ❌ 提交包含真实凭据的代码
- ❌ 绕过磁盘安全确认机制
- ❌ 禁用命令注入防护

### 网络测试规范

- ✅ 网络写入测试必须在QEMU或隔离环境中完成
- ✅ 使用虚拟磁盘进行安装测试
- ✅ 测试前确认测试模式标记
- ✅ 测试后验证服务器磁盘MBR哈希未变

## 代码风格

### Shell脚本

- 使用 `#!/bin/bash` 或 `#!/bin/sh`
- 启用 `set -euo pipefail`
- 变量使用双引号
- 函数使用小写加下划线

### JavaScript/Vue

- 使用ESLint + Prettier
- 组件使用PascalCase命名
- 组合式API优先

### Python

- 遵循PEP 8
- 使用类型注解
- 文档字符串使用Google风格

## 提交前检查清单

- [ ] 代码通过所有测试
- [ ] 无敏感信息泄露
- [ ] 无大型二进制文件（ISO/IMG/ZIP）
- [ ] 文档已更新（如适用）
- [ ] 提交信息符合规范

## 问题报告

报告问题时请包含：

- 环境信息（版本、架构）
- 复现步骤
- 期望行为
- 实际行为
- 日志（脱敏后）
