class Armv6mCortexM0plus < Formula
  desc "Newlib & compiler runtime for baremetal Cortex-M0 targets"
  homepage "https://sourceware.org/newlib/"
  # and homepage "http://compiler-rt.llvm.org/"

  stable do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/efb851a6b319dc7b11234f57e88f4a3b05c66560/CMakeLists.txt"
    sha256 "ccb73bd04a60064385e87fc650c6c805771ceecf382a126e764e6c3b15237355"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "6.0.0"

    resource "newlib" do
      url "ftp://sourceware.org/pub/newlib/newlib-3.0.0.tar.gz"
      sha256 "c8566335ee74e5fcaeb8595b4ebd0400c4b043d6acb3263ecb1314f8f5501332"

      patch do
        url "https://gist.githubusercontent.com/eblot/135ad4fe89008d54fdea89cdadc420de/raw/bd976c82203bf89d4b4ebc141014a88e2e8ba6f1/newlib-arm-eabi-3.0.0.patch"
        sha256 "b2993bc29d83fddd436a7574e680aeae72feab165b9518ba19dcfea60df64b77"
      end

      patch do
        url "https://github.com/eblot/newlib-cygwin/commit/ef7efeb7ec8ca067d07d00c2c8aabb3fdb124440.diff"
        sha256 "eb70bb327f8d33148053488a34cfd549e560d209231897f945eba44a0d5da28f"
      end

      patch do
        url "https://github.com/eblot/newlib-cygwin/commit/544e68a14f2e1c4c53f04cce84343d7bbf0499d0.diff"
        sha256 "f155b4f0dc2ec9c5c5ba1be1454abe8db51e089d22fc2181b91eb94c2fc3ad29"
      end
    end

    resource "compiler-rt" do
      url "https://releases.llvm.org/6.0.0/compiler-rt-6.0.0.src.tar.xz"
      sha256 "d0cc1342cf57e9a8d52f5498da47a3b28d24ac0d39cbc92308781b3ee0cea79a"
    end
  end

  head do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/efb851a6b319dc7b11234f57e88f4a3b05c66560/CMakeLists.txt"
    sha256 "ccb73bd04a60064385e87fc650c6c805771ceecf382a126e764e6c3b15237355"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "7.0.0-dev"

    resource "newlib" do
      url "ftp://sourceware.org/pub/newlib/newlib-3.0.0.tar.gz"
      sha256 "c8566335ee74e5fcaeb8595b4ebd0400c4b043d6acb3263ecb1314f8f5501332"

      patch do
        url "https://gist.githubusercontent.com/eblot/135ad4fe89008d54fdea89cdadc420de/raw/bd976c82203bf89d4b4ebc141014a88e2e8ba6f1/newlib-arm-eabi-3.0.0.patch"
        sha256 "b2993bc29d83fddd436a7574e680aeae72feab165b9518ba19dcfea60df64b77"
      end

      patch do
        url "https://github.com/eblot/newlib-cygwin/commit/ef7efeb7ec8ca067d07d00c2c8aabb3fdb124440.diff"
        sha256 "eb70bb327f8d33148053488a34cfd549e560d209231897f945eba44a0d5da28f"
      end

      patch do
        url "https://github.com/eblot/newlib-cygwin/commit/544e68a14f2e1c4c53f04cce84343d7bbf0499d0.diff"
        sha256 "f155b4f0dc2ec9c5c5ba1be1454abe8db51e089d22fc2181b91eb94c2fc3ad29"
      end
    end

    resource "compiler-rt" do
      url "http://llvm.org/svn/llvm-project/compiler-rt/trunk", :using => :svn
    end
  end

  depends_on "arm-none-eabi-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install
    llvm = Formulary.factory 'arm-none-eabi-llvm'

    (buildpath/"newlib").install resource("newlib")
    (buildpath/"compiler-rt").install resource("compiler-rt")

    ENV.append_path "PATH", "#{llvm.opt_prefix}/bin"

    ENV['CC_FOR_TARGET']="#{llvm.opt_prefix}/bin/clang"
    ENV['AR_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-ar"
    ENV['NM_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-nm"
    ENV['RANLIB_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-ranlib"
    ENV['READELF_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-readelf"
    ENV['CFLAGS_FOR_TARGET']="-target armv6m-none-eabi -mcpu=cortex-m0plus -mfloat-abi=soft -mthumb -mabi=aapcs -g -O3 -ffunction-sections -fdata-sections -Wno-unused-command-line-argument"
    ENV['AS_FOR_TARGET']="#{llvm.opt_prefix}/bin/clang"

    host=`cc -dumpmachine`.strip

    mktemp do
      system buildpath/"newlib/configure",
                "--host=#{host}",
                "--build=#{host}",
                "--target=armv6m-none-eabi",
                "--prefix=#{prefix}/armv6m-none-eabi/cortex-m0plus",
                "--disable-newlib-supplied-syscalls",
                "--enable-newlib-reent-small",
                "--disable-newlib-fvwrite-in-streamio",
                "--disable-newlib-fseek-optimization",
                "--disable-newlib-wide-orient",
                "--enable-newlib-nano-malloc",
                "--disable-newlib-unbuf-stream-opt",
                "--enable-lite-exit",
                "--enable-newlib-global-atexit",
                "--disable-newlib-nano-formatted-io",
                "--disable-newlib-fvwrite-in-streamio",
                "--enable-newlib-io-c99-formats",
                "--disable-newlib-io-float",
                "--disable-nls"
      system "make"
      system "make -j1 install; true"
      system "mv #{prefix}/armv6m-none-eabi/cortex-m0plus/armv6m-none-eabi/* #{prefix}/armv6m-none-eabi/cortex-m0plus/"
      system "rm -rf #{prefix}/armv6m-none-eabi/cortex-m0plus/armv6m-none-eabi"
    end

    mktemp do
      # custom CMakeLists.txt not installed as a resource, so duplicate it for
      # the sake of simplicity. Did I write I hate ruby as a language?
      mkdir_p "#{buildpath}/compiler-rt/cortex-m"
      cp "#{buildpath}/CMakeLists.txt", "#{buildpath}/compiler-rt/cortex-m/CMakeLists.txt"
      system "cmake",
                "-G", "Ninja",
                "-DXTARGET=armv6m-none-eabi",
                "-DXCPU=cortex-m0plus",
                "-DXCPUDIR=cortex-m0plus",
                "-DXCFLAGS=-mfloat-abi=soft",
                "-DXNEWLIB=#{prefix}/armv6m-none-eabi/cortex-m0plus",
                 buildpath/"compiler-rt/cortex-m"
      system "ninja"
      system "cp libcompiler_rt.a #{prefix}/armv6m-none-eabi/cortex-m0plus/lib/"
      ln_s "#{prefix}/armv6m-none-eabi/cortex-m0plus/lib/libcompiler_rt.a",
           "#{prefix}/armv6m-none-eabi/cortex-m0plus/lib/libclang_rt.builtins-armv6m.a.a"
    end
  end

end

__END__
--- a/newlib/libc/stdlib/exit.c
+++ b/newlib/libc/stdlib/exit.c
@@ -54,7 +54,7 @@
 {
 #ifdef _LITE_EXIT
   /* Refer to comments in __atexit.c for more details of lite exit.  */
-  void __call_exitprocs (int, void *)) __attribute__((weak);
+  void __call_exitprocs (int, void *) __attribute__((weak));
   if (__call_exitprocs)
 #endif
     __call_exitprocs (code, NULL);
--- a/newlib/libc/include/stdio.h
+++ b/newlib/libc/include/stdio.h
@@ -689,9 +689,9 @@
 	if ((_p->_flags & __SCLE) && _c == '\n')
 	  __sputc_r (_ptr, '\r', _p);
 #endif
 	if (--_p->_w >= 0 || (_p->_w >= _p->_lbfsize && (char)_c != '\n'))
-		return (*_p->_p++ = _c);
+		return (*_p->_p++ = (unsigned char)_c);
 	else
 		return (__swbuf_r(_ptr, _c, _p));
 }
 #else

--- a/libgloss/arm/Makefile.in
+++ b/libgloss/arm/Makefile.in
@@ -109,7 +109,7 @@ INCLUDES += `if [ -d ${objroot}/newlib ]; then echo -I$(srcroot)/newlib/libc/mac
 # build a test program for each target board. Just trying to get
 # it to link is a good test, so we ignore all the errors for now.
 #
-all: ${CRT0} ${LINUX_CRT0} ${LINUX_BSP} ${REDBOOT_CRT0} ${REDBOOT_OBJS} ${RDPMON_CRT0} ${RDPMON_BSP} ${RDIMON_CRT0} ${RDIMON_BSP}
+all: ${CRT0} # ${LINUX_CRT0} ${LINUX_BSP} ${REDBOOT_CRT0} ${REDBOOT_OBJS} ${RDPMON_CRT0} ${RDPMON_BSP} ${RDIMON_CRT0} ${RDIMON_BSP}
 	@rootpre=`pwd`/; export rootpre; \
 	srcrootpre=`cd $(srcdir); pwd`/; export srcrootpre; \
 	for dir in .. ${SUBDIRS}; do \
@@ -206,7 +206,7 @@ distclean maintainer-clean realclean: clean
 	rm -f Makefile config.status *~
 
 .PHONY: install info install-info clean-info
-install: ${CRT0_INSTALL} ${LINUX_INSTALL} ${REDBOOT_INSTALL} ${RDPMON_INSTALL} ${RDIMON_INSTALL} ${IQ80310_INSTALL}  ${PID_INSTALL} ${NANO_INSTALL}
+install: ${CRT0_INSTALL} ${NANO_INSTALL} # ${LINUX_INSTALL} ${REDBOOT_INSTALL} ${RDPMON_INSTALL} ${RDIMON_INSTALL} ${IQ80310_INSTALL}  ${PID_INSTALL} ${NANO_INSTALL}
 	@rootpre=`pwd`/; export rootpre; \
 	srcrootpre=`cd $(srcdir); pwd`/; export srcrootpre; \
 	for dir in .. ${SUBDIRS}; do \
--- a/libgloss/arm/cpu-init/Makefile.in
+++ /dev/null
@@ -1,87 +0,0 @@
-#
-#
-DESTDIR =
-VPATH = @srcdir@ @srcdir@/.. @srcdir@/../..
-srcdir = @srcdir@
-objdir = .
-srcroot = $(srcdir)/../../..
-objroot = $(objdir)/../../..
-
-prefix = @prefix@
-exec_prefix = @exec_prefix@
-
-host_alias = @host_alias@
-target_alias = @target_alias@
-
-bindir = @bindir@
-libdir = @libdir@
-tooldir = $(exec_prefix)/$(target_alias)
-
-objtype = @objtype@
-
-INSTALL = @INSTALL@
-INSTALL_PROGRAM = @INSTALL_PROGRAM@
-INSTALL_DATA = @INSTALL_DATA@
-
-# Multilib support variables.
-# TOP is used instead of MULTI{BUILD,SRC}TOP.
-MULTISRCTOP =
-MULTIBUILDTOP =
-MULTIDIRS =
-MULTISUBDIR =
-MULTIDO = true
-MULTICLEAN = true
-
-SHELL =	/bin/sh
-
-CC = @CC@
-
-AS = @AS@
-AR = @AR@
-LD = @LD@
-RANLIB = @RANLIB@
-
-CPU_INIT_OBJS = rdimon-aem.o
-CPU_INIT_INSTALL = install-cpu-init
-
-CFLAGS		= -g
-
-# Host specific makefile fragment comes in here.
-@host_makefile_frag@
-
-.PHONY: all
-all: ${CPU_INIT_OBJS}
-
-#
-# here's where we build the test programs for each target
-#
-.PHONY: test
-test:
-
-# Static pattern rule for assembling cpu init files to object files.
-${CPU_INIT_OBJS}: %.o: %.S
-	$(CC) $(CFLAGS_FOR_TARGET) $(CFLAGS) $(INCLUDES) -DARM_RDI_MONITOR -o $@ -c $<
-
-clean mostlyclean:
-	rm -f a.out core *.i *.o *-test *.srec *.dis *.x
-
-distclean maintainer-clean realclean: clean
-	rm -f Makefile *~
-
-.PHONY: install info install-info clean-info
-install: ${CPU_INIT_INSTALL}
-
-install-cpu-init:
-	test -d $(DESTDIR)${tooldir}/lib${MULTISUBDIR}/cpu-init || mkdir $(DESTDIR)${tooldir}/lib${MULTISUBDIR}/cpu-init
-	set -e; for x in ${CPU_INIT_OBJS}; do ${INSTALL_DATA} $$x $(DESTDIR)${tooldir}/lib${MULTISUBDIR}/cpu-init/$$x; done
-
-doc:
-info:
-install-info:
-clean-info:
-
-Makefile: Makefile.in ../config.status @host_makefile_frag_path@
-	$(SHELL) ../config.status --file cpu-init/Makefile
-
-../config.status: ../configure
-	$(SHELL) ../config.status --recheck
--- a/libgloss/arm/cpu-init/rdimon-aem.S
+++ /dev/null
@@ -1,539 +0,0 @@
-/* Copyright (c) 2005-2013 ARM Ltd.  All rights reserved.
-
- Redistribution and use in source and binary forms, with or without
- modification, are permitted provided that the following conditions
- are met:
- 1. Redistributions of source code must retain the above copyright
-    notice, this list of conditions and the following disclaimer.
- 2. Redistributions in binary form must reproduce the above copyright
-    notice, this list of conditions and the following disclaimer in the
-    documentation and/or other materials provided with the distribution.
- 3. The name of the company may not be used to endorse or promote
-    products derived from this software without specific prior written
-    permission.
-
- THIS SOFTWARE IS PROVIDED BY ARM LTD ``AS IS'' AND ANY EXPRESS OR IMPLIED
- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
- IN NO EVENT SHALL ARM LTD BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
- TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
- PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
- LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
-
-/* This file gives a basic initialisation of a Cortex-A series core.  It is
-   the bare minimum required to get Cortex-A core running with a semihosting
-   interface.
-
-   It sets up a basic 1:1 phsyical address to virtual address mapping;
-   turns the MMU on; enables branch prediction; activates any integrated
-   caches; enables the Advanced SIMD and VFP co-processors; and installs
-   basic exception handlers.
-
-   It does not handle peripherals, and assumes all memory is Normal.
-
-   It does not change processor state from the startup privilege and security
-   level.
-
-   This has only been tested to work in ARM state.
-
-   By default it assumes exception vectors are located from address 0.
-   However, if this is not true they can be moved by defining the
-   _rdimon_vector_base symbol.  For example if you have HIVECS enabled you
-   may pass --defsym _rdimon_vector_base=0xffff0000 on the linker command
-   line.  */
-
-   /* __ARM_ARCH_PROFILE is defined from GCC 4.8 onwards, however __ARM_ARCH_7A
-	has been defined since 4.2 onwards, which is when v7-a support was added
-	and hence 'A' profile support was added in the compiler.  Allow for this
-	file to be built with older compilers.  */
-#if defined(__ARM_ARCH_7A__) || (__ARM_ARCH_PROFILE == 'A')
-    .syntax	unified
-    .arch	armv7-a
-    .arm
-
-    @ CPU Initialisation
-    .globl	_rdimon_hw_init_hook
-    .type	_rdimon_hw_init_hook, %function
-
-_rdimon_hw_init_hook:
-    @ Only run the code on CPU 0 - otherwise spin
-    mrc         15, 0, r4, cr0, cr0, 5  @ Read MPIDR
-    ands        r4, r4, #15
-spin:
-    bne spin
-
-    mov         r10, lr			@ Save LR for final return
-
-#ifdef __ARMEB__
-    @ Setup for Big Endian
-    setend      be
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    orr         r4, r4, #(1<<25)        @ Switch to Big Endian (Set SCTLR.EE)
-    mcr         15, 0, r4, cr1, cr0, 0  @ Write SCTLR
-#else
-    @ Setup for Little Endian
-    setend      le
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    bic         r4, r4, #(1<<25)        @ Switch to LE (unset SCTLR.EE)
-    mcr         15, 0, r4, cr1, cr0, 0  @ Write SCTLR
-#endif
-
-    bl          is_a15_a7
-
-    @ For Cortex-A15 and Cortex-A7 only:
-    @ Write zero into the ACTLR to turn everything on.
-    itt		eq
-    moveq       r4, #0
-    mcreq       15, 0, r4, c1, c0, 1
-    isb
-
-    @ For Cortex-A15 and Cortex-A7 only:
-    @ Set ACTLR:SMP bit before enabling the caches and MMU,
-    @ or performing any cache and TLB maintenance operations.
-    ittt	eq
-    mrceq       15, 0, r4, c1, c0, 1    @ Read ACTLR
-    orreq       r4, r4, #(1<<6)         @ Enable ACTLR:SMP
-    mcreq       15, 0, r4, c1, c0, 1    @ Write ACTLR
-    isb
-
-    @ Setup for exceptions being taken to Thumb/ARM state
-    mrc         15, 0, r4, cr1, cr0, 0	@ Read SCTLR
-#if defined(__thumb__)
-    orr         r4, r4, #(1 << 30)	@ Enable SCTLR.TE
-#else
-    bic         r4, r4, #(1 << 30)      @ Disable SCTLR.TE
-#endif
-    mcr         15, 0, r4, cr1, cr0, 0  @ Write SCTLR
-
-    bl          __reset_caches
-
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    orr         r4, r4, #(1<<22)        @ Enable unaligned mode
-    bic         r4, r4, #2              @ Disable alignment faults
-    bic         r4, r4, #1              @ Disable MMU
-    mcr         15, 0, r4, cr1, cr0, 0  @ Write SCTLR
-
-    mov         r4, #0
-    mcr         15, 0, r4, cr8, cr7, 0  @ Write TLBIALL - Invaliidate unified
-                                        @ TLB
-    @ Setup MMU Primary table P=V mapping.
-    mvn         r4, #0
-    mcr         15, 0, r4, cr3, cr0, 0  @ Write DACR
-
-    mov         r4, #0                  @ Always use TTBR0, no LPAE
-    mcr         15, 0, r4, cr2, cr0, 2  @ Write TTBCR
-    adr         r4, page_table_addr	@ Load the base for vectors
-    ldr         r4, [r4]
-    mrc         p15, 0, r0, c0, c0, 5   @ read MPIDR
-    tst         r0, #0x80000000         @ bis[31]
-    @ Set page table flags - there are two page table flag formats for the
-    @ architecture.  For systems without multiprocessor extensions we use 0x1
-    @ which is Inner cacheable/Outer non-cacheable.  For systems with
-    @ multiprocessor extensions we use 0x59 which is Inner/Outer write-back,
-    @ no write-allocate, and cacheable.  See the ARMARM-v7AR for more details.
-    it          ne
-    addne       r4, r4, #0x58
-    add         r4, r4, #1
-
-    mcr         15, 0, r4, cr2, cr0, 0  @ Write TTBR0
-
-    mov         r0, #34 @ 0x22          @ TR0 and TR1 - normal memory
-    orr         r0, r0, #(1 << 19)      @ Shareable
-    mcr         15, 0, r0, cr10, cr2, 0 @ Write PRRR
-    movw        r0, #0x33
-    movt        r0, #0x33
-    mcr         15, 0, r0, cr10, cr2, 1 @ Write NMRR
-    mrc         15, 0, r0, cr1, cr0, 0  @ Read SCTLR
-    bic         r0, r0, #(1 << 28)      @ Clear TRE bit
-    mcr         15, 0, r0, cr1, cr0, 0  @ Write SCTLR
-
-    @ Now install the vector code - we move the Vector code from where it is
-    @ in the image to be based at _rdimon_vector_base.  We have to do this copy
-    @ as the code is all PC-relative.  We actually cheat and do a BX <reg> so
-    @ that we are at a known address relatively quickly and have to move as
-    @ little code as possible.
-    mov         r7, #(VectorCode_Limit - VectorCode)
-    adr         r5, VectorCode
-    adr         r6, vector_base_addr	@ Load the base for vectors
-    ldr         r6, [r6]
-
-copy_loop:                              @ Do the copy
-    ldr         r4, [r5], #4
-    str         r4, [r6], #4
-    subs        r7, r7, #4
-    bne         copy_loop
-
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    bic         r4, r4, #0x1000         @ Disable I Cache
-    bic         r4, r4, #4              @ Disable D Cache
-    orr         r4, r4, #1              @ Enable MMU
-    bic         r4, r4, #(1 << 28)      @ Clear TRE bit
-    mcr         15, 0, r4, cr1, cr0, 0  @ Write SCTLR
-    mrc         15, 0, r4, cr1, cr0, 2  @ Read CPACR
-    orr         r4, r4, #0x00f00000     @ Turn on VFP Co-procs
-    bic         r4, r4, #0x80000000     @ Clear ASEDIS bit
-    mcr         15, 0, r4, cr1, cr0, 2  @ Write CPACR
-    isb
-    mov         r4, #0
-    mcr         15, 0, r4, cr7, cr5, 4  @ Flush prefetch buffer
-    mrc         15, 0, r4, cr1, cr0, 2  @ Read CPACR
-    ubfx        r4, r4, #20, #4		@ Extract bits [20, 23)
-    cmp         r4, #0xf		@ If not all set then the CPU does not
-    itt		eq			@ have FP or Advanced SIMD.
-    moveq       r4, #0x40000000		@ Enable FP and Advanced SIMD
-    mcreq       10, 7, r4, cr8, cr0, 0  @ vmsr  fpexc, r4
-skip_vfp_enable:
-    bl          __enable_caches         @ Turn caches on
-    bx		r10                     @ Return to CRT startup routine
-
-    @ This enable us to be more precise about which caches we want
-init_cpu_client_enable_dcache:
-init_cpu_client_enable_icache:
-    mov         r0, #1
-    bx          lr
-
-vector_base_addr:
-    .word       _rdimon_vector_base
-    .weak       _rdimon_vector_base
-page_table_addr:
-    .word       page_tables
-
-    @ Vector code - must be PIC and in ARM state.
-VectorCode:
-    b           vector_reset
-    b           vector_undef
-    b           vector_swi
-    b           vector_prefetch
-    b           vector_dataabt
-    b           vector_reserved
-    b           vector_irq
-    b           vector_fiq
-
-vector_reset:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #0
-    b           vector_common
-vector_undef:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #1
-    b           vector_common
-vector_swi:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #2
-    b           vector_common
-vector_prefetch:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #3
-    b           vector_common
-vector_dataabt:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #4
-    b           vector_common
-vector_reserved:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #5
-    b           vector_common
-vector_irq:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #6
-    b           vector_common
-vector_fiq:
-    adr         sp, vector_sp_base
-    push        {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
-    mov         r4, #7
-    b           vector_common
-vector_common:
-    adr         r1, vector_common_adr   @ Find where we're going to
-    ldr         r1, [r1]
-    bx          r1                      @ And branch there
-vector_common_adr:
-   .word        vector_common_2         @ Common handling code
-
-                                        @ Vector stack
-   .p2align       3                       @ Align to 8 byte boundary boundary to
-					@ keep ABI compatibility
-   .fill        32, 4, 0                @ 32-entry stack is enough for vector
-					@ handlers.
-vector_sp_base:
-VectorCode_Limit:
-    @ End of PIC code for vectors
-
-    @ Common Handling of vectors
-    .type	vector_common_2, %function
-vector_common_2:
-    mrs         r1, APSR
-    mrs         r2, SPSR
-    push        {r1, r2}                @ Save PSRs
-
-    @ Output the vector we have caught
-    bl          out_nl
-    adr         r0, which_vector
-    bl          out_string
-    adr         r0, vector_names
-    mov         r1, #11
-    mla         r0, r4, r1, r0
-    bl          out_string
-    bl          out_nl
-
-    @ Dump the registers
-    adrl        r6, register_names
-    mov         r7, #0
-dump_r_loop:
-    mov         r0, r6
-    bl          out_string
-    add         r6, r6, #6
-    ldr         r0, [sp, r7, lsl #2]
-    bl          out_word
-    bl          out_nl
-    add         r7, r7, #1
-    cmp         r7, #16
-    blt         dump_r_loop
-    adr         r0, end
-    bl          out_string
-
-    @ And exit
-    mov         r0, #24
-    orr         r1, r4, #0x20000
-    svc         0x00123456
-
-    @ Output the string in r0
-out_string:
-    push        {lr}
-    mov         r1, r0
-    mov         r0, #4
-    svc         0x00123456
-    pop         {pc}
-
-    @ Output a New-line
-out_nl:
-    mov r0, #10
-    @ Fallthrough
-
-    @ Output the character in r0
-out_char:
-    push        {lr}
-    strb        r0, [sp, #-4]!
-    mov         r0, #3
-    mov         r1, sp
-    svc         0x00123456
-    add         sp, sp, #4
-    pop         {pc}
-
-    @ Output the value of r0 as a hex-word
-out_word:
-    push        {r4, r5, r6, lr}
-    mov         r4, r0
-    mov         r5, #28
-    adr         r6, hexchars
-word_loop:
-    lsr         r0, r4, r5
-    and         r0, r0, #15
-    ldrb        r0, [r6, r0]
-    bl          out_char
-    subs        r5, r5, #4
-    bpl         word_loop
-    pop         {r4, r5, r6, pc}
-
-hexchars:
-    .ascii	"0123456789abcdef"
-
-which_vector:
-    .asciz	"Hit vector:"
-end:
-    .asciz	"End.\n"
-
-vector_names:
-    .asciz	"reset     "
-    .asciz	"undef     "
-    .asciz	"swi       "
-    .asciz	"prefetch  "
-    .asciz	"data abort"
-    .asciz	"reserved  "
-    .asciz	"irq       "
-    .asciz	"fiq       "
-
-register_names:
-    .asciz	"apsr "
-    .asciz	"spsr "
-    .asciz	"r0   "
-    .asciz	"r1   "
-    .asciz	"r2   "
-    .asciz	"r3   "
-    .asciz	"r4   "
-    .asciz	"r5   "
-    .asciz	"r6   "
-    .asciz	"r7   "
-    .asciz	"r8   "
-    .asciz	"r9   "
-    .asciz	"r10  "
-    .asciz	"r11  "
-    .asciz	"r12  "
-    .asciz	"r14  "
-
-    .p2align      3
-
-
-    @ Enable the caches
-__enable_caches:
-    mov         r0, #0
-    mcr         15, 0, r0, cr8, cr7, 0  @ Invalidate all unified-TLB
-    mov         r0, #0
-    mcr         15, 0, r0, cr7, cr5, 6  @ Invalidate branch predictor
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    orr         r4, r4, #0x800          @ Enable branch predictor
-    mcr         15, 0, r4, cr1, cr0, 0  @ Set SCTLR
-    mov         r5, lr                  @ Save LR as we're going to BL
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    bl          init_cpu_client_enable_icache
-    cmp         r0, #0
-    it		ne
-    orrne       r4, r4, #0x1000         @ Enable I-Cache
-    bl          init_cpu_client_enable_dcache
-    cmp         r0, #0
-    it		ne
-    orrne       r4, r4, #4
-    mcr         15, 0, r4, cr1, cr0, 0  @ Enable D-Cache
-    bx          r5                      @ Return
-
-__reset_caches:
-    mov         ip, lr                  @ Save LR
-    mov         r0, #0
-    mcr         15, 0, r0, cr7, cr5, 6  @ Invalidate branch predictor
-    mrc         15, 0, r6, cr1, cr0, 0  @ Read SCTLR
-    mrc         15, 0, r0, cr1, cr0, 0  @ Read SCTLR!
-    bic         r0, r0, #0x1000         @ Disable I cache
-    mcr         15, 0, r0, cr1, cr0, 0  @ Write SCTLR
-    mrc         15, 1, r0, cr0, cr0, 1  @ Read CLIDR
-    tst         r0, #3                  @ Harvard Cache?
-    mov         r0, #0
-    it		ne
-    mcrne       15, 0, r0, cr7, cr5, 0  @ Invalidate Instruction Cache?
-
-    mrc         15, 0, r1, cr1, cr0, 0  @ Read SCTLR (again!)
-    orr         r1, r1, #0x800          @ Enable branch predictor
-
-                                        @ If we're not enabling caches we have
-                                        @ no more work to do.
-    bl          init_cpu_client_enable_icache
-    cmp         r0, #0
-    it		ne
-    orrne       r1, r1, #0x1000         @ Enable I-Cache now -
-                                        @ We actually only do this if we have a
-                                        @ Harvard style cache.
-    it		eq
-    bleq        init_cpu_client_enable_dcache
-    itt		eq
-    cmpeq       r0, #0
-    beq         Finished1
-
-    mcr         15, 0, r1, cr1, cr0, 0  @ Write SCTLR (turn on Branch predictor & I-cache)
-
-    mrc         15, 1, r0, cr0, cr0, 1  @ Read CLIDR
-    ands        r3, r0, #0x7000000
-    lsr         r3, r3, #23             @ Total cache levels << 1
-    beq         Finished1
-
-    mov         lr, #0                  @ lr = cache level << 1
-Loop11:
-    mrc         15, 1, r0, cr0, cr0, 1  @ Read CLIDR
-    add         r2, lr, lr, lsr #1      @ r2 holds cache 'set' position
-    lsr         r1, r0, r2              @ Bottom 3-bits are Ctype for this level
-    and         r1, r1, #7              @ Get those 3-bits alone
-    cmp         r1, #2
-    blt         Skip1                   @ No cache or only I-Cache at this level
-    mcr         15, 2, lr, cr0, cr0, 0  @ Write CSSELR
-    mov         r1, #0
-    isb         sy
-    mrc         15, 1, r1, cr0, cr0, 0  @ Read CCSIDR
-    and         r2, r1, #7              @ Extract line length field
-    add         r2, r2, #4              @ Add 4 for the line length offset (log2 16 bytes)
-    movw        r0, #0x3ff
-    ands        r0, r0, r1, lsr #3      @ r0 is the max number on the way size
-    clz         r4, r0                  @ r4 is the bit position of the way size increment
-    movw        r5, #0x7fff
-    ands        r5, r5, r1, lsr #13     @ r5 is the max number of the index size (right aligned)
-Loop21:
-    mov r7, r0                          @ r7 working copy of max way size
-Loop31:
-    orr         r1, lr, r7, lsl r4      @ factor in way number and cache number
-    orr         r1, r1, r5, lsl r2      @ factor in set number
-    tst         r6, #4                  @ D-Cache on?
-    ite         eq
-    mcreq       15, 0, r1, cr7, cr6, 2  @ No - invalidate by set/way
-    mcrne       15, 0, r1, cr7, cr14, 2 @ yes - clean + invalidate by set/way
-    subs        r7, r7, #1              @ Decrement way number
-    bge         Loop31
-    subs        r5, r5, #1              @ Decrement set number
-    bge         Loop21
-Skip1:
-    add         lr, lr, #2              @ increment cache number
-    cmp         r3, lr
-    bgt         Loop11
-Finished1:
-    @ Now we know the caches are clean we can:
-    mrc         15, 0, r4, cr1, cr0, 0  @ Read SCTLR
-    bic         r4, r4, #4              @ Disable D-Cache
-    mcr         15, 0, r4, cr1, cr0, 0  @ Write SCTLR
-    mov         r4, #0
-    mcr         15, 0, r4, cr7, cr5, 6  @ Write BPIALL
-
-    bx          ip                      @ Return
-
-    @ Set Z if this is a Cortex-A15 or Cortex_A7
-    @ Other flags corrupted
-is_a15_a7:
-    mrc         15, 0, r8, c0, c0, 0
-    movw        r9, #0xfff0
-    movt        r9, #0xff0f
-    and         r8, r8, r9
-    movw        r9, #0xc0f0
-    movt        r9, #0x410f
-    cmp         r8, r9
-    movw        r9, #0xc070
-    movt        r9, #0x410f
-    it		ne
-    cmpne       r8, r9
-    bx          lr
-
-    @ Descriptor type: Section
-    @ Bufferable: True
-    @ Cacheable: True
-    @ Execute Never: False
-    @ Domain: 0
-    @ Impl. Defined: 0
-    @ Access: 0/11 Full access
-    @ TEX: 001
-    @ Shareable: False
-    @ Not Global: False
-    @ Supersection: False
-#define PT(X) \
-    .word	X;
-#define PT2(X) \
-    PT(X)  PT(X + 0x100000)    PT(X + 0x200000)    PT(X + 0x300000)
-#define PT3(X) \
-    PT2(X) PT2(X + 0x400000)   PT2(X + 0x800000)   PT2(X + 0xc00000)
-#define PT4(X) \
-    PT3(X) PT3(X + 0x1000000)  PT3(X + 0x2000000)  PT3(X + 0x3000000)
-#define PT5(X) \
-    PT4(X) PT4(X + 0x4000000)  PT4(X + 0x8000000)  PT4(X + 0xc000000)
-#define PT6(X) \
-    PT5(X) PT5(X + 0x10000000) PT5(X + 0x20000000) PT5(X + 0x30000000)
-#define PT7(X) \
-    PT6(X) PT6(X + 0x40000000) PT6(X + 0x80000000) PT6(X + 0xc0000000)
-
-    .section    page_tables_section, "aw", %progbits
-    .p2align    14
-page_tables:
-     PT7(0x1c0e)
-
-#endif //#if defined(__ARM_ARCH_7A__) || __ARM_ARCH_PROFILE == 'A'
--- a/libgloss/libnosys/Makefile.in
+++ b/libgloss/libnosys/Makefile.in
@@ -65,10 +65,7 @@
 	else t='$(program_transform_name)'; echo objcopy | sed -e $$t ; fi`
 
 # object files needed
-OBJS = chown.o close.o environ.o errno.o execve.o fork.o fstat.o \
-	getpid.o gettod.o isatty.o kill.o link.o lseek.o open.o \
-	read.o readlink.o sbrk.o stat.o symlink.o times.o unlink.o \
-	wait.o write.o _exit.o
+OBJS =
 
 # Object files specific to particular targets.
 EVALOBJS = ${OBJS}
