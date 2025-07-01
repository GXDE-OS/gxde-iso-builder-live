#!/bin/bash
function installWithAptss() {
    if [[ $isUnAptss == 1 ]]; then
        chrootCommand apt "$@"
    else
        chrootCommand aptss "$@"
    fi
}
function chrootCommand() {
    for i in {1..5};
    do
        sudo env DEBIAN_FRONTEND=noninteractive chroot $debianRootfsPath "$@"
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
function buildDebianRootf() {
    if [[ $1 == loong64 ]]; then
        sudo debootstrap --no-check-gpg --keyring=/usr/share/keyrings/debian-ports-archive-keyring.gpg \
            --include=debian-ports-archive-keyring,debian-archive-keyring,sudo,vim \
            --arch $1 unstable $debianRootfsPath https://mirrors.nju.edu.cn/debian-ports/
        if [[ $? != 0 ]]; then
            sudo apt install squashfs-tools git aria2 -y
            aria2c -x 16 -s 16 https://repo.gxde.top/TGZ/debian-base-loong64/debian-base-loong64.squashfs
            sudo unsquashfs debian-base-loong64.squashfs
            sudo rm -rf $debianRootfsPath/
            sudo mv squashfs-root $debianRootfsPath -v
        fi
    else
        sudo debootstrap --arch $1 \
            --include=debian-ports-archive-keyring,debian-archive-keyring,sudo,vim \
            $2 $debianRootfsPath https://mirrors.cernet.edu.cn/debian/
    fi
}
programPath=$(cd $(dirname $0); pwd)
debianRootfsPath=debian-rootfs
codeName=hetao
if [[ $1 == "" ]]; then
    echo 请指定架构：i386 amd64 arm64 mips64el loong64
    echo 还可以代号以构建内测镜像
    echo "如 $0  amd64  [tianlu] [aptss(可选)] 顺序不能乱"
    exit 1
fi
if [[ -d $debianRootfsPath ]]; then
    UNMount $debianRootfsPath
    sudo rm -rf $debianRootfsPath
fi
export isUnAptss=0
sudo rm -rf grub-deb
sudo apt install debian-archive-keyring debian-ports-archive-keyring -y
sudo apt install debootstrap  \
    qemu-user-static genisoimage xorriso \
    squashfs-tools -y
# 构建核心系统
set +e
case $codeName in
    "tianlu")
        buildDebianRootf $1 bookworm
        sudo cp $programPath/gxde-temp-bixie.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "bixie")
        buildDebianRootf $1 bookworm
        sudo cp $programPath/gxde-temp-bixie.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "lizhi")
        buildDebianRootf $1 trixie
        sudo cp $programPath/gxde-temp-lizhi.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "zhuangzhuang")
        buildDebianRootf $1 trixie
        sudo cp $programPath/gxde-temp-lizhi.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "meimei")
        if [[ ! -e /usr/share/debootstrap/scripts/loongnix ]]; then
            sudo cp loongnix /usr/share/debootstrap/scripts/ -v
        fi
        sudo debootstrap --no-check-gpg --arch $1 \
            --include=debian-ports-archive-keyring,debian-archive-keyring,sudo,vim \
            loongnix $debianRootfsPath https://pkg.loongnix.cn/loongnix/25
        sudo cp $programPath/gxde-temp-meimei.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "hetao")
        if [[ ! -e /usr/share/debootstrap/scripts/loongnix ]]; then
                sudo cp crimson /usr/share/debootstrap/scripts/ -v
        fi
        sudo debootstrap --no-check-gpg --arch $1 \
            --include=deepin-keyring,sudo,vim \
            crimson $debianRootfsPath https://mirrors.hit.edu.cn/deepin/beige/
        sudo cp $programPath/gxde-temp-hetao.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
        sudo sed -i "s/main/main commercial community/g" $debianRootfsPath/etc/apt/sources.list
    ;;
    *)
        buildDebianRootf $1 bookworm
        sudo cp $programPath/gxde-temp-bixie.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
esac

# 修改系统主机名
echo "gxde-os-live" | sudo tee $debianRootfsPath/etc/hostname
# 写入源
if [[ $codeName == "" ]] || [[ $codeName == "tianlu" ]] || [[ $codeName == "bixie" ]]; then
    if [[ $1 == loong64 ]]; then
        sudo cp $programPath/debian-unreleased.list $debianRootfsPath/etc/apt/sources.list -v
    else
        sudo cp $programPath/debian.list $debianRootfsPath/etc/apt/sources.list -v
        #sudo cp $programPath/debian-backports.list $debianRootfsPath/etc/apt/sources.list.d/debian-backports.list -v
        sudo cp $programPath/99bookworm-backports $debianRootfsPath/etc/apt/preferences.d/ -v
    fi
fi
#sudo cp $programPath/os-release $debianRootfsPath/usr/lib/os-release
if [[ $codeName != "hetao" ]]; then
    sudo sed -i "s/main/main contrib non-free non-free-firmware/g" $debianRootfsPath/etc/apt/sources.list
fi


set +e
# 安装应用

sudo $programPath/pardus-chroot $debianRootfsPath
chrootCommand apt update -o Acquire::Check-Valid-Until=false
chrootCommand apt install sudo vim --no-install-recommends -y
chrootCommand apt install gxde-source --no-install-recommends -y
chrootCommand rm -rfv /etc/apt/sources.list.d/temp.list
chrootCommand apt update -o Acquire::Check-Valid-Until=false

chrootCommand apt install aptss --no-install-recommends -y
chrootCommand aptss update -o Acquire::Check-Valid-Until=false

# 
installWithAptss install gxde-desktop-live --no-install-recommends -y
# 启用 lightdm
chrootCommand systemctl enable lightdm

installWithAptss install linux-kernel-hwe-gxde-$1 --no-install-recommends -y

# 拷贝 kernel
mkdir kernel
sudo cp $debianRootfsPath/boot/initrd.img-* kernel/initrd.img -v
sudo cp $debianRootfsPath/boot/vmlinuz-* kernel/vmlinuz -v

# 卸载内核
installWithAptss autopurge linux-kernel-hwe-gxde-$1 linux-image-* linux-headers-* -y

# 禁用 nmbd
chrootCommand systemctl disable nmbd

# 清空临时文件
installWithAptss autopurge fonts-noto-extra fonts-noto-ui-extra fonts-noto-cjk-extra -y
installWithAptss autopurge -y
installWithAptss clean

# 清空临时文件
installWithAptss clean
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
sudo mksquashfs * ../filesystem.squashfs -comp xz -Xbcj x86
cd ..
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
# 拷贝内核
# 获取内核数量
cp ../../kernel/vmlinuz live/vmlinuz -v
cp ../../kernel/initrd.img live/initrd.img -v

sudo mv ../../filesystem.squashfs live/filesystem.squashfs -v
cd ..
bash $1-build.sh
mv gxde.iso ../gxde-live.iso
cd ..
du -h gxde-live.iso
