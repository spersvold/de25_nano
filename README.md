# DE25-Nano Video Controller

An FPGA video display controller for the **Terasic DE25-Nano** (Intel/Altera
**Agilex 5** SoC FPGA) that scans a framebuffer out of HPS LPDDR4 and drives an
**HDMI** output — driven entirely from **Linux running on the HPS** using the
mainline `ocfb` framebuffer driver.

The video controller ([`sub/vctrl`](sub/vctrl)) is register-compatible with the
OpenCores VGA/LCD core, so the stock Linux `drivers/video/fbdev/ocfb.c` driver
binds to it unmodified. The framebuffer lives in HPS LPDDR4; software allocates
it, writes its physical base into the controller's `VBAR` register, and the
controller's AXI read master streams pixels back over the FPGA→HPS bridge.

## How it works

```
        HPS (Arm Cortex-A55/A76, Linux)                 FPGA fabric
   ┌───────────────────────────────────────┐      ┌────────────────────────────────┐
   │  ocfb fbdev driver                    │      │                                │
   │    • CSR access ───────── lwh2f ──────┼─────>│ lw_ctrl_bridge ──> vctrl_regs  │
   │      (0x2000_0000)        bridge      │      │                         │      │
   │    • framebuffer in LPDDR4            │      │            vctrl_core   ▼      │
   │      (WC carveout @ 0xbf00_0000)      │      │              (scanout)  │      │
   │      base written to VBAR             │      │                         │      │
   │                                       │      │              vctrl_axim │      │
   │  LPDDR4  <──────────── f2h / ACE5-Lite┼<─────┤ (AXI4 read master) <────┘      │
   │  (EMIF)                bridge         │      │                                │
   └───────────────────────────────────────┘      │  vctrl ─> HDMI TX ─> connector │
                                                  └────────────────────────────────┘
```

- **Control plane** — the controller's CSRs are exposed through the
  **lightweight HPS→FPGA bridge** (`lwh2f`, base `0x2000_0000`) via
  [`rtl/lw_ctrl_bridge.sv`](rtl/lw_ctrl_bridge.sv).
- **Framebuffer** — allocated by Linux in HPS **LPDDR4**; its physical address
  is programmed into the `VBAR` (Video Base Address) register.
- **Scanout** — [`vctrl_axim`](sub/vctrl/rtl/vctrl_axim.sv), an AXI4 read
  master, prefetches the framebuffer over the **FPGA→HPS bridge** (`f2h`,
  through an ACE5-Lite translator) and feeds the pixel pipeline.
- **Output** — the pixel pipeline drives an **HDMI** transmitter
  ([`rtl/hdmi_output.sv`](rtl/hdmi_output.sv),
  [`rtl/hdmi_tx_config.sv`](rtl/hdmi_tx_config.sv)). The pixel clock PLL is
  fixed at **148.5 MHz (1080p60)**.
- **Clocking** — the FPGA system/CSR/scanout domain (`clk_sys`, from
  `core_pll`) runs at **250 MHz**, the Agilex 5 ceiling for the `lwhps2fpga` /
  `fpga2hps` bridges. It is asynchronous to the 148.5 MHz pixel clock (separate
  PLLs); the two meet only at the controller's line-buffer CDC, and are
  declared as asynchronous clock groups in the SDC.

See [`sub/vctrl/README.md`](sub/vctrl/README.md) for the video controller's
internal architecture (timing generator, color processor, CLUT, line buffer,
clock-domain crossing).

## Repository layout

| Path | Contents |
|------|----------|
| [`rtl/`](rtl) | Top-level RTL: `de25_nano_top.sv`, `hps_wrapper.sv`, `lw_ctrl_bridge.sv`, HDMI output/config. |
| [`sub/vctrl/`](sub/vctrl) | The video controller (submodule) — ocfb-register-compatible. |
| [`sub/common/`](sub/common) | Shared RTL primitives (submodule). |
| [`build/`](build) | Quartus project (`.qpf`/`.qsf`), Platform Designer IP (`build/ip/`), pin-assignment scripts, and the FPGA build `Makefile`. |
| [`environ/`](environ) | HPS software: Arm Trusted Firmware, U-Boot and Linux (submodules of the Terasic forks), the kernel/firmware build `Makefile`, `patches/`, and the U-Boot boot script. |
| [`sim/`](sim) | Simulation harness for VCS and Verilator (testbench, file-list generation, VCS message config). |

Submodules (see [`.gitmodules`](.gitmodules)): `sub/common`, `sub/vctrl`,
`environ/arm-trusted-firmware`, `environ/u-boot-socfpga`,
`environ/linux-socfpga`.

```sh
git clone --recurse-submodules <repo>
# or, after a plain clone, fetch just the software submodules:
make -C environ update-submodules
```

## FPGA build (`build/`)

