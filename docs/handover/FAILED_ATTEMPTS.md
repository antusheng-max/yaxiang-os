# 失败尝试记录

## 2026-07-25 V0.3构建

### 1. kmod-8021q包不存在
- **原因**: OpenWrt 25.12.5中VLAN支持已内置内核，无独立kmod-8021q包
- **解决**: 从PACKAGES列表中移除kmod-8021q

## 2026-07-25 第六阶段B-最终

无阻塞性失败。所有rpcd脚本语法检查通过，Web构建通过，镜像构建成功。

## 2026-07-25 第六阶段A

无失败尝试。

## 2026-07-25 安装 ISO 第五阶段

### 1. 身份哈希计算不一致
- **解决**: 统一三个脚本的compute_identity_hash默认值

## 2026-07-25 安装 ISO 第四阶段

### 1. grub-mkrescue缺少mformat
- **解决**: apt-get install mtools

## 2026-07-25 安装 ISO 第三阶段

### 1. virtfs/9p不可用 → 改用initrd嵌入
### 2. busybox dd不支持status=progress → 移除
### 3. head -c导致SIGPIPE → 改用dd bs=精确字节数

## 2026-07-25 安装 ISO 第二阶段

### 1. QEMU -nographic与-serial stdio冲突
### 2. VirtIO磁盘未检测(virtio_blk.ko缺失)
### 3. set -e下read退出
### 4. 测试断言跨区段匹配

## 2026-07-25 安装 ISO 第一阶段

### 1-8. debootstrap/date/heredoc/QEMU FAT16/grub-mkrescue/mksquashfs等
