# DE25-Nano Video Controller

An FPGA display subsystem for the **Terasic DE25-Nano** (Intel/Altera
**Agilex 5** SoC FPGA) that drives an **HDMI** output from **Linux running on
the HPS**, through a DRM/KMS driver (`ocfb-drm`).

It is built around the [`vctrl`](sub/vctrl) video controller and its companion
DMA / 2D engine (`vctrl_dma`):

- The scanout buffer lives in the FPGA's own **LPDDR4 (VRAM)**, so display
  refresh never competes with the CPU for HPS memory bandwidth.
- Applications render into ordinary buffers in HPS memory. On each page flip or
  damage update the **DMA engine copies the frame (or only the changed region)
  into VRAM** ("copy-on-flip").
- The **pixel clock is programmable at runtime**, so the driver supports the
  standard modes up to 165 MHz, not just a single fixed resolution.
- The engine also provides fill and alpha blend. The driver uses blend to draw
  a **hardware cursor plane**.

The controller's register interface is compatible with the OpenCores VGA/LCD
core (the `opencores,ocfb` binding), extended with the VRAM, DMA and PLL
features above.

## How it works

```
  Data path (one frame):

    apps / fbcon / X11 render
            │ CPU writes
            ▼
    HPS LPDDR4: framebuffer (64 MiB GEM-DMA pool)
            │ f2sdram  (vctrl_dma read master)
            ▼
    vctrl_dma: copy-on-flip / damage copy, cursor blend
            │ vctrl_dma write master
            ▼
    FPGA LPDDR4 (VRAM): two scanout buffers   ◄── h2f: CPU aperture (clear, debug)
            │ vctrl_axim scanout read
            ▼
    vctrl_core ──> HDMI TX ──> monitor         pixel clock: hdmi_pll, retuned per mode

  Control path:

    HPS ── lwh2f ──> lw_ctrl_bridge ──┬──> vctrl CSRs      (offset 0x0000)
                                      └──> vctrl_dma CSRs  (offset 0x1000)
```

- **Control plane.** The vctrl and DMA registers are exposed through the
  **lightweight HPS→FPGA bridge** (`lwh2f`, base `0x2000_0000`) by
  [`rtl/lw_ctrl_bridge.sv`](rtl/lw_ctrl_bridge.sv): video controller at offset
  `0x0000`, DMA engine at `0x1000`.
- **Framebuffers.** Applications, fbcon and GBM/EGL clients render into GEM-DMA
  buffers allocated from a 64 MiB write-combined pool in **HPS LPDDR4**.
- **Copy-on-flip.** The DMA read master fetches the frame from HPS memory over
  the **FPGA-to-SDRAM bridge** (`f2sdram`, into the HPS memory controller,
  `ARQOS=0xF`). The write master stores it into one of two scanout buffers in
  **FPGA LPDDR4 (VRAM)**. Damage updates copy only the dirty rectangle; the
  driver merges updates and presents once per vblank.
- **Scanout.** [`vctrl_axim`](sub/vctrl/rtl/vctrl_axim.sv) prefetches the
  active VRAM buffer and feeds the pixel pipeline, which drives an **HDMI**
  transmitter ([`rtl/hdmi_output.sv`](rtl/hdmi_output.sv),
  [`rtl/hdmi_tx_config.sv`](rtl/hdmi_tx_config.sv)).
- **VRAM crossbar.** Three masters share the VRAM controller: the scanout read,
  the DMA write, and the full **HPS→FPGA bridge** (`h2f`), which gives the CPU a
  1 GiB aperture onto VRAM at `0x4000_0000`.
- **Pixel clock.** `hdmi_pll` is an Agilex 5 HVIO IOPLL retuned at runtime by
  [`rtl/hdmi_pll_recfg.sv`](rtl/hdmi_pll_recfg.sv), driven from the vctrl
  `PLLDIVCNT`/`PLLCTRL` registers. The driver computes M/N/C divisors for each
  mode, up to 165 MHz.
- **Interrupts.** The vctrl start-of-frame interrupt (`GIC SPI 17`) provides
  vblank. The DMA done interrupt (`GIC SPI 18`) completes flips asynchronously.
- **Clocking.** The FPGA system domain (`clk_sys`, from `core_pll`) runs at
  **250 MHz**, the Agilex 5 ceiling for the HPS bridges. It is asynchronous to
  the pixel clock; the two meet only at the controller's line-buffer CDC and are
  declared as asynchronous clock groups in the SDC.

See [`sub/vctrl/README.md`](sub/vctrl/README.md) for the video controller and
DMA engine internals, register maps and the DMA command interface.

## Linux driver

The `ocfb-drm` DRM/KMS driver (`CONFIG_DRM_OCFB`, built in) is added by the
kernel patch series in [`environ/patches/linux/`](environ/patches/linux) and
lives in `drivers/gpu/drm/tiny/`. It replaces the legacy `ocfb` fbdev driver
(`FB_OPENCORES` depends on `!DRM_OCFB`). It provides:

