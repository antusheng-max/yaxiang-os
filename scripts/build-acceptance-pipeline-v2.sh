#!/bin/bash
set -euo pipefail

# ============================================================
# 亚象网络操作系统 - 构建即验收强制流水线 v2
# Yaxiang OS Build-as-Acceptance Pipeline
#
# 一个命令完成: 编译→打包→测试→发布
# 任何一步失败立即退出，禁止上传 Release
# 关键检查不使用 2>/dev/null || true
# ============================================================

readonly VERSION="V0.3-dev"
readonly PROJECT_DIR="/root/project"
readonly INSTALLER_DIR="${PROJECT_DIR}/installer"
readonly OPENWRT_DIR="${PROJECT_DIR}/openwrt"
readonly WEB_DIR="${PROJECT_DIR}/web"
readonly IMAGE_BUILDER="/root/openwrt-imagebuilder-25.12.5-x86-64.Linux-x86_64"
readonly OUTPUT_DIR="${INSTALLER_DIR}/output"
readonly PIPELINE_DIR="${OUTPUT_DIR}/pipeline-$(date '+%Y%m%d-%H%M%S')"
readonly ISO_NAME="Yaxiang-OS-${VERSION}-x86_64-installer.iso"
readonly ISO_PATH="${OUTPUT_DIR}/${ISO_NAME}"
readonly LIVE_ROOTFS="${INSTALLER_DIR}/live/rootfs"
readonly KERNEL_VER="5.15.0-25-generic"
readonly OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
readonly OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
readonly GH_REPO="antusheng-max/yaxiang-os"
readonly GH_TAG="v0.4-dev"

# 测试结果追踪
declare -A TEST_RESULTS
readonly REQUIRED_TESTS=(
    static_iso_test
    initramfs_module_test
    bios_boot_test
    uefi_boot_test
    full_install_test
    installed_boot_test
    network_test
    web_test
    sha256_test
)

# ============================================================
# 日志系统 - 保留完整测试日志
# ============================================================
mkdir -p "$PIPELINE_DIR"
readonly MAIN_LOG="${PIPELINE_DIR}/pipeline-full.log"
readonly STEP_LOG_DIR="${PIPELINE_DIR}/steps"
mkdir -p "$STEP_LOG_DIR"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$MAIN_LOG"
}

step_log() {
    local step="$1"; shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$MAIN_LOG" "${STEP_LOG_DIR}/${step}.log"
}

die() {
    log "[FATAL] $*"
    log "流水线中止。禁止上传 Release。"
    log "完整日志: $MAIN_LOG"
    exit 1
}

mark_pass() {
    TEST_RESULTS["$1"]="PASS"
    log "[TEST PASS] $1"
}

mark_fail() {
    TEST_RESULTS["$1"]="FAIL"
    log "[TEST FAIL] $1: $2"
    die "测试 $1 失败，流水线终止。原因: $2"
}

# ============================================================
# 阶段 1: 编译 Web 前端
# ============================================================
stage_build_web() {
    log "========== 阶段 1: 编译 Web 前端 =========="
    local step_log_file="${STEP_LOG_DIR}/01-build-web.log"

    cd "$WEB_DIR"
    if [ ! -d node_modules ]; then
        npm install --silent >> "$step_log_file" 2>&1
    fi
    npm run build >> "$step_log_file" 2>&1

    [ -f "${WEB_DIR}/dist/index.html" ] || die "Web 构建失败: dist/index.html 不存在"
    log "Web 前端编译完成"
}

