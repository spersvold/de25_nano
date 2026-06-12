NPROC			:= $(shell nproc)
CROSS_COMPILE_LINUX	:= aarch64-linux-gnu-
KERNEL_DIR		:= linux-socfpga
KERNEL_IMG		:= $(KERNEL_DIR)/arch/arm64/boot/Image
KERNEL_MODULES_STAGE	:= workspace/modules
KERNEL_MODULES_TAR	:= workspace/linux-modules.tar.gz
ARM_FW_DIR		:= arm-trusted-firmware
ARM_FW_IMG		:= $(ARM_FW_DIR)/build/agilex5/release/bl31.bin

.PHONY: all
all: u-boot linux

# environ/ submodules to manage (paths relative to this Makefile).
# The sub/ RTL submodules (common, vctrl) are intentionally excluded.
SUBMODULES = arm-trusted-firmware u-boot-socfpga linux-socfpga

.PHONY: update-submodules
update-submodules:
	rm -rf workspace/patch-*-done
	git submodule sync --recursive -- $(SUBMODULES)
	git submodule update --init --force -- $(SUBMODULES)

.PHONY: clean-submodules
clean-submodules:
	for m in $(SUBMODULES); do if [ -e $$m/.git ]; then ( cd $$m && git clean -xfdq && git checkout . ); fi; done
	rm -rf workspace/patch-*-done

.PHONY: clean
clean: clean-submodules
	rm -rf workspace

# --- build Linux kernel ---

.PHONY: linux
linux: $(KERNEL_IMG) $(KERNEL_MODULES_TAR)

LINUX_PATCHES := $(wildcard patches/linux/*.patch)
workspace/linux.patch: $(LINUX_PATCHES)
	mkdir -p workspace && rm -f $@
	$(foreach  p,$(LINUX_PATCHES), cat $(p) >>$@;)

workspace/patch-linux-done: workspace/linux.patch Makefile
	if [ -s workspace/linux.patch ] ; then cd $(KERNEL_DIR) && ( git apply -R --check ../workspace/linux.patch 2>/dev/null || git apply ../workspace/linux.patch ) ; fi
	cp $(KERNEL_DIR)/de25-nano.config $(KERNEL_DIR)/.config
	mkdir -p workspace && touch workspace/patch-linux-done

$(KERNEL_IMG): workspace/patch-linux-done
	cd $(KERNEL_DIR) && ./scripts/kconfig/merge_config.sh -m .config ../patches/linux.config > /dev/null
	make -C $(KERNEL_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE_LINUX) olddefconfig
	make -j$(NPROC) -C $(KERNEL_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE_LINUX) Image modules dtbs

$(KERNEL_MODULES_TAR): $(KERNEL_IMG)
	rm -rf $(KERNEL_MODULES_STAGE)
	mkdir -p $(KERNEL_MODULES_STAGE)
	make -j$(NPROC) -C $(KERNEL_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE_LINUX) \
		INSTALL_MOD_PATH=$(abspath $(KERNEL_MODULES_STAGE)) INSTALL_MOD_STRIP=1 modules_install
	rm -f $(KERNEL_MODULES_STAGE)/lib/modules/*/build $(KERNEL_MODULES_STAGE)/lib/modules/*/source
	tar --owner=0 --group=0 --numeric-owner -czf $@ -C $(KERNEL_MODULES_STAGE)/lib modules

# --- build ARM FW ---

.PHONY: arm-firmware
arm-firmware: $(ARM_FW_IMG)

$(ARM_FW_IMG):
	make -j$(NPROC) -C $(ARM_FW_DIR) PLAT=agilex5 bl31

# --- build U-Boot ---

.PHONY: u-boot
u-boot: u-boot-socfpga/u-boot.itb workspace/boot.scr.uimg

u-boot-socfpga/u-boot.itb: $(ARM_FW_IMG)
	ln -sf $$(realpath $(ARM_FW_IMG)) u-boot-socfpga/bl31.bin
	make -C u-boot-socfpga CROSS_COMPILE=$(CROSS_COMPILE_LINUX) socfpga_agilex5_de25_nano_defconfig
	make -j$(NPROC) -C u-boot-socfpga CROSS_COMPILE=$(CROSS_COMPILE_LINUX)

workspace/boot.scr.uimg: uboot-script/uboot_script.its uboot-script/uboot.txt
	mkdir -p workspace
	mkimage -f $<  $@
