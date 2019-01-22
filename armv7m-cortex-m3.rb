class Armv7mCortexM3 < Formula
  desc "Newlib & compiler runtime for baremetal Cortex-M3 targets"
  homepage "https://sourceware.org/newlib/"
  # and homepage "http://compiler-rt.llvm.org/"

  stable do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/efb851a6b319dc7b11234f57e88f4a3b05c66560/CMakeLists.txt"
    sha256 "ccb73bd04a60064385e87fc650c6c805771ceecf382a126e764e6c3b15237355"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "7.0.1"

    resource 'newlib' do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.1.0.20181231.tar.gz'
      sha256 '9e12fea7297648b114434033ed4458755afe7b9b6c7d58123389e82bd37681c0'

      patch do
        url "https://gist.githubusercontent.com/eblot/2f0af31b27cf3d6300b190906ae58c5c/raw/de43bc16b7280c97467af09ef329fc527296226e/newlib-arm-eabi-3.1.0.patch"
        sha256 "e30f7f37c9562ef89685c7a69c25139b1047a13be69a0f82459593e7fc3fab90"
      end
    end

    resource "compiler-rt" do
      url "https://releases.llvm.org/7.0.1/compiler-rt-7.0.1.src.tar.xz"
      sha256 "782edfc119ee172f169c91dd79f2c964fb6b248bd9b73523149030ed505bbe18"
    end
  end

  head do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/efb851a6b319dc7b11234f57e88f4a3b05c66560/CMakeLists.txt"
    sha256 "ccb73bd04a60064385e87fc650c6c805771ceecf382a126e764e6c3b15237355"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "8.0.0-dev"

    resource 'newlib' do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.0.0.tar.gz'
      sha256 'c8566335ee74e5fcaeb8595b4ebd0400c4b043d6acb3263ecb1314f8f5501332'

      patch do
        url "https://gist.githubusercontent.com/eblot/135ad4fe89008d54fdea89cdadc420de/raw/bd976c82203bf89d4b4ebc141014a88e2e8ba6f1/newlib-arm-eabi-3.0.0.patch"
        sha256 "b2993bc29d83fddd436a7574e680aeae72feab165b9518ba19dcfea60df64b77"
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
    ENV['CFLAGS_FOR_TARGET']="-target armv7m-none-eabi -mcpu=cortex-m3 -mfloat-abi=soft -mthumb -mabi=aapcs -g -O3 -ffunction-sections -fdata-sections -Wno-unused-command-line-argument"
    ENV['AS_FOR_TARGET']="#{llvm.opt_prefix}/bin/clang"

    host=`cc -dumpmachine`.strip

    mktemp do
      system buildpath/"newlib/configure",
                "--host=#{host}",
                "--build=#{host}",
                "--target=armv7m-none-eabi",
                "--prefix=#{prefix}/armv7m-none-eabi/cortex-m3",
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
      system "mv #{prefix}/armv7m-none-eabi/cortex-m3/armv7m-none-eabi/* #{prefix}/armv7m-none-eabi/cortex-m3/"
      system "rm -rf #{prefix}/armv7m-none-eabi/cortex-m3/armv7m-none-eabi"
    end

    mktemp do
      # custom CMakeLists.txt not installed as a resource, so duplicate it for
      # the sake of simplicity. Did I write I hate ruby as a language?
      mkdir_p "#{buildpath}/compiler-rt/cortex-m"
      cp "#{buildpath}/CMakeLists.txt", "#{buildpath}/compiler-rt/cortex-m/CMakeLists.txt"
      system "cmake",
                "-G", "Ninja",
                "-DXTARGET=armv7m-none-eabi",
                "-DXCPU=cortex-m3",
                "-DXCPUDIR=cortex-m3",
                "-DXCFLAGS=-mfloat-abi=soft",
                "-DXNEWLIB=#{prefix}/armv7m-none-eabi/cortex-m3",
                 buildpath/"compiler-rt/cortex-m"
      system "ninja"
      system "cp libcompiler_rt.a #{prefix}/armv7m-none-eabi/cortex-m3/lib/"
      ln_s "#{prefix}/armv7m-none-eabi/cortex-m3/lib/libcompiler_rt.a",
           "#{prefix}/armv7m-none-eabi/cortex-m3/lib/libclang_rt.builtins-armv7m.a.a"
      ln_s "#{prefix}/armv7m-none-eabi/cortex-m3/lib/libcompiler_rt.a",
           "#{prefix}/armv7m-none-eabi/cortex-m3/lib/libclang_rt.builtins-arm.a.a"
    end
  end

end
