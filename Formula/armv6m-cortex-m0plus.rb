require "formula"

class Armv6mCortexM0plus < Formula
  desc "C and C++ libraries for baremetal Cortex-M0+ targets"
  homepage "https://llvm.org/"
  # and "https://sourceware.org/newlib/"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.3/llvm-project-17.0.3.src.tar.xz"
    sha256 "be5a1e44d64f306bb44fce7d36e3b3993694e8e6122b2348608906283c176db8"

    resource "newlib" do
      url "ftp://sourceware.org/pub/newlib/newlib-4.2.0.20211231.tar.gz"
      sha256 "c3a0e8b63bc3bef1aeee4ca3906b53b3b86c8d139867607369cb2915ffc54435"

      patch do
        url "https://gist.githubusercontent.com/eblot/08f3774e913a2734ad5a2120fbb8802a/raw/13911c67219445771527bbe08a1c23cfeb1be851/newlib-stdio.diff"
        sha256 "495d1cff0607e3df0fae398542b150dd9e46b79b4c11c4d67722edc70679a355"
      end

      patch do
        url "https://gist.githubusercontent.com/eblot/5217dea8003deb9884f77171d521a519/raw/879d6a2500b1a53fb34a64946b98ac477a23d400/newlib-libgloss-arm-none-eabi.diff"
        sha256 "49f73f94a55cff74fc1b294892b34e1d55f25ce2f427a080fe47e1cbdc986aa5"
      end

      patch do
        url "https://gist.githubusercontent.com/eblot/7cf3590518167f37e6cb7ff0cb801d04/raw/bdec4f2dedc328fc7df15194478c80cab480d175/newlib-libgloss-armv6m-none-eabi.diff"
        sha256 "76e625f7d933cb2b52aa02cff144316eb28bbdfef341c4204ea1673df7eb2c60"
      end

      patch do
        url "https://github.com/eblot/newlib-cygwin/commit/544e68a14f2e1c4c53f04cce84343d7bbf0499d0.diff?full_index=1"
        sha256 "b5e2eb40763712a0a2e1f2fa3fb8df43ed087f2c613e5c92f67cb66d0157cfc4"
      end
    end
  end

  # build system is stupid enough to consider cross-compiled C++ static
  # libraries as potential candidates for future LLVM/Clang compiler builds...
  # do not let this formula to install C++ libraries with system-wide
  # visibility
  keg_only "conflict with llvm"

  depends_on "arm-none-eabi-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python" => :build

  def install
    llvm = Formulary.factory "arm-none-eabi-llvm"

    xtarget = "armv6m-none-eabi"
    xcpu = "cortex-m0plus"
    xcpudir = "cortex-m0plus"

    xabi = "-mthumb -mabi=aapcs -fshort-enums"
    xfpu = "-mfloat-abi=soft"
    xopts = "-g -Os"
    xcfeatures = "-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"
    xcxxfeatures = "#{xcfeatures} -fno-use-cxa-atexit"

    xctarget = "-mcpu=#{xcpu} #{xabi}"
    xsysroot = "#{prefix}/#{xtarget}/#{xcpudir}"

    xcxxdefs = "-D_LIBUNWIND_IS_BAREMETAL=1 -D_GNU_SOURCE=1 -D_POSIX_TIMERS=1"
    xcxxdefs = "#{xcxxdefs} -D_LIBCPP_HAS_NO_LIBRARY_ALIGNED_ALLOCATION"
    xcxxnothread = "-D_LIBCPP_HAS_NO_THREADS=1"

    xcxx_inc = "-I#{xsysroot}/include"
    xcxx_lib = "-L#{xsysroot}/lib"

    xcflags = "#{xctarget} #{xfpu} #{xopts} #{xcfeatures}"
    xcxxflags = "#{xctarget} #{xfpu} #{xopts} #{xcxxfeatures} #{xcxxdefs} #{xcxx_inc}"

    (buildpath/"newlib").install resource("newlib")

    ENV.append_path "PATH", "#{llvm.bin}"

    ENV["CC_FOR_TARGET"] = "#{llvm.bin}/clang"
    ENV["AR_FOR_TARGET"] = "#{llvm.bin}/llvm-ar"
    ENV["NM_FOR_TARGET"] = "#{llvm.bin}/llvm-nm"
    ENV["RANLIB_FOR_TARGET"] = "#{llvm.bin}/llvm-ranlib"
    ENV["READELF_FOR_TARGET"] = "#{llvm.bin}/llvm-readelf"
    ENV["CFLAGS_FOR_TARGET"] = "-target #{xtarget} #{xcflags} -Wno-unused-command-line-argument"
    ENV["AS_FOR_TARGET"] = "#{llvm.bin}/clang"

    host=`cc -dumpmachine`.strip

    # Note: beware that enable assertions disables CMake's NDEBUG flag, which
    # in turn enable calls to fprintf/fflush and other stdio API, which may
    # add up 40KB to the final executable...

    mktemp do
      puts "--- newlib ---"
      system "#{buildpath}/newlib/configure",
                "--host=#{host}",
                "--build=#{host}",
                "--target=#{xtarget}",
                "--prefix=#{xsysroot}",
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
                "--enable-newlib-io-float",
                "--disable-newlib-io-long-double",
                "--disable-nls"
      system "make"
      # deparallelise (-j1) is required or installer fails to create output dir
      system "make -j1 install; true"
      system "mv #{xsysroot}/#{xtarget}/* #{xsysroot}/"
      system "rm -rf #{xsysroot}/#{xtarget}"
    end
    # newlib

    mktemp do
      puts "--- compiler-rt ---"
      system "cmake",
                "-G", "Ninja",
                "-DCMAKE_INSTALL_PREFIX=#{xsysroot}",
                "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
                "-DCMAKE_SYSTEM_PROCESSOR=arm",
                "-DCMAKE_SYSTEM_NAME=Generic",
                "-DCMAKE_CROSSCOMPILING=ON",
                "-DCMAKE_CXX_COMPILER_FORCED=TRUE",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_C_COMPILER=#{llvm.bin}/clang",
                "-DCMAKE_CXX_COMPILER=#{llvm.bin}/clang++",
                "-DCMAKE_LINKER=#{llvm.bin}/clang",
                "-DCMAKE_AR=#{llvm.bin}/llvm-ar",
                "-DCMAKE_RANLIB=#{llvm.bin}/llvm-ranlib",
                "-DCMAKE_C_COMPILER_TARGET=#{xtarget}",
                "-DCMAKE_ASM_COMPILER_TARGET=#{xtarget}",
                "-DCMAKE_SYSROOT=#{xsysroot}",
                "-DCMAKE_SYSROOT_LINK=#{xsysroot}",
                "-DCMAKE_C_FLAGS=#{xcflags}",
                "-DCMAKE_ASM_FLAGS=#{xcflags}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xsysroot}/lib",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_DEFAULT_TARGET_TRIPLE=#{xtarget}",
                "-DLLVM_TARGETS_TO_BUILD=ARM",
                "-DLLVM_ENABLE_PIC=OFF",
                "-DCOMPILER_RT_OS_DIR=baremetal",
                "-DCOMPILER_RT_BUILD_BUILTINS=ON",
                "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
                "-DCOMPILER_RT_BUILD_XRAY=OFF",
                "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
                "-DCOMPILER_RT_BUILD_PROFILE=OFF",
                "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
                "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
                "-DCOMPILER_RT_INCLUDE_TESTS=OFF",
                "-DCOMPILER_RT_USE_LIBCXX=ON",
                "-DUNIX=1",
                "#{buildpath}/compiler-rt"
      system "ninja"
      system "ninja install"
      system "mv #{xsysroot}/lib/baremetal/* #{xsysroot}/lib"
      system "rmdir #{xsysroot}/lib/baremetal"
    end
    # compiler-rt

    puts "--- C++ ---"
    mkdir "build"
    system "cmake",
      "-G", "Ninja", "-S", "runtimes", "-B", "build",
      "-DUNIX=1",
      "-DCMAKE_INSTALL_PREFIX=#{xsysroot}",
      "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
      "-DCMAKE_SYSTEM_PROCESSOR=arm",
      "-DCMAKE_SYSTEM_NAME=Generic",
      "-DCMAKE_CROSSCOMPILING=ON",
      "-DCMAKE_CXX_COMPILER_FORCED=TRUE",
      "-DCMAKE_BUILD_TYPE=Release",
      "-DCMAKE_C_COMPILER=#{llvm.bin}/clang",
      "-DCMAKE_CXX_COMPILER=#{llvm.bin}/clang++",
      "-DCMAKE_LINKER=#{llvm.bin}/clang",
      "-DCMAKE_AR=#{llvm.bin}/llvm-ar",
      "-DCMAKE_RANLIB=#{llvm.bin}/llvm-ranlib",
      "-DCMAKE_C_COMPILER_TARGET=#{xtarget}",
      "-DCMAKE_CXX_COMPILER_TARGET=#{xtarget}",
      "-DCMAKE_SYSROOT=#{xsysroot}",
      "-DCMAKE_SYSROOT_LINK=#{xsysroot}",
      "-DCMAKE_C_FLAGS=#{xcflags}",
      "-DCMAKE_CXX_FLAGS=#{xcxxflags}",
      "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
      "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind",
      "-DLLVM_INCLUDE_TESTS=OFF",
      "-DLLVM_ENABLE_PIC=OFF",
      "-DLIBCXX_ENABLE_FILESYSTEM=OFF",
      "-DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF",
      "-DLIBCXX_ENABLE_SHARED=OFF",
      "-DLIBCXX_ENABLE_STATIC=ON",
      "-DLIBCXX_ENABLE_THREADS=OFF",
      "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
      "-DLIBCXXABI_ENABLE_SHARED=OFF",
      "-DLIBCXXABI_ENABLE_STATIC=ON",
      "-DLIBCXXABI_ENABLE_THREADS=OFF",
      "-DLIBUNWIND_ENABLE_SHARED=OFF",
      "-DLIBUNWIND_ENABLE_STATIC=ON",
      "-DLIBUNWIND_ENABLE_THREADS=OFF",
      "-DLIBUNWIND_INCLUDE_DOCS=OFF",
      "-DLIBUNWIND_INCLUDE_TESTS=OFF",
      "-DLIBUNWIND_IS_BAREMETAL=ON",
      "-DLIBUNWIND_REMEMBER_HEAP_ALLOC=ON",
      "-DLIBUNWIND_USE_COMPILER_RT=ON"
    system "ninja -C build cxx cxxabi unwind"
    system "ninja -C build install-cxx install-cxxabi install-unwind"
    # C++

  end
  # install
end
# formula



