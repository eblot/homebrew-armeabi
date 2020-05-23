require "formula"

class Armv6mCortexM0plus < Formula
  desc "C and C++ libraries for baremetal Cortex-M0+ targets"
  homepage "https://llvm.org/"
  # and "https://sourceware.org/newlib/"

  stable do
    url "https://github.com/llvm/llvm-project/archive/llvmorg-10.0.0.tar.gz"
    sha256 "b81c96d2f8f40dc61b14a167513d87c0d813aae0251e06e11ae8a4384ca15451"

    # use work from Yves Delley
    patch do
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-support-FPv4-SP.patch"
      sha256 "170da3053537885af5a4f0ae83444a7dbc6c81e4c8b27d0c13bdfa7a18533642"
    end

    patch do
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-enable-atomic-header-on-thread-less-builds.patch"
      sha256 "02db625a01dff58cfd4d6f7a73355e4148c39c920902c497d49c0e3e55cfb191"
    end

    patch do
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-explicitly-specify-location-of-libunwind-in-static-b.patch"
      sha256 "cb46ee6e3551c37a61d6563b8e52b7f5b5a493e559700a147ee29b970c659c11"
    end

    resource "newlib" do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz'
      sha256 '58dd9e3eaedf519360d92d84205c3deef0b3fc286685d1c562e245914ef72c66'

      patch do
        url "https://gist.githubusercontent.com/eblot/2f0af31b27cf3d6300b190906ae58c5c/raw/de43bc16b7280c97467af09ef329fc527296226e/newlib-arm-eabi-3.1.0.patch"
        sha256 "e30f7f37c9562ef89685c7a69c25139b1047a13be69a0f82459593e7fc3fab90"
      end

      patch do
        url "https://gist.githubusercontent.com/eblot/43509ee1803b835d1b51f92700efb4d2/raw/c899e4b1b93769faac897694a249ccd339ba24e7/newlib-3.3.0-armv6m.diff"
        sha256 "ab2a3d5a597f54585ebdde243cc20926f0feabc33afb896f049a130119e8e3a3"
      end

      patch do
        url "https://github.com/eblot/newlib-cygwin/commit/544e68a14f2e1c4c53f04cce84343d7bbf0499d0.diff"
        sha256 "f155b4f0dc2ec9c5c5ba1be1454abe8db51e089d22fc2181b91eb94c2fc3ad29"
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
    llvm = Formulary.factory 'arm-none-eabi-llvm'

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

    xcxxdefs = "-D_LIBUNWIND_IS_BAREMETAL=1 -D_GNU_SOURCE=1 -D_POSIX_TIMERS=1 -D_LIBCPP_HAS_NO_LIBRARY_ALIGNED_ALLOCATION"
    xcxxnothread = "-D_LIBCPP_HAS_NO_THREADS=1"

    xcxx_inc = "-I#{xsysroot}/include"
    xcxx_lib = "-L#{xsysroot}/lib"

    xcflags = "#{xctarget} #{xfpu} #{xopts} #{xcfeatures}"
    xcxxflags = "#{xctarget} #{xfpu} #{xopts} #{xcxxfeatures} #{xcxxdefs} #{xcxx_inc}"

    (buildpath/"newlib").install resource("newlib")

    ENV.append_path "PATH", "#{llvm.bin}"

    ENV['CC_FOR_TARGET']="#{llvm.bin}/clang"
    ENV['AR_FOR_TARGET']="#{llvm.bin}/llvm-ar"
    ENV['NM_FOR_TARGET']="#{llvm.bin}/llvm-nm"
    ENV['RANLIB_FOR_TARGET']="#{llvm.bin}/llvm-ranlib"
    ENV['READELF_FOR_TARGET']="#{llvm.bin}/llvm-readelf"
    ENV['CFLAGS_FOR_TARGET']="-target #{xtarget} #{xcflags} -Wno-unused-command-line-argument"
    ENV['AS_FOR_TARGET']="#{llvm.bin}/clang"

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
    end # newlib

    mktemp do
      puts "--- compiler-rt ---"
      system "cmake",
                "-G", "Ninja",
                *(std_cmake_args),
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
                "-DCMAKE_CXX_FLAGS=#{xcflags}",
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
    end # compiler-rt

    mktemp do
      puts "--- libcxx ---"
      system "cmake",
                "-G", "Ninja",
                *(std_cmake_args),
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
                "-DCMAKE_C_FLAGS=#{xcxxflags}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_TARGETS_TO_BUILD=ARM",
                "-DLLVM_ENABLE_PIC=OFF",
                "-DLIBCXX_ENABLE_ASSERTIONS=OFF",
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
    end # libcxx

    mktemp do
      puts "--- libunwind ---"
      system "cmake",
                "-G", "Ninja",
                *(std_cmake_args),
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
                "-DCMAKE_C_FLAGS=#{xcxxflags} #{xcxxnothread}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags} #{xcxxnothread}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_ENABLE_PIC=OFF",
                "-DLIBUNWIND_ENABLE_ASSERTIONS=OFF",
                "-DLIBUNWIND_ENABLE_PEDANTIC=ON",
                "-DLIBUNWIND_ENABLE_SHARED=OFF",
                "-DLIBUNWIND_ENABLE_THREADS=OFF",
                "-DLLVM_ENABLE_LIBCXX=TRUE",
                "-DUNIX=1",
                "#{buildpath}/libunwind"
      system "ninja"
      system "ninja install"
    end # libunwind

    mktemp do
      puts "--- libcxxabi ---"
      system "cmake",
                "-G", "Ninja",
                *(std_cmake_args),
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
                "-DCMAKE_C_FLAGS=#{xcxxflags}",
                "-DCMAKE_CXX_FLAGS=#{xcxxflags}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{xcxx_lib}",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_ENABLE_PIC=OFF",
                "-DLIBCXXABI_ENABLE_ASSERTIONS=OFF",
                "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
                "-DLIBCXXABI_USE_COMPILER_RT=ON",
                "-DLIBCXXABI_ENABLE_THREADS=OFF",
                "-DLIBCXXABI_ENABLE_SHARED=OFF",
                "-DLIBCXXABI_BAREMETAL=ON",
                "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
                "-DLIBCXXABI_SILENT_TERMINATE=ON",
                "-DLIBCXXABI_INCLUDE_TESTS=OFF",
                "-DLIBCXXABI_LIBCXX_SRC_DIRS=#{buildpath}/libcxx",
                "-DLIBCXXABI_LIBUNWIND_LINK_FLAGS=-L#{xsysroot}/lib",
                "-DLIBCXXABI_LIBCXX_PATH=#{buildpath}/libcxx",
                "-DLIBCXXABI_LIBCXX_INCLUDES=#{xsysroot}/include/c++/v1",
                "-DUNIX=1",
                "#{buildpath}/libcxxabi"
      system "ninja"
      system "ninja install"
    end # libcxxabi

  end # install

end # formula
