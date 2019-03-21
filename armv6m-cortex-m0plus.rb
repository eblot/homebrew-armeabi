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
    version "8.0.0"


    resource "newlib" do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.1.0.tar.gz'
      sha256 'fb4fa1cc21e9060719208300a61420e4089d6de6ef59cf533b57fe74801d102a'

      patch do
        url "https://gist.githubusercontent.com/eblot/2f0af31b27cf3d6300b190906ae58c5c/raw/de43bc16b7280c97467af09ef329fc527296226e/newlib-arm-eabi-3.1.0.patch"
        sha256 "e30f7f37c9562ef89685c7a69c25139b1047a13be69a0f82459593e7fc3fab90"
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
      url "https://releases.llvm.org/8.0.0/compiler-rt-8.0.0.src.tar.xz"
      sha256 "b435c7474f459e71b2831f1a4e3f1d21203cb9c0172e94e9d9b69f50354f21b1"
    end
  end

  head do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/efb851a6b319dc7b11234f57e88f4a3b05c66560/CMakeLists.txt"
    sha256 "ccb73bd04a60064385e87fc650c6c805771ceecf382a126e764e6c3b15237355"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "9.0.0-dev"

    resource "newlib" do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.1.0.tar.gz'
      sha256 'fb4fa1cc21e9060719208300a61420e4089d6de6ef59cf533b57fe74801d102a'

      patch do
        url "https://gist.githubusercontent.com/eblot/2f0af31b27cf3d6300b190906ae58c5c/raw/de43bc16b7280c97467af09ef329fc527296226e/newlib-arm-eabi-3.1.0.patch"
        sha256 "e30f7f37c9562ef89685c7a69c25139b1047a13be69a0f82459593e7fc3fab90"
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
      ln_s "#{prefix}/armv6m-none-eabi/cortex-m0plus/lib/libcompiler_rt.a",
           "#{prefix}/armv6m-none-eabi/cortex-m0plus/lib/libclang_rt.builtins-arm.a.a"
    end
  end

end
