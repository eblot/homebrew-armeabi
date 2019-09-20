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
   1. `brew install arm-none-eabi-llvm`
   2. `brew install armv7em-cortex-m4f`

## Available recipes

 * GNU BinUtils (Assembler, Linker, Tools): `arm-none-eabi-binutils.rb`
 * GNU C compiler: `arm-none-eabi-gcc.rb`
 * GNU Debugger: `arm-none-eabi-gdb.rb`
 * Clang/LLVM toolchain w/ additional tools: `arm-none-eabi-llvm.rb`
   * This toolchain does not require any of the GNU tools, as it comes with
     an integrated asssembler and linker, and the `lldb` debugger.
   * Support the `--HEAD` option to install the development version of LLVM
 * C library (newlib 3.x) and compiler runtime for various targets:
    * Cortex-M4: `armv7em-cortex-m4.rb` (`-lclang_rt.builtins-armv7em`)
    * Cortex-M4 w/ FPU: `armv7em-cortex-m4f.rb` (`-lclang_rt.builtins-armv7em`)
    * Cortex-M3: `armv7m-cortex-m3.rb` (`-lclang_rt.builtins-armv7m`)
    * Cortex-M0+: `armv6m-cortex-m0plus.rb` (`-lclang_rt.builtins-armv6m`)
 * nRF52 script to fix Nordik SDK supervisor calls: `nrfsvc.py`
 * CramFS tools to build/check CramFS volume: `cramfs.rb`
 * eCos configuration tool: `ecosconfig.rb`

### Notes:

 LLVM 9.0 series finally fixes the compiler runtime library name, so existing
 link command lines and/or scripts should be updated.
