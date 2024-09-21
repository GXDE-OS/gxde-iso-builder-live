#!/bin/bash
function chrootCommand() {
    for i in {1..5};
    do
        sudo chroot $debianRootfsPath "$@"
        if [[ $? == 0 ]]; then
            break
        fi
        sleep 1
    done
}
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
#du -h filesystem.squashfs
# 构建 ISO
if [[ ! -f iso-template/$1-build.sh ]]; then
    echo 不存在 $1 架构的构建模板，不进行构建
    exit
fi
cd iso-template/$1
# 清空废弃文件
rm -rfv live/*
rm -rfv deb/*/
mkdir -p live
mkdir -p deb
# 添加 deb 包
cd deb
./addmore.py ../../../grub-deb/*.deb
cd ..
# 拷贝内核
# 获取内核数量
kernelNumber=$(ls -1 ../../$debianRootfsPath/boot/vmlinuz-* | wc -l)
vmlinuzList=($(ls -1 ../../$debianRootfsPath/boot/vmlinuz-* | sort -rV))
initrdList=($(ls -1 ../../$debianRootfsPath/boot/initrd.img-* | sort -rV))
for i in $( seq 0 $(expr $kernelNumber - 1) )
do
    if [[ $i == 0 ]]; then
        cp ../../$debianRootfsPath/boot/${vmlinuzList[i]} live/vmlinuz -v
        cp ../../$debianRootfsPath/boot/${initrdList[i]} live/initrd.img -v
    fi
    if [[ $i == 1 ]]; then
        cp ../../$debianRootfsPath/boot/${vmlinuzList[i]} live/vmlinuz-oldstable -v
        cp ../../$debianRootfsPath/boot/${initrdList[i]} live/initrd.img-oldstable -v
    fi
done
sudo mv ../../filesystem.squashfs live/filesystem.squashfs -v
cd ..
bash $1-build.sh
mv gxde.iso ..
cd ..
du -h gxde.iso