class Armv7emCortexM4fCxx < Formula
  desc "C++ support for baremetal Cortex-M4 w/VFP targets"
  homepage "https://llvm.org/"

  stable do
    url "https://github.com/llvm/llvm-project/archive/llvmorg-9.0.0.tar.gz"
    sha256 "7807fac25330e24e9955ca46cd855dd34bbc9cc4fdba8322366206654d1036f2"

    # use work from Yves Delley
    patch do
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-enable-atomic-header-on-thread-less-builds.patch"
      sha256 "02db625a01dff58cfd4d6f7a73355e4148c39c920902c497d49c0e3e55cfb191"
    end

    patch do
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-explicitly-specify-location-of-libunwind-in-static-b.patch"
      sha256 "cb46ee6e3551c37a61d6563b8e52b7f5b5a493e559700a147ee29b970c659c11"
    end

  end

  depends_on "arm-none-eabi-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python" => :build
  depends_on "armv7em-cortex-m4f"

  def install
    llvm = Formulary.factory 'arm-none-eabi-llvm'
    xrt = Formulary.factory 'armv7em-cortex-m4f'

    xtarget = "armv7em-none-eabi"
    xcpu = "cortex-m4"
    xcpudir = "cortex-m4f"
    xabi = "-mthumb -mabi=aapcs"
    xcxxfpu = "-mfloat-abi=hard -mfpu=fpv4-sp-d16"
    xcxxopts = "-g -Os"
    xcxxfeatures = "-ffunction-sections -fdata-sections -fno-stack-protector -fvisibility=hidden"
    xcxxdefs = "-D_LIBUNWIND_IS_BAREMETAL=1 -D_GNU_SOURCE=1 -D_POSIX_TIMERS=1 -D_LIBCPP_HAS_NO_LIBRARY_ALIGNED_ALLOCATION"
    xcxxnothread = "-D_LIBCPP_HAS_NO_THREADS=1"

    xsysroot = "#{xrt.prefix}/#{xtarget}/#{xcpudir}"
    xcxx_inc="-I${xsysroot}/include"
    xcxx_lib="-L${xsysroot}/lib"

    xcxxtarget = "-mcpu=#{xcpu} #{xabi}"
    xcxxflags = "#{xcxxtarget} #{xcxxfpu} #{xcxxopts} #{xcxxfeatures} #{xcxxdefs} #{xcxx_inc}"

    ENV.append_path "PATH", "#{llvm.bin}"

    mktemp do
      system "echo LibCXX"
      system "cmake",
                "-G", "Ninja", "-Wno-dev",
                "-DCMAKE_INSTALL_PREFIX=#{prefix}",
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
                "-DCMAKE_C_FLAGS=#{xcxxflags}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
                "-DLLVM_TARGETS_TO_BUILD=ARM",
                "-DLIBCXX_ENABLE_SHARED=OFF",
                "-DLIBCXX_ENABLE_FILESYSTEM=OFF",
                "-DLIBCXX_ENABLE_THREADS=OFF",
                "-DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF",
                "-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF",
                "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON",
                "-DLIBCXX_INCLUDE_TESTS=OFF",
                "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
                "-DLIBCXX_USE_COMPILER_RT=ON",
                "-DLIBCXX_CXX_ABI=libcxxabi",
                "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=#{buildpath}/libcxxabi/include",
                "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
                "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
                "-DUNIX=1",
                "#{buildpath}/libcxx"

      system "ninja"
      system "ninja install"
    end

    mktemp do
      system "echo LibUnwind"
      system "cmake",
                "-G", "Ninja", "-Wno-dev",
                "-DCMAKE_INSTALL_PREFIX=#{prefix}",
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
                "-DCMAKE_C_FLAGS=#{xcxxflags} #{xcxxnothread}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags} #{xcxxnothread}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
                "-DLLVM_TARGETS_TO_BUILD=ARM",
                "-DLIBUNWIND_ENABLE_ASSERTIONS=ON",
                "-DLIBUNWIND_ENABLE_PEDANTIC=ON",
                "-DLIBUNWIND_ENABLE_SHARED=OFF",
                "-DLIBUNWIND_ENABLE_THREADS=OFF",
                "-DLIBCXXABI_LIBCXX_PATH=#{prefix}",
                "-DLIBCXXABI_LIBCXX_INCLUDES=#{prefix}/include/c++/v1",
                "-DLLVM_ENABLE_LIBCXX=TRUE",
                "-DUNIX=1",
                "#{buildpath}/libunwind"

      system "ninja"
      system "ninja install"
    end

    mktemp do
      system "echo LibCxxAbi"
      system "cmake",
                "-G", "Ninja", "-Wno-dev",
                "-DCMAKE_INSTALL_PREFIX=#{prefix}",
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
                "-DCMAKE_C_FLAGS=#{xcxxflags}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
                "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
                "-DLIBCXXABI_USE_COMPILER_RT=ON",
                "-DLIBCXXABI_ENABLE_THREADS=OFF",
                "-DLIBCXXABI_ENABLE_SHARED=OFF",
                "-DLIBCXXABI_BAREMETAL=ON",
                "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
                "-DLIBCXXABI_SILENT_TERMINATE=ON",
                "-DLIBCXXABI_INCLUDE_TESTS=OFF",
                "-DLIBCXXABI_LIBCXX_SRC_DIRS=#{buildpath}/libcxx",
                "-DLIBCXXABI_LIBUNWIND_LINK_FLAGS=-L#{prefix}/lib",
                "-DLIBCXXABI_LIBCXX_PATH=#{buildpath}/libcxx",
                "-DLIBCXXABI_LIBCXX_INCLUDES=#{prefix}/include/c++/v1",
                "-DUNIX=1",
                "#{buildpath}/libcxxabi"

      system "ninja"
      system "ninja install"
    end
  end

end
