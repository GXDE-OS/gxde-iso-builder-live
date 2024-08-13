#!/bin/bash
programPath=$(dirname $0; pwd)
debianRootfsPath=debian-rootfs
sudo apt install debootstrap debian-archive-keyring \
    debian-ports-archive-keyring qemu-user-static -y
# 构建核心系统
if [[ $1 == loong64 ]]; then
    sudo debootstrap --arch $1 unstable $debianRootfsPath https://mirror.sjtu.edu.cn/debian-ports/
else
    sudo debootstrap --arch $1 bookworm $debianRootfsPath https://mirrors.tuna.tsinghua.edu.cn/debian/
fi
# 写入源
if [[ $1 == loong64 ]]; then
    sudo cp $programPath/debian-port.list $debianRootfsPath/etc/apt/sources.list.d/debian.list -v
else
    sudo cp $programPath/debian-unreleased.list $debianRootfsPath/etc/apt/sources.list.d/debian-unreleased.list -v
fi
sudo sed -i "s/main/main contrib non-free non-free-firmware/g" $debianRootfsPath/etc/apt/sources.list
sudo cp $programPath/gxde-temp.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
# 安装应用
sudo $programPath/pardus-chroot $debianRootfsPath
sudo chroot $debianRootfsPath apt update
sudo chroot $debianRootfsPath apt install gxde-desktop deepin-installer --install-recommends -y
sudo chroot $debianRootfsPath sudo apt install live-task-recommended live-task-standard live-config-systemd \
    live-boot -y
sudo chroot $debianRootfsPath sudo apt install spark-store spark-deepin-wine-runner -y
sudo chroot $debianRootfsPath sudo apt autopurge wine -y
sudo chroot $debianRootfsPath sudo aptss update
sudo chroot $debianRootfsPath sudo aptss full-upgrade -y
# 卸载无用应用
sudo chroot $debianRootfsPath sudo apt install deepin-terminal -y
sudo chroot $debianRootfsPath sudo apt purge mlterm deepin-terminal-gtk -y
# 安装内核
if [[ $1 == loong64 ]]; then
    # loong64 安装定制的内核
    sudo chroot $debianRootfsPath apt install linux-kernel-gxde-loong64 -y
else
    sudo chroot $debianRootfsPath apt install linux-image-amd64 linux-headers-amd64 -y
fi
sudo chroot $debianRootfsPath apt install linux-firmware -y
sudo chroot $debianRootfsPath apt install firmware-linux -y
# 清空临时文件
sudo chroot $debianRootfsPath apt autopurge -y
sudo chroot $debianRootfsPath apt clean
sudo rm -rf $debianRootfsPath/var/log/*
sudo rm -rf $debianRootfsPath/root/.bash_history
sudo rm -rf $debianRootfsPath/etc/apt/sources.list.d/temp.list
# 卸载文件
sudo umount "$debianRootfsPath/sys/firmware/efi/efivars"
sudo umount "$debianRootfsPath/sys"
sudo umount "$debianRootfsPath/dev/pts"
sudo umount "$debianRootfsPath/dev/shm"
sudo umount "$debianRootfsPath/dev"

sudo umount "$debianRootfsPath/sys/firmware/efi/efivars"
sudo umount "$debianRootfsPath/sys"
sudo umount "$debianRootfsPath/dev/pts"
sudo umount "$debianRootfsPath/dev/shm"
sudo umount "$debianRootfsPath/dev"

sudo umount "$debianRootfsPath/run"
sudo umount "$debianRootfsPath/media"
sudo umount "$debianRootfsPath/proc"
sudo umount "$debianRootfsPath/tmp"
# 封装
cd $debianRootfsPath
sudo mksquashfs * ../filesystem.squashfs