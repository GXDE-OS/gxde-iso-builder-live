FROM debian:bookworm-backports
LABEL version="15.15" maintainer="gfdgd xi" org.opencontainers.image.authors="gfdgd xi"
USER root

CMD startdde

# 替换为国内源以及添加 non-free 源
COPY ../99bookworm-backports /etc/apt/preferences.d/
RUN sed -i "s/deb.debian.org/mirrors.cernet.edu.cn/g" /etc/apt/sources.list.d/* \
 && sed -i "s/main/main contrib non-free non-free-firmware/g" /etc/apt/sources.list.d/* \
 && apt update \
 && apt install ca-certificates -y
# 添加 GXDE OS 源
RUN echo "deb [trusted=true] https://repo.gxde.top/gxde-os/bixie ./" > /etc/apt/sources.list.d/temp.list \
 && apt update && apt install gxde-source && rm -rf /etc/apt/sources.list.d/temp.list && apt update
# 安装 GXDE OS
RUN apt install gxde-desktop-android gxde-desktop-extra --install-recommends -y
