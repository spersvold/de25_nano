# -*- mode: makefile; indent-tabs-mode: t -*-
# vi: set noet ci pi sts=0 sw=8 ts=8 :
#
# Copyright 2026 Steffen Persvold
# SPDX-License-Identifier: Apache-2.0

PROJECT_ROOT	:= $(shell git rev-parse --show-toplevel)
TARGET_ROOT	:= $(PROJECT_ROOT)/build

GEN_IPS         := core_pll hdmi_pll reset_release
GEN_IPS		+= agilex_hps emif_io96b_hps emif_io96b_fpga
GEN_IPS		+= lpddr4b_vram lpddr4b_vram_clock_in lpddr4b_vram_reset_in
GEN_IPS		+= lpddr4b_vram_axi_bridge_0 lpddr4b_vram_axi_bridge_1
GEN_IP_FILES    := $(GEN_IPS:%=%_files.f)
GEN_VCS_FILES   := $(GEN_IPS:%=$(TARGET_ROOT)/ip/%/sim/common/vcsmx_files.tcl)
GEN_IP_MEMFILES := $(GEN_IPS:%=%_memfiles.f)
MEMFILES_MANIFEST := .ip_memfiles


# Path to the shared Quartus-primitive stub library. Used on the
# Verilator path in place of the real eda/sim_lib + qsys-generated
# IP wrappers.
QUARTUS_STUBS	:= quartus_sim_stubs.sv

.DEFAULT_GOAL	:= all

# Two flows share one sim_files.f. The flow switch lives entirely in
# unique_ip_files.f: VCS gets the Quartus libs (via quartus_files.f)
# plus the per-IP IP wrappers; Verilator gets only the Quartus-primitive
# stub library. The PRELUDE differs too -- the Verilator path doesn't
# need qsys IP regeneration.
#
# unique_ip_files.f is regenerated on every invocation -- it is cheap
# to produce, and a stale file from the other flow would silently
# point VCS at stub modules (or Verilator at the real Quartus libs).
.PHONY:		unique_ip_files.f
ifneq ($(filter verisim verilate lint,$(MAKECMDGOALS)),)
PRELUDE		:= unique_ip_files.f
unique_ip_files.f: $(QUARTUS_STUBS)
		@echo "#     Generating $@ for Verilator (stubs only)"
		@printf "%s\n%s\n" "$(QUARTUS_STUBS)" "$(LPDDR4_MODEL)" > $@
else
PRELUDE		:= $(GEN_VCS_FILES) unique_ip_files.f $(MEMFILES_MANIFEST)
unique_ip_files.f: $(GEN_IP_FILES) quartus_files.f
		@echo "#     Generating $@ for VCS (Quartus libs + IPs)"
		@( echo "-F quartus_files.f"; \
		   cat $(GEN_IP_FILES) | awk 'function basename(file) { sub(".*/", "", file); return file; } /^[ \t]*"?[-+]/ { if (!seen_opt[$$0]++) print; next } !seen[basename($$0)]++ { print }' \
		 ) > $@

# Symlink each IP's simulation memory-init file(s) (e.g. .hex ROM/cal images)
# into the sim dir by basename, so the generated IP RTL's $readmemh finds them
# at run time. Multiple per IP; idempotent (ln -sf); the IP paths carry // which
# is collapsed. The manifest records the link names so `clean` can remove them.
$(MEMFILES_MANIFEST): $(GEN_IP_MEMFILES)
		@echo "#     Linking IP simulation memory files into the sim dir"
		$(AT)cat $(GEN_IP_MEMFILES) | sed 's://*:/:g' | sort -u | \
		   while read f; do [ -n "$$f" ] || continue; ln -sf "$$f" "$$(basename "$$f")"; basename "$$f"; done > $@
endif

include sim.mk

# Static VCS message-control template. The compile target expands its
# //@IP_FILES@ marker lines into per-IP +file= entries (from unique_ip_files.f)
# in a temp file, which it then passes via -msg_config.
MSG_CONFIG	:= msg_config

VCS_FLAGS       += -top tb +verilog2001ext+.vp +libext+.v+.sv
BUILDARGS	+= +define+SIMULATION +define+VENDOR_ALTERA

define IP_files_f
$(TARGET_ROOT)/ip/$(1)/sim/common/vcsmx_files.tcl: $(TARGET_ROOT)/ip/$(1).ip $(TARGET_ROOT)/Makefile
		$(AT)make -C $(TARGET_ROOT)/ ipgen

$(1)_files.f: $(TARGET_ROOT)/ip/$(1)/sim/common/vcsmx_files.tcl get_design_files.tcl
		@echo "#     Generating $$@ for $(1)"
		$(AT)tclsh get_design_files.tcl -args $(1) $$(realpath $(TARGET_ROOT)/ip/$(1)/sim) > $$@

$(1)_memfiles.f: $(TARGET_ROOT)/ip/$(1)/sim/common/vcsmx_files.tcl get_memory_files.tcl
		@echo "#     Generating $$@ (memory files) for $(1)"
		$(AT)tclsh get_memory_files.tcl -args $(1) $$(realpath $(TARGET_ROOT)/ip/$(1)/sim) > $$@
endef

$(foreach ip,$(GEN_IPS),$(eval $(call IP_files_f,$(ip))))

.PHONY:		clean
clean:
		@[ -f $(MEMFILES_MANIFEST) ] && xargs rm -f <$(MEMFILES_MANIFEST) 2>/dev/null; true
		@rm -rf csrc simv.daidir $(SIMBIN) vc_hdrs.h obj_dir $(GEN_IP_FILES) $(GEN_IP_MEMFILES) $(MEMFILES_MANIFEST) unique_ip_files.f *.txt *.hex
