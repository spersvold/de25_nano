PROJECT_ROOT	:= $(shell git rev-parse --show-toplevel)
GITSHA		:= $(shell git rev-parse HEAD | cut -c1-8)

AT		:= @

QUARTUS		:= $(QUARTUS_HOME)/bin/quartus
QUARTUS_SYN	:= $(QUARTUS_HOME)/bin/quartus_syn
QUARTUS_FIT	:= $(QUARTUS_HOME)/bin/quartus_fit
QUARTUS_STA	:= $(QUARTUS_HOME)/bin/quartus_sta
QUARTUS_ASM	:= $(QUARTUS_HOME)/bin/quartus_asm
QUARTUS_SH	:= $(QUARTUS_HOME)/bin/quartus_sh
QUARTUS_IPGEN	:= $(QUARTUS_HOME)/bin/quartus_ipgenerate
QUARTUS_PFG	:= $(QUARTUS_HOME)/bin/quartus_pfg
QUARTUS_PGM	:= $(QUARTUS_HOME)/bin/quartus_pgm
QUARTUS_FLAGS	:= --read_settings_files=on --write_settings_files=off

OUTDIR		:= output_files
STAMP		:= @echo done
TIMESTAMP	:= $(shell date +%d_%m_%Y_%H_%M_%S)

TARGETNAME	:= de25_nano

SPL_HEX		:= ../environ/u-boot-socfpga/spl/u-boot-spl-dtb.hex
FLASH_DEVICE	:= MT25QU128
FLASH_LOADER	:= A5EB013BB23BE4SR1
FLASH_MODE	:= ASX4

all: asm

elab.chg:
	$(STAMP) >$@

syn.chg:
	$(STAMP) >$@

fit.chg:
	$(STAMP) >$@

sta.chg:
	$(STAMP) >$@

asm.chg:
	$(STAMP) >$@

jic.chg:
	$(STAMP) >$@

qar.chg:
	$(STAMP) >$@


.PHONY: quartus
quartus: $(TARGETNAME).qpf
	@echo "#     Running Quartus ..."
	$(AT)$(QUARTUS) $(TARGETNAME).qpf

.PHONY: elab
elab: $(OUTDIR)/$(TARGETNAME).syn.ae.rpt

.PHONY: syn
syn: $(OUTDIR)/$(TARGETNAME).syn.rpt

.PHONY: fit
fit: $(OUTDIR)/$(TARGETNAME).fit.rpt

.PHONY: sta
sta: $(OUTDIR)/$(TARGETNAME).sta.rpt

.PHONY: asm
asm: $(OUTDIR)/$(TARGETNAME)_hps.sof

.PHONY: jic
jic: $(OUTDIR)/$(TARGETNAME)_hps.jic

.PHONY: ipgen
ipgen: ipgen.chg

ipgen.chg: $(TARGETNAME).qsf
	@echo "#     Running Quartus IP generation..."
	$(AT)$(QUARTUS_IPGEN) $(TARGETNAME) -c $(TARGETNAME) --simulation=verilog --simulator=vcsmx --synthesis=verilog
	$(STAMP) >$@

$(OUTDIR)/$(TARGETNAME).syn.ae.rpt: elab.chg ipgen.chg
	@echo "#     Running Quartus analysis and elaboration..."
	$(AT)$(QUARTUS_SYN) $(QUARTUS_FLAGS) $(TARGETNAME) -c $(TARGETNAME) --analysis_and_elaboration

$(OUTDIR)/$(TARGETNAME).syn.rpt: syn.chg $(OUTDIR)/$(TARGETNAME).syn.ae.rpt
	@echo "#     Running Quartus synthesis..."
	$(AT)$(QUARTUS_SYN) $(QUARTUS_FLAGS) $(TARGETNAME) -c $(TARGETNAME)

$(OUTDIR)/$(TARGETNAME).fit.rpt: fit.chg $(OUTDIR)/$(TARGETNAME).syn.rpt
	@echo "#     Running Quartus fitter..."
	$(AT)$(QUARTUS_FIT) $(QUARTUS_FLAGS) $(TARGETNAME) -c $(TARGETNAME)

$(OUTDIR)/$(TARGETNAME).sta.rpt: sta.chg $(OUTDIR)/$(TARGETNAME).fit.rpt
	@echo "#     Running Quartus static timing analyzer..."
	$(AT)$(QUARTUS_STA) $(TARGETNAME) -c $(TARGETNAME) --mode=finalize

$(OUTDIR)/$(TARGETNAME).sof: asm.chg $(OUTDIR)/$(TARGETNAME).fit.rpt
	@echo "#     Running Quartus bitfile generator..."
	$(AT)$(QUARTUS_ASM) $(QUARTUS_FLAGS) $(TARGETNAME)

# Build U-Boot (which produces the SPL hex) on demand. No prerequisites, so it
# only runs when the hex is missing -- an existing hex is left untouched.
$(SPL_HEX):
	@echo "#     SPL hex not found -- building U-Boot in ../environ ..."
	$(AT)$(MAKE) -C ../environ u-boot

$(OUTDIR)/$(TARGETNAME)_hps.sof: $(OUTDIR)/$(TARGETNAME).sof $(SPL_HEX)
	@echo "#     Generating SOF with HPS firmware..."
	$(AT)$(QUARTUS_PFG) -c $(OUTDIR)/$(TARGETNAME).sof $(OUTDIR)/$(TARGETNAME)_hps.sof -o hps_path=$(SPL_HEX)

$(OUTDIR)/$(TARGETNAME)_hps.jic: jic.chg $(OUTDIR)/$(TARGETNAME)_hps.sof
	$(AT)$(QUARTUS_PFG) -c $(OUTDIR)/$(TARGETNAME)_hps.sof $(OUTDIR)/$(TARGETNAME)_hps.jic -o device=$(FLASH_DEVICE) -o flash_loader=$(FLASH_LOADER) -o mode=$(FLASH_MODE)

.PHONY: program
program: $(OUTDIR)/$(TARGETNAME)_hps.sof
	@echo "#     Programming FPGA SRAM via JTAG (.sof, volatile) ..."
	$(AT)$(QUARTUS_PGM) -m jtag -c 1 -o "P;$(OUTDIR)/$(TARGETNAME)_hps.sof"

.PHONY: flash
flash: $(OUTDIR)/$(TARGETNAME)_hps.jic
	@echo "#     Programming on-board QSPI flash via JTAG (.jic, persistent) ..."
	$(AT)$(QUARTUS_PGM) -m jtag -c 1 scripts/flash.cdf

.PHONY: quartus_qar
quartus_qar: qar.chg output_files/$(TARGETNAME).fit.rpt
	@echo "#     Running Quartus archive..."
	$(AT)$(QUARTUS_SH) --archive -use_file_subset auto $(TARGETNAME) -output $(TARGETNAME)_$(GITSHA)_$(TIMESTAMP)

.PHONY: clean
clean:
	$(AT)rm -rf output_files dni qdb tmp-clearbox synth_dumps *.chg *.mif *.h *.list *.qws
