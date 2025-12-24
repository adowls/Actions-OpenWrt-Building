# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2013 OpenWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define Image/Prepare
	rm -f $(KDIR)/fs_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/fs_mark
	$(call prepare_generic_squashfs,$(KDIR)/fs_mark)

	# For UBI we want only one extra block
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/lzma-d16
	$(STAGING_DIR_HOST)/bin/lzma e $@ -d16 $(1) $@.new
	mv $@.new $@
endef

# TRX with only one (kernel) partition
define Build/trx
	$(STAGING_DIR_HOST)/bin/trx \
		-o $@.new \
		-m 33554432 \
		-f $@
	mv $@.new $@
endef

define Build/trx-serial
	$(STAGING_DIR_HOST)/bin/otrx create $@.new \
		-f $(IMAGE_KERNEL) -a 1024 \
		-f $@ -a 0x10000 -A $(KDIR)/fs_mark
	mv $@.new $@
endef

define Build/trx-nand
	# kernel: always use 4 MiB (-28 B or TRX header) to allow upgrades even
	#	  if it grows up between releases
	# root: UBI with one extra block containing UBI mark to trigger erasing
	#	rest of partition
	$(STAGING_DIR_HOST)/bin/otrx create $@.new \
		-f $(IMAGE_KERNEL) -a 0x20000 -b 0x400000 \
		-f $@ \
		-A $(KDIR)/ubi_mark -a 0x20000
	mv $@.new $@
endef

DTS_DIR := $(DTS_DIR)/broadcom

DEVICE_VARS += NETGEAR_BOARD_ID NETGEAR_REGION TPLINK_BOARD

IEEE8021X := wpad-basic-mbedtls
B43 := $(IEEE8021X) kmod-b43
BRCMFMAC_43602A1 := $(IEEE8021X) kmod-brcmfmac brcmfmac-firmware-43602a1-pcie
BRCMFMAC_4366B1 := $(IEEE8021X) kmod-brcmfmac brcmfmac-firmware-4366b1-pcie
BRCMFMAC_4366C0 := $(IEEE8021X) kmod-brcmfmac brcmfmac-firmware-4366c0-pcie
USB2_PACKAGES := kmod-usb-ohci kmod-usb2 kmod-phy-bcm-ns-usb2
USB2_PACKAGES += kmod-usb-ledtrig-usbport
USB3_PACKAGES := $(USB2_PACKAGES) kmod-usb3 kmod-phy-bcm-ns-usb3

define Device/Default
  PROFILES = Generic $$(DEVICE_NAME)
  # .dtb files are prefixed by SoC type, e.g. bcm4708- which is not included in device/image names
  # extract the full dtb name based on the device info
  DEVICE_DTS := $(patsubst %.dtb,%,$(notdir $(wildcard $(if $(IB),$(KDIR),$(DTS_DIR))/*-$(subst _,-,$(1)).dtb)))
  KERNEL := kernel-bin | append-dtb | lzma-d16
  KERNEL_DEPENDS = $$(wildcard $(DTS_DIR)/$$(DEVICE_DTS).dts)
  KERNEL_INITRAMFS_SUFFIX := .trx
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma-d16 | trx
  FILESYSTEMS := squashfs
  KERNEL_NAME := zImage
  DEVICE_IMG_NAME = $$(DEVICE_IMG_PREFIX)-$$(1).$$(2)
  IMAGES := trx
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE/trx := append-ubi | trx-nand
endef

define Device/netgear
  DEVICE_VENDOR := NETGEAR
  IMAGES := chk
  IMAGE/chk := append-ubi | trx-nand | netgear-chk
  NETGEAR_REGION := 1
endef

define Device/netgear_r8500
  DEVICE_MODEL := R8500
  DEVICE_PACKAGES := $(BRCMFMAC_4366B1) $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H334T00_NETGEAR
endef
TARGET_DEVICES += netgear_r8500

$(eval $(call BuildImage))
