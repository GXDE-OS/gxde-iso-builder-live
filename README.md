# GXDE OS 安装镜像构建工具（GXDE ISO Builder）

Scripts and toos used to build GXDE OS ISO/Linux Kernel.  

Usage: ./build-squashfs.sh -h
  
支持从 debootstrap 开始从 0 构建出可供安装的 GXDE OS ISO 镜像  
同时支持使用 qemu-user-static + binfmt-support 跨架构生成 ISO  
目前支持 amd64、arm64 安装镜像的构建  
同时也会安装常用的应用，并对生成的 rootfs 进行调优以获得更好的体验，包括但不限于设置国内镜像源、配置语言等等  