- An atomic CRTC with a primary plane (XRGB8888, ARGB8888, RGB565; linear
  layout) and a 256×256 ARGB8888 **hardware cursor plane**.
- Copy-on-flip into VRAM, submitted through the DMA engine's command ring with
  `dma_fence` completion, asynchronous page flips, and damage-aware partial
  updates for in-place clients (fbcon, X11).
- Runtime mode setting with pixel-clock programming, and vblank events from the
  start-of-frame interrupt.
- A fallback to direct scanout from HPS memory when the bitstream has no DMA
  engine or VRAM.
- debugfs hooks for bring-up and testing of the DMA engine (fill, blend, copy
  self-tests and stress).

Tested on hardware with fbcon, `modetest`, kmscube, glmark2-drm, Xorg
(modesetting) and ioquake3.

| Patch | Contents |
|-------|----------|
| 0001 | `ocfb-drm` DRM/KMS driver |
| 0002 | Device-tree binding (`opencores,ocfb`) |
| 0003 | DE25-Nano board support |
| 0004 | SD/MMC voltage regulators |
| 0005 | DE25-Nano display node (VRAM, DMA, interrupts, programmable pixel clock) |
| 0006–0007 | DMA engine debugfs bring-up hooks, serialized submission, blend stress test |
| 0008 | Submission through the command ring with `dma_fence` |
| 0009 | Strided 2D copy debugfs diagnostic |
| 0010 | Damage-aware copy-on-flip |
| 0011 | Atomic CRTC + primary plane |
| 0012 | ARGB8888 + linear modifier on the primary plane |
| 0013 | Hardware cursor plane |

## Repository layout

| Path | Contents |
|------|----------|
| [`rtl/`](rtl) | Top-level RTL: `de25_nano_top.sv`, `hps_wrapper.sv`, `vctrl_wrapper.sv` (vctrl + DMA + VRAM integration), `lw_ctrl_bridge.sv`, `hdmi_pll_recfg.sv`, HDMI output/config, `freq_counter.sv`. |
| [`sub/vctrl/`](sub/vctrl) | The video controller and DMA / 2D engine (submodule). |
| [`sub/common/`](sub/common) | Shared RTL primitives (submodule). |
| [`build/`](build) | Quartus project (`.qpf`/`.qsf`/`.sdc`), Platform Designer IP (`build/ip/`, including the `lpddr4b_vram` VRAM subsystem), pin-assignment scripts, and the FPGA build `Makefile`. |
| [`environ/`](environ) | HPS software: Arm Trusted Firmware, U-Boot and Linux (submodules), the firmware/kernel build `Makefile`, the patch series in `patches/`, and the U-Boot boot script. |
| [`sim/`](sim) | Top-level simulation harness for VCS and Verilator (testbench, IP file-list generation, LPDDR4 model, VCS message config). |

Submodules (see [`.gitmodules`](.gitmodules)): `sub/common`, `sub/vctrl`,
`environ/arm-trusted-firmware`, `environ/u-boot-socfpga`,
`environ/linux-socfpga`.

```sh
git clone --recurse-submodules <repo>
# or, after a plain clone, fetch just the software submodules:
make -C environ update-submodules
```

## FPGA build (`build/`)

Requires **Intel Quartus Prime 26.1** (with Agilex 5 device support) and
`$QUARTUS_HOME` set. The flow runs IP generation → synthesis → fit → timing →
assembly, then merges the HPS first-stage boot loader (U-Boot SPL, from
`environ/`) into the `.sof`, so build U-Boot first.

```sh
cd build
make ipgen        # generate Platform Designer IP (also used by simulation)
make asm          # full compile → output_files/de25_nano_hps.sof
make jic          # convert to a QSPI flash image (.jic)

make program      # configure FPGA SRAM over JTAG (volatile, dev loop)
make flash        # program on-board QSPI flash (persistent)
```

`make program` (JTAG `.sof`) is the usual development loop. `make flash` writes
QSPI for standalone boot. A standalone **cold** boot also requires the board's
MSEL straps to select QSPI.

## HPS software build (`environ/`)

Requires an `aarch64-linux-gnu-` cross toolchain and `mkimage`. The `Makefile`
builds Arm Trusted Firmware (BL31), U-Boot 2026.01 and Linux 6.18. It applies
the patch series in [`environ/patches/`](environ/patches) to the pristine
submodule trees first, and merges
[`patches/linux.config`](environ/patches/linux.config) into the kernel
configuration.

```sh
cd environ
make update-submodules   # init/update ONLY the firmware/kernel submodules
make arm-firmware        # BL31 (bl31.bin)
make u-boot              # SPL + u-boot.itb + boot.scr.uimg
make linux               # arm64 Image + dtbs + workspace/linux-modules.tar.gz
```

Nothing is committed into the submodules. The DE25-Nano support and every
driver change live as patches (`patches/u-boot/`, `patches/linux/`), so a fresh
clone plus `make` reproduces the full tree. `make clean-submodules` returns the
submodules to pristine.

