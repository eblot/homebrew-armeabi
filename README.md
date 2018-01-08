# Homebrew-ArmEabi

Homebrew tap for ARM EABI toolchain, dedicated to build baremetal ARM Cortex-M
applications from a macOS host.

These toolchains have been used to build eCos-based application and bootloaders,
and are now used to build applications for Nordik nRF52 BLE applications, 
ST STM32L0 and STM32L4 baremetal and ChibiOS applications.

## Installation

 * Install [Homebrew](https://brew.sh)
 * Execute `brew tap eblot/armeabi`
 * Install the package you need, *e.g.*
    `brew install arm-none-eabi-llvm`

## Available recipes

 * GNU BinUtils (Assembler, Linker, Tools): `arm-none-eabi-binutils.rb`
 * GNU C compiler: `arm-none-eabi-gcc.rb`
 * GNU Debugger: `arm-none-eabi-gdb.rb`
 * Clang/LLVM toolchain: `arm-none-eabi-llvm.rb`
   * This toolchain does not require any of the GNU tools, as it comes with
     an integrated asssembler and linker. Note that the linker does not support
     complex `target.ld` scripts with the stable 5.0 version. However the
     development version now supports most of the common script syntax.
   * Support the `--HEAD` option to install the development version of LLVM
 * C library (newlib) and compiler runtime for Cortex-M4 targets `armv7em-cortex-m4.rb`
 * C library (newlib) and compiler runtime for Cortex-M4 FPU targets `armv7em-cortex-m4f.rb`
 * CramFS tools to build/check CramFS volume: `cramfs.rb`
 * eCos configuration tool: `ecosconfig.rb`
 * nRF52 script to fix Nordik SDK supervisor calls: `nrfsvc.py`
