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
programPath=$(cd $(dirname $0); pwd)
debianRootfsPath=debian-rootfs
if [[ $1 == "" ]]; then
    echo 请指定架构：i386 amd64 arm64 mips64el loong64
    echo 还可以再加一个参数：unstable 以构建内测镜像
    echo "如 $0  amd64  [unstable] [aptss(可选)] 顺序不能乱"
    exit 1
fi
if [[ -d $debianRootfsPath ]]; then
    UNMount $debianRootfsPath
    sudo rm -rf $debianRootfsPath
fi
export isUnAptss=1
if [[ $1 == aptss ]] || [[ $2 == aptss ]]|| [[ $3 == aptss ]]; then
    export isUnAptss=0
fi
sudo rm -rf grub-deb
sudo apt install debootstrap debian-archive-keyring \
    debian-ports-archive-keyring qemu-user-static genisoimage \
    squashfs-tools -y
# 构建核心系统
set -e
if [[ $1 == loong64 ]]; then
    sudo debootstrap --no-check-gpg --keyring=/usr/share/keyrings/debian-ports-archive-keyring.gpg --arch $1 unstable $debianRootfsPath https://packages.gxde.org/debian-loong64/
else
    sudo debootstrap --arch $1 bookworm $debianRootfsPath https://mirrors.tuna.tsinghua.edu.cn/debian/
fi
# 修改系统主机名
echo "gxde-os" | sudo tee $debianRootfsPath/etc/hostname
# 写入源
if [[ $1 == loong64 ]]; then
    sudo cp $programPath/debian-unreleased.list $debianRootfsPath/etc/apt/sources.list -v
else
    sudo cp $programPath/debian.list $debianRootfsPath/etc/apt/sources.list -v
    #sudo cp $programPath/debian-backports.list $debianRootfsPath/etc/apt/sources.list.d/debian-backports.list -v
    sudo cp $programPath/99bookworm-backports $debianRootfsPath/etc/apt/preferences.d/ -v
fi
sudo cp $programPath/os-release $debianRootfsPath/usr/lib/os-release
sudo sed -i "s/main/main contrib non-free non-free-firmware/g" $debianRootfsPath/etc/apt/sources.list
sudo cp $programPath/gxde-temp.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
set +e
# 安装应用

sudo $programPath/pardus-chroot $debianRootfsPath
chrootCommand apt install debian-ports-archive-keyring -y
chrootCommand apt install debian-archive-keyring -y
chrootCommand apt update -o Acquire::Check-Valid-Until=false
if [[ $2 == "unstable" ]]; then
    chrootCommand apt install gxde-testing-source -y
    chrootCommand apt update -o Acquire::Check-Valid-Until=false
fi
chrootCommand apt install aptss -y
chrootCommand aptss update -o Acquire::Check-Valid-Until=false

# 
installWithAptss install gxde-desktop --install-recommends -y
if [[ $1 != "mips64el" ]]; then
    installWithAptss install calamares-settings-gxde --install-recommends -y
else
    installWithAptss install gxde-installer --install-recommends -y
fi

sudo rm -rf $debianRootfsPath/var/lib/dpkg/info/plymouth-theme-gxde-logo.postinst
installWithAptss install live-task-recommended live-task-standard live-config-systemd \
    live-boot -y
installWithAptss install fcitx5-pinyin libudisks2-qt5-0 fcitx5 -y
# 
if [[ $1 != "i386" ]]; then
    chrootCommand apt install spark-store -y
else
    if [[ $1 == "mips64el" ]]; then
        chrootCommand apt install loongsonapplication -y
    else
        chrootCommand apt install aptss -y
    fi
fi

installWithAptss update -o Acquire::Check-Valid-Until=false

installWithAptss full-upgrade -y
if [[ $1 == loong64 ]]; then
    chrootCommand aptss install cn.loongnix.lbrowser -y
elif [[ $1 == amd64 ]];then
    chrootCommand aptss install firefox-spark -y
    chrootCommand aptss install spark-deepin-cloud-print spark-deepin-cloud-scanner -y
    installWithAptss install dummyapp-wps-office dummyapp-spark-deepin-wine-runner -y
elif [[ $1 == arm64 ]];then
    chrootCommand aptss install firefox-spark -y
    installWithAptss install dummyapp-wps-office dummyapp-spark-deepin-wine-runner -y
else 
    #installWithAptss install chromium chromium-l10n -y
    installWithAptss install firefox-esr firefox-esr-l10n-zh-cn -y
fi
#if [[ $1 == arm64 ]] || [[ $1 == loong64 ]]; then
#    installWithAptss install spark-box64 -y
#fi
installWithAptss install network-manager-gnome -y
#chrootCommand apt install grub-efi-$1 -y
#if [[ $1 != amd64 ]]; then
#    chrootCommand apt install grub-efi-$1 -y
#fi
# 卸载无用应用
installWithAptss remove  mlterm mlterm-tiny deepin-terminal-gtk deepin-terminal ibus systemsettings deepin-wine8-stable  -y
# 安装内核
if [[ $1 != amd64 ]]; then
    installWithAptss autopurge "linux-image-*" "linux-headers-*" -y
fi
installWithAptss install linux-kernel-gxde-$1 -y
# 如果为 amd64/i386 则同时安装 oldstable 内核
if [[ $1 == amd64 ]] || [[ $1 == i386 ]] || [[ $1 == mips64el ]]; then
    installWithAptss install linux-kernel-oldstable-gxde-$1 -y
fi
#installWithAptss install linux-firmware -y
installWithAptss install firmware-linux -y
installWithAptss install firmware-iwlwifi firmware-realtek -y
installWithAptss install grub-common -y
# 清空临时文件
installWithAptss autopurge -y
installWithAptss clean
# 下载所需的安装包
installWithAptss install grub-pc --download-only -y
installWithAptss install grub-efi-$1 --download-only -y
installWithAptss install grub-efi --download-only -y
installWithAptss install grub-common --download-only -y
installWithAptss install cryptsetup-initramfs cryptsetup keyutils --download-only -y

mkdir grub-deb
sudo cp $debianRootfsPath/var/cache/apt/archives/*.deb grub-deb
# 清空临时文件
installWithAptss clean
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