Requires **Intel Quartus Prime** (with Agilex 5 device support) and
`$QUARTUS_HOME` set. The flow runs IP generation → synthesis → fit → timing →
assembly, then merges the HPS first-stage boot image into the `.sof`.

```sh
cd build
make ipgen        # generate Platform Designer IP (also used by simulation)
make asm          # full compile → output_files/de25_nano_hps.sof
make jic          # convert to a QSPI flash image (.jic)

make program      # configure FPGA SRAM over JTAG (volatile, dev loop)
make flash        # program on-board QSPI flash (persistent)
```

`make program` (JTAG `.sof`) is the usual development loop. `make flash` writes
QSPI for standalone boot — note that a standalone **cold** boot/reset also
requires the board's MSEL straps to select QSPI and the flash image to carry
the HPS boot chain.

## HPS software build (`environ/`)

Requires an `aarch64-linux-gnu-` cross toolchain, `$QUARTUS_HOME` (for the SPL
hex used by the FPGA build), and `mkimage`. The `Makefile` builds Arm Trusted
Firmware (BL31), U-Boot, and the Linux kernel, applying the patch series in
[`environ/patches/`](environ/patches) to the kernel tree first.

```sh
cd environ
make update-submodules   # init/update ONLY the firmware/kernel submodules
make arm-firmware        # BL31 (bl31.bin)
make u-boot              # u-boot.itb + boot.scr.uimg
make linux               # arm64 Image + dtbs (patches applied automatically)
```

The `patches/linux/*.patch` series adds the `ocfb` driver enhancements and the
DE25-Nano device-tree wiring for the framebuffer. Nothing is committed into the
submodules — a fresh clone + `make` reproduces the full tree.

### Boot artifacts

The board boots a **raw arm64 `Image`** plus a separate device tree via `booti`
(not a FIT/`bootm`). A typical SD boot partition holds `u-boot.itb`, `Image`,
`socfpga_agilex5_de25_nano.dtb`, and `boot.scr.uimg`. The boot script enables
the HPS↔FPGA bridges (`bridge enable 0x6` — LWHPS2FPGA + FPGA2HPS) before
loading the kernel.

## Bringing up the framebuffer under Linux

The framebuffer device is described in the board DTS
(`socfpga_agilex5_de25_nano.dts`, applied via the kernel patch series):

```dts
framebuffer0: framebuffer@20000000 {
    compatible = "opencores,ocfb";
    reg = <0x20000000 0x1000>,        /* CSR window (lwh2f) */
          <0xbf000000 0x01000000>;    /* framebuffer carveout in LPDDR4 */
    status = "okay";
};
```

with a matching `reserved-memory` `no-map` region at `0xbf000000`. With the
second `reg` region present, the driver maps the carveout **write-combining**
and programs its base into `VBAR`; the controller reads it non-coherently over
`f2h` (so the region must **not** be `dma-coherent`).

The HDMI pixel clock is fixed at 148.5 MHz, so the controller must run at
**1080p60**. Add to the kernel command line:

```
video=ocfb:1920x1080-16@60
```

or switch live with `fbset`:

```sh
fbset -g 1920 1080 1920 1080 16 -t 6734 148 88 36 4 44 5 -hsync high -vsync high
```

### Key addresses

| Region | Address | Notes |
|--------|---------|-------|
| Video controller CSRs | `0x2000_0000` (4 KiB) | via lightweight HPS→FPGA bridge; `VBAR` at offset `0x14` |
| Command DMA registers | `0x2000_1000` | second region behind `lw_ctrl_bridge` |
| HPS LPDDR4 | `0x8000_0000`– | framebuffer carveout at `0xbf00_0000` (top of the 1 GiB window; `VBAR` is 32-bit) |

## Simulation (`sim/`)

Two flows share one file list; supports **Synopsys VCS** and **Verilator**.

```sh
cd sim
make compile      # build the VCS simulation binary
make simulate     # compile + run (VCS)
make verilate     # build with Verilator (uses Quartus-primitive stubs)
make verisim      # build + run (Verilator)
make lint         # Verilator lint-only
```

The generated Platform Designer IP file lists are collected via
`get_design_files.tcl` and de-duplicated into `unique_ip_files.f`. VCS warnings
from the (encrypted/generated) vendor IP are filtered through
[`sim/msg_config`](sim/msg_config): a `//@IP_FILES@` marker is expanded at
compile time into per-file suppression entries for every generated IP source.

## Requirements

- Intel Quartus Prime with Agilex 5 device support (`$QUARTUS_HOME`)
- `aarch64-linux-gnu-` cross toolchain, `mkimage` (u-boot-tools)
- Synopsys VCS (`$VCS_HOME`) and/or Verilator (`$VERILATOR_HOME`) for simulation
- Terasic DE25-Nano board

## License

Project RTL and scripts are licensed under **Apache-2.0** (see SPDX headers in
the source). Submodules and vendor-generated IP retain their own licenses.
