class Armv7emCortexM4f < Formula
  desc "Newlib & compiler runtime for baremetal Cortex-M4 w/VFP targets"
  homepage "https://sourceware.org/newlib/"
  # and homepage "http://compiler-rt.llvm.org/"

  stable do
    url "https://github.com/llvm/llvm-project/archive/llvmorg-9.0.0.tar.gz"
    sha256 "7807fac25330e24e9955ca46cd855dd34bbc9cc4fdba8322366206654d1036f2"

    patch do
      # use work from Yves Delley
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-support-FPv4-SP.patch"
      sha256 "170da3053537885af5a4f0ae83444a7dbc6c81e4c8b27d0c13bdfa7a18533642"
    end

    resource "newlib" do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.1.0.tar.gz'
      sha256 'fb4fa1cc21e9060719208300a61420e4089d6de6ef59cf533b57fe74801d102a'

      patch do
        url "https://gist.githubusercontent.com/eblot/2f0af31b27cf3d6300b190906ae58c5c/raw/de43bc16b7280c97467af09ef329fc527296226e/newlib-arm-eabi-3.1.0.patch"
        sha256 "e30f7f37c9562ef89685c7a69c25139b1047a13be69a0f82459593e7fc3fab90"
      end
    end
  end

  head do
    url "https://github.com/llvm/llvm-project", :using => :git

    patch do
      # note: there is no guarantee whatsoever than this patch may apply on any LLVM development version
      url "https://raw.githubusercontent.com/burnpanck/docker-llvm-armeabi/10b0c46be7df2c543e21a8ac592eb9fd6c7cea69/patches/0001-support-FPv4-SP.patch"
      sha256 "170da3053537885af5a4f0ae83444a7dbc6c81e4c8b27d0c13bdfa7a18533642"
    end

    resource "newlib" do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.1.0.tar.gz'
      sha256 'fb4fa1cc21e9060719208300a61420e4089d6de6ef59cf533b57fe74801d102a'

      patch do
        url "https://gist.githubusercontent.com/eblot/2f0af31b27cf3d6300b190906ae58c5c/raw/de43bc16b7280c97467af09ef329fc527296226e/newlib-arm-eabi-3.1.0.patch"
        sha256 "e30f7f37c9562ef89685c7a69c25139b1047a13be69a0f82459593e7fc3fab90"
      end
    end
  end

  depends_on "arm-none-eabi-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python" => :build

  def install
    xtarget = "armv7em-none-eabi"
    xcpu = "cortex-m4"
    xcpudir = "cortex-m4f"
    # it is not possible to use -Os for now, as clang integrated assembler rejects an ldrb.w opcode, to be fixed.
    xcflags = "-mfloat-abi=hard -mfpu=fpv4-sp-d16 -mthumb -mabi=aapcs -g -O3 -ffunction-sections -fdata-sections"

    llvm = Formulary.factory 'arm-none-eabi-llvm'

    (buildpath/"newlib").install resource("newlib")

    ENV.append_path "PATH", "#{llvm.bin}"

    ENV['CC_FOR_TARGET']="#{llvm.bin}/clang"
    ENV['AR_FOR_TARGET']="#{llvm.bin}/llvm-ar"
    ENV['NM_FOR_TARGET']="#{llvm.bin}/llvm-nm"
    ENV['RANLIB_FOR_TARGET']="#{llvm.bin}/llvm-ranlib"
    ENV['READELF_FOR_TARGET']="#{llvm.bin}/llvm-readelf"
    ENV['CFLAGS_FOR_TARGET']="-target #{xtarget} -mcpu=#{xcpu} #{xcflags} -Wno-unused-command-line-argument"
    ENV['AS_FOR_TARGET']="#{llvm.bin}/clang"

    host=`cc -dumpmachine`.strip

    mktemp do
      system "#{buildpath}/newlib/configure",
                "--host=#{host}",
                "--build=#{host}",
                "--target=#{xtarget}",
                "--prefix=#{prefix}/#{xtarget}/#{xcpudir}",
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
      system "make -j1 install; true"
      system "mv #{prefix}/#{xtarget}/#{xcpudir}/#{xtarget}/* #{prefix}/#{xtarget}/#{xcpudir}/"
      system "rm -rf #{prefix}/#{xtarget}/#{xcpudir}/#{xtarget}"
    end

    mktemp do
      system "cmake",
                "-G", "Ninja",
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
                "-DCMAKE_ASM_COMPILER_TARGET=#{xtarget}",
                "-DCMAKE_SYSROOT=#{prefix}/#{xtarget}/#{xcpudir}",
                "-DCMAKE_SYSROOT_LINK=#{prefix}/#{xtarget}/#{xcpudir}",
                "-DCMAKE_C_FLAGS=#{xcflags}",
                "-DCMAKE_ASM_FLAGS=#{xcflags}",
                "-DCMAKE_CXX_FLAGS=#{xcflags}",
                "-DCMAKE_EXE_LINKER_FLAGS=-L#{prefix}/#{xtarget}/#{xcpudir}/lib",
                "-DLLVM_CONFIG_PATH=#{llvm.bin}/llvm-config",
                "-DLLVM_DEFAULT_TARGET_TRIPLE=#{xtarget}",
                "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
                "-DLLVM_TARGETS_TO_BUILD=ARM",
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
      system "mv #{prefix}/lib/baremetal/*.a #{prefix}/#{xtarget}/#{xcpudir}/lib"
    end
  end

end
