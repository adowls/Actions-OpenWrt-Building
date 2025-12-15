#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

wget http://downloads.openwrt.org/releases/24.10.4/targets/bcm53xx/generic/config.buildinfo -O .config
sed -i '/.*bcm53xx_generic_DEVICE/d' .config
sed -i 's/CONFIG_TARGET_MULTI_PROFILE=y/# CONFIG_TARGET_MULTI_PROFILE is not set/' .config
sed -i 's/CONFIG_TARGET_ALL_PROFILES=y/# CONFIG_TARGET_ALL_PROFILES is not set/' .config
sed -i 's/CONFIG_TARGET_PER_DEVICE_ROOTFS=y/# CONFIG_TARGET_PER_DEVICE_ROOTFS is not set/' .config
echo 'CONFIG_TARGET_bcm53xx_generic_DEVICE_netgear_r8500=y' >> .config
echo 'CONFIG_TARGET_DEVICE_bcm53xx_generic_DEVICE_netgear_r8500=y' >> .config
echo 'CONFIG_TARGET_DEVICE_PACKAGES_bcm53xx_generic_DEVICE_netgear_r8500=y' >> .config
echo 'CONFIG_TARGET_ROOTFS_SQUASHFS=y' >> .config
echo '# CONFIG_TARGET_ROOTFS_EXT4FS is not set' >> .config
