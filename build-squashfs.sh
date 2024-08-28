#!/bin/bash
function UNMount() {
    sudo umount "$1/sys/firmware/efi/efivars"
    sudo umount "$1/sys"
    sudo umount "$1/dev/pts"
    sudo umount "$1/dev/shm"
    sudo umount "$1/dev"

    sudo umount "$1/sys/firmware/efi/efivars"
    sudo umount "$1/sys"
    sudo umount "$1/dev/pts"
    sudo umount "$1/dev/shm"
    sudo umount "$1/dev"

    sudo umount "$1/run"
    sudo umount "$1/media"
    sudo umount "$1/proc"
    sudo umount "$1/tmp"
}
programPath=$(cd $(dirname $0); pwd)
debianRootfsPath=debian-rootfs
if [[ $1 == "" ]]; then
    echo 请指定架构：amd64 arm64 loong64
    exit 1
fi
if [[ -d $debianRootfsPath ]]; then
    UNMount $debianRootfsPath
    sudo rm -rf $debianRootfsPath
fi
sudo apt install debootstrap debian-archive-keyring \
    debian-ports-archive-keyring qemu-user-static -y
# 构建核心系统
set -e
if [[ $1 == loong64 ]]; then
    sudo debootstrap --arch $1 unstable $debianRootfsPath https://mirror.sjtu.edu.cn/debian-ports/
else
    sudo debootstrap --arch $1 bookworm $debianRootfsPath https://mirrors.tuna.tsinghua.edu.cn/debian/
fi
# 写入源
if [[ $1 == loong64 ]]; then
    sudo cp $programPath/debian-unreleased.list $debianRootfsPath/etc/apt/sources.list.d/debian-unreleased.list -v
else
    sudo cp $programPath/debian.list $debianRootfsPath/etc/apt/sources.list.d/debian.list -v
    sudo cp $programPath/debian-backports.list $debianRootfsPath/etc/apt/sources.list.d/debian-backports.list -v
    sudo cp $programPath/99bookworm-backports $debianRootfsPath/etc/apt/preferences.d/ -v
fi
sudo sed -i "s/main/main contrib non-free non-free-firmware/g" $debianRootfsPath/etc/apt/sources.list
sudo cp $programPath/gxde-temp.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
set +e
# 安装应用
sudo $programPath/pardus-chroot $debianRootfsPath
sudo chroot $debianRootfsPath apt install debian-ports-archive-keyring debian-archive-keyring -y
sudo chroot $debianRootfsPath apt update
if [[ $2 == "unstable" ]]; then
    sudo chroot $debianRootfsPath apt install gxde-testing-source -y
    sudo chroot $debianRootfsPath apt update
fi
sudo chroot $debianRootfsPath apt install gxde-desktop calamares-settings-gxde --install-recommends -y
sudo rm -rf $debianRootfsPath/var/lib/dpkg/info/plymouth-theme-gxde-logo.postinst
sudo chroot $debianRootfsPath apt install live-task-recommended live-task-standard live-config-systemd \
    live-boot -y
sudo chroot $debianRootfsPath apt install fcitx5-pinyin libudisks2-qt5-0 fcitx5 -y
sudo chroot $debianRootfsPath apt install spark-store -y
sudo chroot $debianRootfsPath aptss update
#sudo chroot $debianRootfsPath aptss install spark-deepin-wine-runner -y
sudo chroot $debianRootfsPath aptss full-upgrade -y
if [[ $1 == loong64 ]]; then
    sudo chroot $debianRootfsPath aptss install cn.loongnix.lbrowser -y
else
    sudo chroot $debianRootfsPath apt install chromium chromium-l10n -y
fi
#if [[ $1 == arm64 ]] || [[ $1 == loong64 ]]; then
#    sudo chroot $debianRootfsPath aptss install spark-box64 -y
#fi
sudo chroot $debianRootfsPath apt install grub-efi network-manager-gnome -y
sudo chroot $debianRootfsPath apt install grub-efi-$1 -y
# 卸载无用应用
sudo chroot $debianRootfsPath apt purge mlterm mlterm-tiny deepin-terminal-gtk deepin-terminal ibus systemsettings -y
# 安装内核
if [[ $1 != amd64 ]]; then
    sudo chroot $debianRootfsPath apt autopurge "linux-image-*" "linux-headers-*" -y
fi
sudo chroot $debianRootfsPath apt install linux-kernel-gxde-$1 -y
sudo chroot $debianRootfsPath apt install linux-firmware -y
sudo chroot $debianRootfsPath apt install firmware-linux -y
# 清空临时文件
sudo chroot $debianRootfsPath apt autopurge -y
sudo chroot $debianRootfsPath apt clean
sudo touch $debianRootfsPath/etc/deepin/calamares
sudo rm $debianRootfsPath/etc/apt/sources.list.d/debian.list -rf
sudo rm $debianRootfsPath/etc/apt/sources.list.d/debian-backports.list -rf
sudo rm -rf $debianRootfsPath/var/log/*
sudo rm -rf $debianRootfsPath/root/.bash_history
sudo rm -rf $debianRootfsPath/etc/apt/sources.list.d/temp.list
sudo rm -rf $debianRootfsPath/initrd.img.old
sudo rm -rf $debianRootfsPath/vmlinuz.old
# 卸载文件
sleep 5
UNMount $debianRootfsPath
# 封装
cd $debianRootfsPath
set -e
sudo rm -rf ../filesystem.squashfs
sudo mksquashfs * ../filesystem.squashfs
cd ..
du -h filesystem.squashfs