### Boot artifacts

The board boots a **raw arm64 `Image`** plus a separate device tree via `booti`
(not a FIT/`bootm`). A typical SD boot partition holds `u-boot.itb`, `Image`,
`socfpga_agilex5_de25_nano.dtb` and `boot.scr.uimg`. The root filesystem (for
example Ubuntu) is on the SD card and is not built here; unpack
`linux-modules.tar.gz` into its `/lib`.

The boot script ([`environ/uboot-script/uboot.txt`](environ/uboot-script/uboot.txt))
enables the HPS↔FPGA bridges (`bridge enable`) before loading the kernel, and
sets:

```
console=ttyS0,115200 root=${mmcroot} rw rootwait video=HDMI-A-1:1280x720-32@60 reboot=warm
```

`reboot=warm` makes `reboot` perform a warm reset. `video=` picks the initial console mode. Any mode the monitor
advertises within the 165 MHz pixel-clock limit can be selected at runtime (for
example with `modetest` or `xrandr`).

## Device tree

The display node is added by kernel patch 0005 (`socfpga_agilex5_de25_nano.dts`):

```dts
framebuffer0: framebuffer@20000000 {
    compatible = "opencores,ocfb";
    reg = <0x20000000 0x00001000>,    /* csr  : vctrl CSRs (lwh2f)            */
          <0x40000000 0x40000000>,    /* vram : 1 GiB FPGA LPDDR4 aperture (h2f) */
          <0x20001000 0x00001000>;    /* dma  : vctrl_dma CSRs (lwh2f)        */
    reg-names = "csr", "vram", "dma";
    interrupts = <GIC_SPI 17 IRQ_TYPE_LEVEL_HIGH>,    /* vsync (start of frame) */
                 <GIC_SPI 18 IRQ_TYPE_LEVEL_HIGH>;    /* DMA done               */
    memory-region = <&fb_reserved>;   /* 64 MiB shared-dma-pool, no-map */
    opencores,vram-base = <0>;
    opencores,vbar-offset = <0>;
    opencores,has-pitch;
    opencores,has-doublescan;
    opencores,programmable-pixclk;
    clocks = <&hdmi_pll_refclk>;      /* 50 MHz PLL reference */
    /* ... PLL VCO/PFD/M/N/C limits ... */
    opencores,max-pixclk-hz = <165000000>;
};
```

The framebuffer pool (`fb_reserved`) is `no-map` and mapped write-combining.
The FPGA reads it without snooping CPU caches, so it must **not** be marked
`dma-coherent`. Dropping the second interrupt makes the driver poll the DMA
fence and complete flips synchronously. Dropping the `vram`/`dma` regions
selects direct scanout from HPS memory.

### Key addresses

| Region | HPS address | Notes |
|--------|-------------|-------|
| vctrl CSRs | `0x2000_0000` (4 KiB) | lightweight HPS→FPGA bridge |
| vctrl_dma CSRs | `0x2000_1000` (4 KiB) | lightweight HPS→FPGA bridge |
| VRAM aperture | `0x4000_0000` (1 GiB) | HPS→FPGA bridge onto FPGA LPDDR4; FPGA masters address it zero-based |
| HPS LPDDR4 | `0x8000_0000` (1 GiB) | framebuffer pool placed here by the kernel; the DMA read master reaches it 1:1 through `f2sdram` |

## Simulation (`sim/`)

The top-level testbench simulates the integrated design, including the
generated Platform Designer IP and an LPDDR4 model. Both flows share one file
list; it supports **Synopsys VCS** and **Verilator**.

```sh
cd sim
make compile      # build the VCS simulation binary
make simulate     # compile + run (VCS)
make verilate     # build with Verilator (uses Quartus-primitive stubs)
make verisim      # build + run (Verilator)
make lint         # Verilator lint-only
```

The generated IP file lists are collected via `get_design_files.tcl` and
de-duplicated into `unique_ip_files.f`. VCS warnings from the
(encrypted/generated) vendor IP are filtered through
[`sim/msg_config`](sim/msg_config): a `//@IP_FILES@` marker is expanded at
compile time into per-file suppression entries for every generated IP source.

Block-level tests for the controller and the DMA engine (copy, 2D, ring, fill,
blend, 4 KiB burst checks) live in [`sub/vctrl/sim`](sub/vctrl/sim) and run
without vendor IP.

## Requirements

- Intel Quartus Prime 26.1 with Agilex 5 device support (`$QUARTUS_HOME`)
- `aarch64-linux-gnu-` cross toolchain, `mkimage` (u-boot-tools)
- Synopsys VCS (`$VCS_HOME`) and/or Verilator (`$VERILATOR_HOME`) for simulation
- Terasic DE25-Nano board and an HDMI monitor

## License

Project RTL and scripts are licensed under **Apache-2.0** (see SPDX headers in
the source). Submodules and vendor-generated IP retain their own licenses.
