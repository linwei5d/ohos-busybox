#!/bin/sh
set -e

# 当前工作目录。拼接绝对路径的时候需要用到这个值。
WORKDIR=$(pwd)

# 如果存在旧的目录和文件，就清理掉
rm -rf *.tar.gz \
    busybox-1.37.0.tar.bz2 \
    busybox-1.37.0 \
    ohos-sdk \
    busybox-1.37.0-ohos-arm64

# 准备 ohos-sdk
mkdir ohos-sdk
curl -L -O https://repo.huaweicloud.com/openharmony/os/5.1.0-Release/ohos-sdk-windows_linux-public.tar.gz
tar -zxf ohos-sdk-windows_linux-public.tar.gz -C ohos-sdk
cd ohos-sdk/linux
unzip -q native-*.zip
cd ../..

# 准备源码
curl -L -O https://busybox.net/downloads/busybox-1.37.0.tar.bz2
tar -jxf busybox-1.37.0.tar.bz2
cd busybox-1.37.0

# 打一个鸿蒙适配的小补丁
patch -p1 < ../0001-adapt-to-ohos.patch

# 生成默认配置
make defconfig

# 一些难以适配的功能直接禁用掉
sed -i 's/CONFIG_SHA1_HWACCEL=y/# CONFIG_SHA1_HWACCEL is not set/' .config
sed -i 's/CONFIG_FEATURE_UTMP=y/# CONFIG_FEATURE_UTMP is not set/' .config
sed -i 's/CONFIG_FEATURE_SU_CHECKS_SHELLS=y/# CONFIG_FEATURE_SU_CHECKS_SHELLS is not set/' .config
sed -i 's/CONFIG_HOSTID=y/# CONFIG_HOSTID is not set/' .config
sed -i 's/CONFIG_HUSH=y/# CONFIG_HUSH is not set/' .config

# 编译 busybox
make -j$(nproc) \
    CONFIG_PREFIX=${WORKDIR}/busybox-1.37.0-ohos-arm64 \
    CC=${WORKDIR}/ohos-sdk/linux/native/llvm/bin/aarch64-unknown-linux-ohos-clang \
    LD=${WORKDIR}/ohos-sdk/linux/native/llvm/bin/ld.lld \
    AR=${WORKDIR}/ohos-sdk/linux/native/llvm/bin/llvm-ar \
    STRIP=${WORKDIR}/ohos-sdk/linux/native/llvm/bin/llvm-strip \
    HOSTCC=gcc \
    HOSTLD=ld
cd ..


# 手动进行“安装”
mkdir -p busybox-1.37.0-ohos-arm64/bin
cp busybox-1.37.0/busybox busybox-1.37.0-ohos-arm64/bin/


# 履行开源义务，将 license 随制品一起发布
cp busybox-1.37.0/LICENSE busybox-1.37.0-ohos-arm64/
cp busybox-1.37.0/AUTHORS busybox-1.37.0-ohos-arm64/

# 打包最终产物
tar -zcf busybox-1.37.0-ohos-arm64.tar.gz busybox-1.37.0-ohos-arm64