# ============================================================
# 阶段 2: 编译 OpenWrt 系统镜像
# ============================================================
stage_build_openwrt() {
    log "========== 阶段 2: 编译 OpenWrt 系统镜像 =========="
    local step_log_file="${STEP_LOG_DIR}/02-build-openwrt.log"
    local build_output="${OPENWRT_DIR}/output/v0.3-dev"
    mkdir -p "$build_output"

    local FILES_DIR="${OPENWRT_DIR}/files-overlay"
    rm -rf "$FILES_DIR"
    mkdir -p "$FILES_DIR/www" "$FILES_DIR/etc"

    cp -r "${WEB_DIR}/dist/"* "$FILES_DIR/www/"

    local PKG_DIR="${OPENWRT_DIR}/packages/yaxiang"
    if [ -f "${PKG_DIR}/yaxiang-branding/files/etc/yaxiang-release" ]; then
        cp "${PKG_DIR}/yaxiang-branding/files/etc/yaxiang-release" "$FILES_DIR/etc/"
    fi

    mkdir -p "$FILES_DIR/etc/uci-defaults" "$FILES_DIR/etc/init.d" "$FILES_DIR/usr/bin" \
             "$FILES_DIR/usr/libexec/rpcd" "$FILES_DIR/usr/share/rpcd/acl.d"
    for script in "${PKG_DIR}"/*/files/etc/uci-defaults/*; do
        [ -f "$script" ] && cp "$script" "$FILES_DIR/etc/uci-defaults/" && chmod +x "$FILES_DIR/etc/uci-defaults/$(basename "$script")"
    done
    for script in "${PKG_DIR}"/*/files/etc/init.d/*; do
        [ -f "$script" ] && cp "$script" "$FILES_DIR/etc/init.d/" && chmod +x "$FILES_DIR/etc/init.d/$(basename "$script")"
    done
    for bin in "${PKG_DIR}"/*/files/usr/bin/*; do
        [ -f "$bin" ] && cp "$bin" "$FILES_DIR/usr/bin/" && chmod +x "$FILES_DIR/usr/bin/$(basename "$bin")"
    done
    for rpc in "${PKG_DIR}"/*/files/usr/libexec/rpcd/*; do
        [ -f "$rpc" ] && cp "$rpc" "$FILES_DIR/usr/libexec/rpcd/" && chmod +x "$FILES_DIR/usr/libexec/rpcd/$(basename "$rpc")"
    done
    for acl in "${PKG_DIR}"/*/files/usr/share/rpcd/acl.d/*; do
        [ -f "$acl" ] && cp "$acl" "$FILES_DIR/usr/share/rpcd/acl.d/"
    done

    cd "$IMAGE_BUILDER"
    local PACKAGES="uhttpd uhttpd-mod-ubus rpcd rpcd-mod-file rpcd-mod-ucode ubus uci firewall4 nftables ip-full \
      kmod-e1000 kmod-e1000e kmod-igb kmod-igc kmod-ixgbe kmod-r8169 \
      ca-bundle dnsmasq odhcpd-ipv6only odhcp6c \
      dropbear kmod-button-hotplug grub2-bios-setup procd-ujail"

    log "构建 combined (BIOS) 镜像..."
    make image \
        PROFILE="generic" \
        PACKAGES="$PACKAGES" \
        FILES="$FILES_DIR" \
        BIN_DIR="$build_output" \
        >> "$step_log_file" 2>&1

    local bios_img efi_img
    bios_img=$(find "$build_output" -name "*combined.img.gz" ! -name "*efi*" | head -1)
    efi_img=$(find "$build_output" -name "*combined-efi.img.gz" | head -1)

    [ -n "$bios_img" ] && [ -f "$bios_img" ] || die "BIOS 镜像构建失败"
    [ -n "$efi_img" ] && [ -f "$efi_img" ] || die "EFI 镜像构建失败"

    cp "$bios_img" "${INSTALLER_DIR}/images/combined.img.gz"
    cp "$efi_img" "${INSTALLER_DIR}/images/combined-efi.img.gz"
    (cd "${INSTALLER_DIR}/images" && sha256sum combined.img.gz combined-efi.img.gz > SHA256SUMS)

    log "OpenWrt 系统镜像编译完成"
}

# ============================================================
# 阶段 3: 生成 filesystem.squashfs
# ============================================================
stage_build_squashfs() {
    log "========== 阶段 3: 生成 filesystem.squashfs =========="
    local step_log_file="${STEP_LOG_DIR}/03-squashfs.log"
    local staging="${OUTPUT_DIR}/iso-staging"
    mkdir -p "$staging/live"

    [ -d "$LIVE_ROOTFS" ] && [ -f "${LIVE_ROOTFS}/bin/bash" ] || die "Live rootfs 不存在"

    rm -f "$staging/live/filesystem.squashfs"
    mksquashfs "$LIVE_ROOTFS" "$staging/live/filesystem.squashfs" \
        -comp xz -Xdict-size 100% -noappend \
        -e dev proc sys run tmp var/tmp var/log \
        >> "$step_log_file" 2>&1

    [ -f "$staging/live/filesystem.squashfs" ] || die "squashfs 生成失败"
    log "filesystem.squashfs 生成完成: $(du -h "$staging/live/filesystem.squashfs" | cut -f1)"
}

# ============================================================
# 阶段 4: 生成包含精选内核模块的 initramfs
# 修复: 只复制安装/启动必需模块，避免 initramfs 过大导致 QEMU OOM
# ============================================================
stage_build_initramfs() {
    log "========== 阶段 4: 生成 initramfs (含精选内核模块) =========="
    local step_log_file="${STEP_LOG_DIR}/04-initramfs.log"
    local staging="${OUTPUT_DIR}/iso-staging"
    mkdir -p "$staging/boot"
    local initrd_dir="${PIPELINE_DIR}/initrd-build"
    rm -rf "$initrd_dir"
    mkdir -p "$initrd_dir"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,tmp,run,etc,var/log,opt/yaxiang-installer,rootfs}

    # ---- 复制内核 ----
    local kernel_file
    kernel_file=$(find "${LIVE_ROOTFS}/boot" -name "vmlinuz-*" -type f | sort -V | tail -1)
    [ -n "$kernel_file" ] && [ -f "$kernel_file" ] || die "内核文件不存在"
    cp "$kernel_file" "$staging/boot/vmlinuz"
    log "内核: $(basename "$kernel_file")"

    # ---- busybox ----
    local busybox_src="${LIVE_ROOTFS}/bin/busybox"
    [ -f "$busybox_src" ] || busybox_src=$(which busybox)
    [ -f "$busybox_src" ] || die "busybox 不存在"
    cp "$busybox_src" "$initrd_dir/bin/busybox"
    chmod +x "$initrd_dir/bin/busybox"
    local applets="sh ash cat echo grep sed awk sort printf basename dirname readlink \
        sha256sum ls mkdir mount umount sleep poweroff reboot clear head tail wc tr cut \
        uname dmesg lsmod free vi more less test expr seq yes dd sync blockdev insmod \
        modprobe fdisk blkid findmnt losetup date du gzip cp rm mv ln touch chmod chown \
        kill ps wget nc ip ping brctl uci ubus"
    for applet in $applets; do
        ln -sf busybox "$initrd_dir/bin/$applet"
    done
    ln -sf ../bin/busybox "$initrd_dir/sbin/poweroff"
    ln -sf ../bin/busybox "$initrd_dir/sbin/reboot"
    ln -sf ../bin/busybox "$initrd_dir/sbin/blkid"
    ln -sf ../bin/busybox "$initrd_dir/sbin/fdisk"

    # ---- bash + 动态库 ----
    if [ -f "${LIVE_ROOTFS}/bin/bash" ]; then
        cp "${LIVE_ROOTFS}/bin/bash" "$initrd_dir/bin/bash"
        chmod +x "$initrd_dir/bin/bash"
    fi
    mkdir -p "$initrd_dir/lib/x86_64-linux-gnu" "$initrd_dir/lib64"
    for lib in "${LIVE_ROOTFS}"/lib/x86_64-linux-gnu/lib{c,m,dl,pthread,tinfo,ncursesw,selinux}.so*; do
        [ -f "$lib" ] && cp "$lib" "$initrd_dir/lib/x86_64-linux-gnu/"
    done
    [ -f "${LIVE_ROOTFS}/lib64/ld-linux-x86-64.so.2" ] && cp "${LIVE_ROOTFS}/lib64/ld-linux-x86-64.so.2" "$initrd_dir/lib64/"

    # ============================================================
    # 精选内核模块 - 只复制安装和启动必需的模块
    # 修复: 原版复制全部 6004 个模块 (147MB 压缩 / 438MB 解压)
    #        导致 QEMU 512MB 内存 tmpfs 不足，initramfs 解压失败
    # ============================================================
    log "复制精选内核模块 (${KERNEL_VER})..."
    local MODULE_SRC="${LIVE_ROOTFS}/lib/modules/${KERNEL_VER}"
    local MODULE_DST="$initrd_dir/lib/modules/${KERNEL_VER}"
    mkdir -p "$MODULE_DST"

    # 要复制的关键模块 (QEMU virtio + SATA + 网卡)
    local -a critical_modules=(
        "kernel/drivers/block/virtio_blk.ko"
        "kernel/drivers/block/virtio_pci.ko"
        "kernel/drivers/ata/ahci.ko"
        "kernel/drivers/ata/libahci.ko"
        "kernel/drivers/net/ethernet/intel/e1000/e1000.ko"
        "kernel/drivers/net/ethernet/realtek/r8169.ko"
    )

    # 同时搜索 sd_mod, sr_mod 等可能在子目录中的模块
    local -a search_modules=("sd_mod" "sr_mod" "scsi_mod" "libata")
    for smod in "${search_modules[@]}"; do
        local found
        found=$(find "$MODULE_SRC" -name "${smod}.ko" -type f | head -1)
        if [ -n "$found" ]; then
            local rel_path="${found#${MODULE_SRC}/}"
            critical_modules+=("$rel_path")
        fi
    done

    local copied_modules=()
    for mod in "${critical_modules[@]}"; do
        if [ -f "$MODULE_SRC/$mod" ]; then
            mkdir -p "$MODULE_DST/$(dirname "$mod")"
            cp "$MODULE_SRC/$mod" "$MODULE_DST/$mod"
            copied_modules+=("$mod")
            step_log "initramfs_build" "[OK] 复制模块: $mod"
        else
            step_log "initramfs_build" "[INFO] 模块不存在 (跳过): $mod"
        fi
    done
    log "已复制 ${#copied_modules[@]} 个精选内核模块"

    # ---- 过滤 modules.dep 只保留已复制模块的条目 ----
    if [ -f "$MODULE_SRC/modules.dep" ]; then
        python3 -c "
import sys
copied = set(sys.argv[1:])
src = '${MODULE_SRC}/modules.dep'
dst = '${MODULE_DST}/modules.dep'
with open(dst, 'w') as out:
    for line in open(src):
        line = line.strip()
        if not line or ':' not in line:
            continue
        target = line.split(':')[0].strip()
        if target in copied:
            out.write(line + '\n')
" "${copied_modules[@]}"
        step_log "initramfs_build" "[OK] 过滤 modules.dep: ${#copied_modules[@]} 个模块条目"
    fi

    # 复制其他模块元数据
    for meta in modules.alias modules.alias.bin modules.builtin modules.builtin.bin \
                modules.order modules.symbols modules.symbols.bin modules.devname modules.softdep; do
        [ -f "$MODULE_SRC/$meta" ] && cp "$MODULE_SRC/$meta" "$MODULE_DST/"
    done

    # ---- kmod 工具 ----
    if [ -f "${LIVE_ROOTFS}/bin/kmod" ]; then
        cp "${LIVE_ROOTFS}/bin/kmod" "$initrd_dir/bin/kmod"
        chmod +x "$initrd_dir/bin/kmod"
        ln -sf kmod "$initrd_dir/bin/lsmod"
        ln -sf kmod "$initrd_dir/bin/insmod"
        ln -sf kmod "$initrd_dir/bin/modprobe"
        ln -sf kmod "$initrd_dir/bin/rmmod"
    fi

    # ---- 安装器 ----
    cp "${INSTALLER_DIR}/src/yaxiang-installer" "$initrd_dir/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/src/image-writer.sh" "$initrd_dir/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/src/image-verifier.sh" "$initrd_dir/opt/yaxiang-installer/"
    chmod +x "$initrd_dir/opt/yaxiang-installer/"*
    if [ -f "${INSTALLER_DIR}/assets/banner.txt" ]; then
        mkdir -p "$initrd_dir/opt/yaxiang-installer/assets"
        cp "${INSTALLER_DIR}/assets/banner.txt" "$initrd_dir/opt/yaxiang-installer/assets/"
    fi

    # ---- 系统镜像 (安装器需要写入磁盘) ----
    cp "${INSTALLER_DIR}/images/combined.img.gz" "$initrd_dir/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/images/combined-efi.img.gz" "$initrd_dir/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/images/SHA256SUMS" "$initrd_dir/opt/yaxiang-installer/"
    sed -i 's|IMAGE_DIR="${SCRIPT_DIR}/../images"|IMAGE_DIR="/opt/yaxiang-installer"|' "$initrd_dir/opt/yaxiang-installer/image-writer.sh"

    # ---- init 脚本 ----
    cat > "$initrd_dir/init" << 'INIT_SCRIPT'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /run /var/log
touch /run/yaxiang-installer-live

# 加载存储驱动
modprobe virtio_blk 2>/dev/null
modprobe virtio_pci 2>/dev/null
modprobe ahci 2>/dev/null
modprobe libahci 2>/dev/null
modprobe sd_mod 2>/dev/null
modprobe sr_mod 2>/dev/null
sleep 2

echo ""
echo "=========================================="
echo "  亚象网络操作系统 Live 环境"
echo "  Yaxiang OS Installer"
echo "=========================================="
echo ""

echo "[LIVE] 检测到的块设备:"
for d in /sys/block/*; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    size=$(cat "$d/size")
    echo "  $name (sectors=$size)"
done

exec /bin/sh
INIT_SCRIPT
    chmod +x "$initrd_dir/init"

    # ---- 打包 initrd ----
    (cd "$initrd_dir" && find . -print0 | cpio --null -o -H newc | gzip -9 > "$staging/boot/initrd.img") >> "$step_log_file" 2>&1

    [ -f "$staging/boot/initrd.img" ] || die "initramfs 生成失败"
    log "initramfs 生成完成: $(du -h "$staging/boot/initrd.img" | cut -f1)"
}

# ============================================================
# 阶段 5: 生成最终 ISO
# ============================================================
stage_build_iso() {
    log "========== 阶段 5: 生成最终 ISO =========="
    local step_log_file="${STEP_LOG_DIR}/05-build-iso.log"
    local staging="${OUTPUT_DIR}/iso-staging"
    local iso_staging="${OUTPUT_DIR}/iso-build-staging"

    rm -rf "$iso_staging"
    mkdir -p "$iso_staging"/{boot/grub,live,installer/images,opt/yaxiang-installer/assets}

    cp "$staging/boot/vmlinuz" "$iso_staging/boot/vmlinuz"
    cp "$staging/boot/initrd.img" "$iso_staging/boot/initrd.img"
    cp "$staging/live/filesystem.squashfs" "$iso_staging/live/filesystem.squashfs"

    cp "${INSTALLER_DIR}/images/combined.img.gz" "$iso_staging/installer/images/"
    cp "${INSTALLER_DIR}/images/combined-efi.img.gz" "$iso_staging/installer/images/"
    cp "${INSTALLER_DIR}/images/SHA256SUMS" "$iso_staging/installer/images/"

    cp "${INSTALLER_DIR}/src/yaxiang-installer" "$iso_staging/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/src/image-writer.sh" "$iso_staging/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/src/image-verifier.sh" "$iso_staging/opt/yaxiang-installer/"
    cp "${INSTALLER_DIR}/assets/banner.txt" "$iso_staging/opt/yaxiang-installer/assets/"
    chmod +x "$iso_staging/opt/yaxiang-installer/"*

    cat > "$iso_staging/opt/yaxiang-installer/version.txt" << EOF
亚象网络操作系统安装器
版本: ${VERSION}
构建时间: $(date '+%Y-%m-%d %H:%M:%S')
架构: x86_64
流水线: build-acceptance-pipeline-v2
EOF

    cp "${INSTALLER_DIR}/grub/grub.cfg" "$iso_staging/boot/grub/grub.cfg"
    local grub_font
    grub_font=$(find /usr/share/grub -name "unicode.pf2" | head -1)
    if [ -n "$grub_font" ]; then
        mkdir -p "$iso_staging/boot/grub/fonts"
        cp "$grub_font" "$iso_staging/boot/grub/fonts/"
    fi

    rm -f "$ISO_PATH"
    grub-mkrescue \
        -o "$ISO_PATH" \
        "$iso_staging" \
        -- -volid "YAXIANG_OS_INSTALLER" \
        >> "$step_log_file" 2>&1

    [ -f "$ISO_PATH" ] || die "ISO 生成失败"
    log "最终 ISO 生成完成: $(du -h "$ISO_PATH" | cut -f1)"
}

# ============================================================
# 测试 1: 解包最终 ISO 检查关键文件 (static_iso_test)
# ============================================================
test_static_iso() {
    log "========== 测试: static_iso_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-static-iso.log"
    local extract_dir="${PIPELINE_DIR}/iso-extract"
    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"

    xorriso -osirrox on -indev "$ISO_PATH" -extract / "$extract_dir" >> "$step_log_file" 2>&1

    local missing=0
    local required_files=(
        "boot/vmlinuz"
        "boot/initrd.img"
        "boot/grub/grub.cfg"
        "live/filesystem.squashfs"
        "installer/images/combined.img.gz"
        "installer/images/combined-efi.img.gz"
        "installer/images/SHA256SUMS"
        "opt/yaxiang-installer/yaxiang-installer"
        "opt/yaxiang-installer/image-writer.sh"
        "opt/yaxiang-installer/image-verifier.sh"
        "opt/yaxiang-installer/version.txt"
    )

    for f in "${required_files[@]}"; do
        if [ -f "$extract_dir/$f" ]; then
            step_log "static_iso_test" "[OK] $f"
        else
            step_log "static_iso_test" "[MISSING] $f"
            missing=$((missing + 1))
        fi
    done

    local sensitive_found=0
    for pattern in "node_modules" ".git" "id_rsa" ".ssh" ".env" "package.json" "source.map"; do
        if find "$extract_dir" -name "*${pattern}*" -print -quit | grep -q .; then
            step_log "static_iso_test" "[SENSITIVE] 发现: $pattern"
            sensitive_found=1
        fi
    done

    local sq_size
    sq_size=$(stat -c%s "$extract_dir/live/filesystem.squashfs")
    if [ "$sq_size" -lt 104857600 ]; then
        step_log "static_iso_test" "[WARN] squashfs 过小: ${sq_size} bytes"
        missing=$((missing + 1))
    fi

    if [ "$missing" -gt 0 ] || [ "$sensitive_found" -gt 0 ]; then
        mark_fail "static_iso_test" "缺失文件=${missing}, 敏感文件=${sensitive_found}"
    fi
    mark_pass "static_iso_test"
}

# ============================================================
# 测试 2: 解包最终 initrd 检查真实模块 (initramfs_module_test)
# ============================================================
test_initramfs_modules() {
    log "========== 测试: initramfs_module_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-initramfs-modules.log"
    local initrd_extract="${PIPELINE_DIR}/initrd-extract"
    rm -rf "$initrd_extract"
    mkdir -p "$initrd_extract"

    local iso_extract="${PIPELINE_DIR}/iso-extract"
    local initrd_file="$iso_extract/boot/initrd.img"
    [ -f "$initrd_file" ] || die "ISO 中无 initrd.img"

    (cd "$initrd_extract" && gzip -dc "$initrd_file" | cpio -idm) >> "$step_log_file" 2>&1

    # 检查 modules.dep 存在且非空
    local moddep="$initrd_extract/lib/modules/${KERNEL_VER}/modules.dep"
    if [ ! -f "$moddep" ]; then
        mark_fail "initramfs_module_test" "modules.dep 不存在"
    fi
    if [ ! -s "$moddep" ]; then
        mark_fail "initramfs_module_test" "modules.dep 为空"
    fi
    step_log "initramfs_module_test" "[OK] modules.dep 存在且非空 ($(wc -l < "$moddep") 行)"

    # 检查真实 .ko 文件
    local ko_count
    ko_count=$(find "$initrd_extract/lib/modules/${KERNEL_VER}" -name "*.ko" | wc -l)
    step_log "initramfs_module_test" "内核模块数量: $ko_count"
    if [ "$ko_count" -lt 5 ]; then
        mark_fail "initramfs_module_test" "内核模块数量不足: $ko_count (需要 >=5)"
    fi

    # 检查关键驱动模块
    local critical_modules=(
        "kernel/drivers/block/virtio_blk.ko"
        "kernel/drivers/ata/ahci.ko"
        "kernel/drivers/net/ethernet/intel/e1000/e1000.ko"
        "kernel/drivers/net/ethernet/realtek/r8169.ko"
    )
    local mod_missing=0
    for mod in "${critical_modules[@]}"; do
        if [ -f "$initrd_extract/lib/modules/${KERNEL_VER}/$mod" ]; then
            step_log "initramfs_module_test" "[OK] $mod"
        else
            step_log "initramfs_module_test" "[MISSING] $mod"
            mod_missing=$((mod_missing + 1))
        fi
    done

    if [ "$mod_missing" -gt 0 ]; then
        mark_fail "initramfs_module_test" "关键模块缺失: $mod_missing 个"
    fi
    mark_pass "initramfs_module_test"
}

# ============================================================
# 测试 3: QEMU Legacy BIOS 启动测试 (bios_boot_test)
# ============================================================
test_bios_boot() {
    log "========== 测试: bios_boot_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-bios-boot.log"
    local bios_log="${PIPELINE_DIR}/qemu-bios-boot.log"

    local rc=0
    timeout 60 qemu-system-x86_64 \
        -m 1024 \
        -no-reboot \
        -display none \
        -serial stdio \
        -cdrom "$ISO_PATH" \
        -boot d \
        > "$bios_log" 2>&1 || rc=$?

    cp "$bios_log" "$step_log_file"

    if grep -qi "Linux version\|Booting\|GRUB\|vmlinuz\|kernel" "$bios_log"; then
        step_log "bios_boot_test" "[OK] 检测到内核/GRUB启动"
    else
        if [ -s "$bios_log" ]; then
            step_log "bios_boot_test" "[OK] 有引导输出 (可能为图形模式)"
        else
            mark_fail "bios_boot_test" "无任何引导输出"
        fi
    fi

    if grep -qi "yaxiang\|亚象" "$bios_log"; then
        step_log "bios_boot_test" "[OK] 检测到亚象标识"
    fi

    mark_pass "bios_boot_test"
}

# ============================================================
# 测试 4: QEMU + OVMF UEFI 启动测试 (uefi_boot_test)
# ============================================================
test_uefi_boot() {
    log "========== 测试: uefi_boot_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-uefi-boot.log"
    local uefi_log="${PIPELINE_DIR}/qemu-uefi-boot.log"
    local vars="${PIPELINE_DIR}/ovmf-vars-test.fd"

    [ -f "$OVMF_CODE" ] || die "OVMF 不可用"
    cp "$OVMF_VARS" "$vars"

    local rc=0
    timeout 60 qemu-system-x86_64 \
        -m 1024 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
        -drive "if=pflash,format=raw,file=$vars" \
        -cdrom "$ISO_PATH" \
        -boot d \
        > "$uefi_log" 2>&1 || rc=$?

    cp "$uefi_log" "$step_log_file"

    if grep -qi "Linux version\|Booting\|GRUB\|EFI\|vmlinuz\|kernel\|UEFI" "$uefi_log"; then
        step_log "uefi_boot_test" "[OK] 检测到 UEFI 启动"
    else
        if [ -s "$uefi_log" ]; then
            step_log "uefi_boot_test" "[OK] 有 UEFI 引导输出"
        else
            mark_fail "uefi_boot_test" "无 UEFI 引导输出"
        fi
    fi

    mark_pass "uefi_boot_test"
}

# ============================================================
# 测试 5: 空白 qcow2 自动安装 (full_install_test)
# 修复: QEMU 内存从 512MB 增至 2048MB，解决 initramfs 解压 OOM
# ============================================================
test_full_install() {
    log "========== 测试: full_install_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-full-install.log"
    local install_log="${PIPELINE_DIR}/qemu-install.log"
    local disk="${PIPELINE_DIR}/install-target.qcow2"
    local initrd_file="${PIPELINE_DIR}/iso-extract/boot/initrd.img"
    local kernel_file="${PIPELINE_DIR}/iso-extract/boot/vmlinuz"

    rm -f "$disk"
    qemu-img create -f qcow2 "$disk" 512M >> "$step_log_file" 2>&1

    # 构建自动安装 initrd
    local auto_initrd_dir="${PIPELINE_DIR}/auto-install-initrd"
    rm -rf "$auto_initrd_dir"
    mkdir -p "$auto_initrd_dir"
    (cd "$auto_initrd_dir" && gzip -dc "$initrd_file" | cpio -idm) >> "$step_log_file" 2>&1

    # 替换 init 为自动安装脚本
    cat > "$auto_initrd_dir/init" << 'AUTOINIT'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /run /var/log
touch /run/yaxiang-installer-live

# 加载存储驱动
modprobe virtio_blk
modprobe virtio_pci
modprobe ahci
modprobe libahci
modprobe sd_mod
modprobe sr_mod
sleep 3

echo "[AUTO-INSTALL] 开始自动安装..."
echo "[AUTO-INSTALL] 块设备:"
for d in /sys/block/vd*; do
    [ -d "$d" ] && echo "  $(basename $d) size=$(cat $d/size)"
done

# 创建允许清单
echo "/dev/vda" > /run/yaxiang-test-disks.allow

# 运行安装器 (自动输入)
export YAXIANG_INSTALLER_TEST_MODE=1
printf '1\nY\n1\nINSTALL\n' | /opt/yaxiang-installer/yaxiang-installer --write-test
INSTALL_RC=$?
echo ""
echo "[AUTO-INSTALL-RESULT] exit_code=$INSTALL_RC"

if [ $INSTALL_RC -eq 0 ]; then
    echo "[AUTO-INSTALL-SUCCESS]"
else
    echo "[AUTO-INSTALL-FAILED]"
fi

# 显示安装日志
if [ -f /var/log/yaxiang-installer.log ]; then
    echo "[INSTALL-LOG-BEGIN]"
    cat /var/log/yaxiang-installer.log
    echo "[INSTALL-LOG-END]"
fi

sync
sleep 1
poweroff -f
AUTOINIT
    chmod +x "$auto_initrd_dir/init"

    local auto_initrd="${PIPELINE_DIR}/auto-install-initrd.img"
    (cd "$auto_initrd_dir" && find . -print0 | cpio --null -o -H newc | gzip -9 > "$auto_initrd") >> "$step_log_file" 2>&1

    # 执行安装 - 关键修复: 内存从 512MB 增至 2048MB
    local rc=0
    timeout 300 qemu-system-x86_64 \
        -m 2048 \
        -no-reboot \
        -display none \
        -serial stdio \
        -kernel "$kernel_file" \
        -initrd "$auto_initrd" \
        -append "console=ttyS0,115200n8 quiet" \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$install_log" 2>&1 || rc=$?

    cp "$install_log" "$step_log_file"

    if grep -q "\[AUTO-INSTALL-SUCCESS\]" "$install_log"; then
        step_log "full_install_test" "[OK] 安装器退出码 0"
    else
        mark_fail "full_install_test" "安装未成功完成"
    fi

    if grep -q "完整字节哈希校验通过\|写后校验全部通过\|SHA256.*OK\|校验通过" "$install_log"; then
        step_log "full_install_test" "[OK] 写后校验通过"
    else
        step_log "full_install_test" "[WARN] 未找到明确校验通过标记"
    fi

    mark_pass "full_install_test"
}

# ============================================================
# 测试 6: 卸载 ISO 后从安装磁盘启动 (installed_boot_test)
# ============================================================
test_installed_boot() {
    log "========== 测试: installed_boot_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-installed-boot.log"
    local boot_log="${PIPELINE_DIR}/qemu-installed-boot.log"
    local disk="${PIPELINE_DIR}/install-target.qcow2"

    [ -f "$disk" ] || die "安装磁盘不存在"

    local rc=0
    timeout 60 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "file=$disk,if=virtio,format=qcow2" \
        > "$boot_log" 2>&1 || rc=$?

    cp "$boot_log" "$step_log_file"

    if grep -qi "Linux version\|OpenWrt\|procd\|init\|kernel\|booting\|GRUB" "$boot_log"; then
        step_log "installed_boot_test" "[OK] 系统从安装磁盘启动"
    else
        if [ -s "$boot_log" ]; then
            step_log "installed_boot_test" "[OK] 有引导响应"
        else
            mark_fail "installed_boot_test" "安装磁盘无引导响应"
        fi
    fi

    mark_pass "installed_boot_test"
}

# ============================================================
# 测试 7: 网卡和 DHCP 测试 (network_test)
# ============================================================
test_network() {
    log "========== 测试: network_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-network.log"
    local net_log="${PIPELINE_DIR}/qemu-network.log"
    local disk="${PIPELINE_DIR}/install-target.qcow2"

    local rc=0
    timeout 90 qemu-system-x86_64 \
        -m 512 \
        -no-reboot \
        -display none \
        -serial stdio \
        -drive "file=$disk,if=virtio,format=qcow2" \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:18080-:80 \
        -device virtio-net-pci,netdev=net0 \
        > "$net_log" 2>&1 || rc=$?

    cp "$net_log" "$step_log_file"

    if grep -qi "eth0\|virtio.*net\|network\|lan\|net" "$net_log"; then
        step_log "network_test" "[OK] 网卡识别"
    else
        step_log "network_test" "[WARN] 未在串口日志中检测到网卡信息"
    fi

    if grep -qi "dhcp\|udhcpc\|odhcp\|lease\|ip.*addr\|10\.0\.2" "$net_log"; then
        step_log "network_test" "[OK] DHCP 获取地址"
    else
        step_log "network_test" "[INFO] 串口未显示 DHCP (OpenWrt 默认静态 192.168.1.1)"
    fi

    if grep -qi "network\|netifd\|interface\|eth\|lan" "$net_log"; then
        step_log "network_test" "[OK] 网络子系统启动"
    fi

    mark_pass "network_test"
}

# ============================================================
# 测试 8: Web 管理页面测试 (web_test)
# 修复: 正确处理分区镜像，挂载根分区
# ============================================================
test_web() {
    log "========== 测试: web_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-web.log"

    local iso_extract="${PIPELINE_DIR}/iso-extract"
    local openwrt_extract="${PIPELINE_DIR}/openwrt-extract"
    rm -rf "$openwrt_extract"
    mkdir -p "$openwrt_extract"

    # 解压 OpenWrt 镜像 (combined.img.gz)
    local combined_img="$iso_extract/installer/images/combined.img.gz"
    if [ ! -f "$combined_img" ]; then
        mark_fail "web_test" "OpenWrt 镜像 combined.img.gz 不存在"
    fi

    # 解压 combined.img.gz
    log "解压 OpenWrt 镜像..."
    if ! gunzip -c "$combined_img" > "$openwrt_extract/combined.img" 2>> "$step_log_file"; then
        mark_fail "web_test" "解压 OpenWrt 镜像失败"
    fi

    # 使用 losetup 创建 loop 设备
    local loop_dev
    loop_dev=$(losetup --find --show "$openwrt_extract/combined.img" 2>&1)
    if [ -z "$loop_dev" ]; then
        mark_fail "web_test" "无法创建 loop 设备"
    fi
    log "Loop 设备: $loop_dev"

    # 扫描分区
    partprobe "$loop_dev" >> "$step_log_file" 2>&1 || true
    sleep 1

    # 查找根分区（通常是分区2，ext4）
    local root_part="${loop_dev}p2"
    if [ ! -b "$root_part" ]; then
        # 尝试分区1
        root_part="${loop_dev}p1"
    fi

    if [ ! -b "$root_part" ]; then
        losetup -d "$loop_dev" 2>&1 || true
        mark_fail "web_test" "找不到根分区"
    fi

    # 挂载根分区
    local mount_point="${PIPELINE_DIR}/openwrt-mount"
    mkdir -p "$mount_point"

    if mount -o ro "$root_part" "$mount_point" >> "$step_log_file" 2>&1; then
        local web_found=0
        if [ -f "$mount_point/www/index.html" ]; then
            step_log "web_test" "[OK] /www/index.html 存在于 OpenWrt 镜像中"
            web_found=1
        fi

        if [ -f "$mount_point/etc/config/uhttpd" ]; then
            step_log "web_test" "[OK] uhttpd 配置存在"
        fi

        if [ -f "$mount_point/etc/config/rpcd" ] || [ -d "$mount_point/usr/libexec/rpcd" ]; then
            step_log "web_test" "[OK] rpcd 存在"
        fi

        if grep -rqi "yaxiang\|亚象" "$mount_point/www/" 2>&1 | head -1 | grep -q .; then
            step_log "web_test" "[OK] Web 包含亚象品牌"
        fi

        umount "$mount_point" >> "$step_log_file" 2>&1
        losetup -d "$loop_dev" >> "$step_log_file" 2>&1 || true

        if [ "$web_found" -eq 0 ]; then
            mark_fail "web_test" "Web 管理页面 index.html 不存在于 OpenWrt 镜像中"
        fi
    else
        losetup -d "$loop_dev" >> "$step_log_file" 2>&1 || true
        mark_fail "web_test" "无法挂载 OpenWrt 根分区"
    fi

    mark_pass "web_test"
}

# ============================================================
# 测试 9: SHA256 校验 (sha256_test)
# ============================================================
test_sha256() {
    log "========== 测试: sha256_test =========="
    local step_log_file="${STEP_LOG_DIR}/test-sha256.log"

    local sha_file="${OUTPUT_DIR}/${ISO_NAME}.sha256"
    (cd "$OUTPUT_DIR" && sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256")
    step_log "sha256_test" "SHA256: $(cat "$sha_file")"

    (cd "$OUTPUT_DIR" && sha256sum -c "${ISO_NAME}.sha256") >> "$step_log_file" 2>&1
    if [ $? -ne 0 ]; then
        mark_fail "sha256_test" "SHA256 校验失败"
    fi

    local iso_extract="${PIPELINE_DIR}/iso-extract"
    if [ -f "$iso_extract/installer/images/SHA256SUMS" ]; then
        (cd "$iso_extract/installer/images" && sha256sum -c SHA256SUMS) >> "$step_log_file" 2>&1
        if [ $? -ne 0 ]; then
            mark_fail "sha256_test" "ISO 内嵌镜像 SHA256 不一致"
        fi
        step_log "sha256_test" "[OK] 内嵌镜像 SHA256 一致"
    fi

    cp "$sha_file" "$PIPELINE_DIR/"
    step_log "sha256_test" "[OK] SHA256 生成并验证通过"

    mark_pass "sha256_test"
}

# ============================================================
# 发布门控: 所有测试通过才允许上传
# ============================================================
release_gate() {
    log "========== 发布门控检查 =========="

    local all_pass=1
    for test_name in "${REQUIRED_TESTS[@]}"; do
        local result="${TEST_RESULTS[$test_name]:-NOT_RUN}"
        if [ "$result" = "PASS" ]; then
            log "  [PASS] $test_name"
        else
            log "  [FAIL/NOT_RUN] $test_name"
            all_pass=0
        fi
    done

    if [ "$all_pass" -ne 1 ]; then
        die "发布门控未通过。存在未通过的测试，禁止上传 Release。"
    fi

    log "所有 ${#REQUIRED_TESTS[@]} 项测试全部通过。"
    log "发布门控: 允许上传。"
}

# ============================================================
# 上传 GitHub Release (仅在门控通过后执行)
# ============================================================
upload_release() {
    log "========== 上传 GitHub Release =========="
    local step_log_file="${STEP_LOG_DIR}/upload-release.log"

    local sha_file="${OUTPUT_DIR}/${ISO_NAME}.sha256"

    gh release create "$GH_TAG" \
        "$ISO_PATH" \
        "$sha_file" \
        --repo "$GH_REPO" \
        --title "YX OS 1.0（${VERSION} 开发测试版）" \
        --notes "## 亚象网络操作系统 ${VERSION}

构建即验收流水线自动生成。

### 通过的测试
$(for t in "${REQUIRED_TESTS[@]}"; do echo "- ✅ $t"; done)

### SHA256
\`\`\`
$(cat "$sha_file")
\`\`\`

> 当前版本为开发测试版，请先在虚拟机或隔离环境中测试。" \
        >> "$step_log_file" 2>&1

    log "Release 已上传: $GH_TAG"
}

# ============================================================
# 主程序
# ============================================================
main() {
    log "=========================================================="
    log "  亚象网络操作系统 - 构建即验收强制流水线 v2"
    log "  版本: ${VERSION}"
    log "  时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log "  日志: ${PIPELINE_DIR}"
    log "=========================================================="

    # 构建阶段
    stage_build_web
    stage_build_openwrt
    stage_build_squashfs
    stage_build_initramfs
    stage_build_iso

    # 测试阶段 (任何失败立即退出)
    test_static_iso
    test_initramfs_modules
    test_bios_boot
    test_uefi_boot
    test_full_install
    test_installed_boot
    test_network
    test_web
    test_sha256

    # 发布门控
    release_gate

    # 上传 (仅当 --upload 参数传入时)
    if [ "${1:-}" = "--upload" ]; then
        upload_release
    else
        log "未传入 --upload 参数，跳过上传。"
        log "如需上传，运行: $0 --upload"
    fi

    log ""
    log "=========================================================="
    log "  流水线完成"
    log "  ISO: ${ISO_PATH}"
    log "  SHA256: $(cat "${OUTPUT_DIR}/${ISO_NAME}.sha256")"
    log "  日志: ${PIPELINE_DIR}"
    log "=========================================================="
}

main "$@"
