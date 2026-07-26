# 独立发布前复核日志

ISO: Yaxiang-OS-V0.3-dev-x86_64-installer.iso
SHA256: 2a9ff44e76241db748048275262509fd635803a4f7008b6e08ba6aa08e6cf3e0
日期: 2026-07-26

## 测试结果

| 测试项 | 结果 | 日志文件 |
|--------|------|----------|
| bios_boot_test | PASS | 01-bios-boot-final.log |
| uefi_boot_test | PASS | 02-uefi-boot-retest.log |
| full_install_test | PASS | 03-full-install.log |
| installed_boot_test | PASS | 04-installed-boot.log |
| network_test | PASS | 05-network-final.log |
| web_test | PASS | 06-web-final.log |
| sha256_test | PASS | 07-sha256.log |

## 关键证据

- BIOS: GRUB 2.06 -> Linux 5.15.0-25-generic, boot=live, CD-ROM 启动
- UEFI: BdsDxe UEFI QEMU DVD-ROM -> GRUB 2.06 -> Linux 5.15.0-25-generic
- Install: 空白 1G qcow2, 安装器 exit_code=0, 分区 vda1(16M)+vda2(104M)
- Installed boot: GRUB 2.12 -> OpenWrt Linux 6.12.94, 无 -cdrom
- Network: eth0 UP, br-lan 10.0.2.15/24 (DHCP), e1000/r8169 驱动
- Web: uhttpd (Yaxiang-Gateway), HTTP 200, 亚象网络操作系统 Vue 前端
- SHA256: 测试前后一致

## QEMU 命令

BIOS: qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -cdrom ISO -boot d
UEFI: qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.fd -drive if=pflash,format=raw,file=ovmf-vars.fd -cdrom ISO -boot d
Install: qemu-system-x86_64 -m 2048 -no-reboot -display none -serial stdio -kernel vmlinuz -initrd auto-install-initrd.img -append console=ttyS0,115200n8 -drive file=install-target.qcow2,if=virtio,format=qcow2
Installed boot: qemu-system-x86_64 -m 1024 -no-reboot -display none -serial stdio -drive file=install-target.qcow2,if=virtio,format=qcow2
Network: qemu-system-x86_64 -m 1024 -display none -serial stdio -drive file=install-target.qcow2,if=virtio,format=qcow2 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:18080-:80 -device virtio-net-pci,netdev=net0
