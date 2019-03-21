class Armv7emCortexM4f < Formula
  desc "Newlib & compiler runtime for baremetal Cortex-M4F targets"
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
    ENV['CFLAGS_FOR_TARGET']="-target armv7em-none-eabi -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -mthumb -mabi=aapcs -g -O3 -ffunction-sections -fdata-sections -Wno-unused-command-line-argument"
    ENV['AS_FOR_TARGET']="#{llvm.opt_prefix}/bin/clang"

    host=`cc -dumpmachine`.strip

    mktemp do
      system buildpath/"newlib/configure",
                "--host=#{host}",
                "--build=#{host}",
                "--target=armv7em-none-eabi",
                "--prefix=#{prefix}/armv7em-none-eabi/cortex-m4f",
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
      system "mv #{prefix}/armv7em-none-eabi/cortex-m4f/armv7em-none-eabi/* #{prefix}/armv7em-none-eabi/cortex-m4f/"
      system "rm -rf #{prefix}/armv7em-none-eabi/cortex-m4f/armv7em-none-eabi"
    end

    mktemp do
      # custom CMakeLists.txt not installed as a resource, so duplicate it for
      # the sake of simplicity. Did I write I hate ruby as a language?
      mkdir_p "#{buildpath}/compiler-rt/cortex-m"
      cp "#{buildpath}/CMakeLists.txt", "#{buildpath}/compiler-rt/cortex-m/CMakeLists.txt"
      system "cmake",
                "-G", "Ninja",
                "-DXTARGET=armv7em-none-eabi",
                "-DXCPU=cortex-m4",
                "-DXCPUDIR=cortex-m4f",
                "-DXCFLAGS=-mfloat-abi=hard -mfpu=fpv4-sp-d16",
                "-DXNEWLIB=#{prefix}/armv7em-none-eabi/cortex-m4f",
                buildpath/"compiler-rt/cortex-m"
      system "ninja"
      system "cp libcompiler_rt.a #{prefix}/armv7em-none-eabi/cortex-m4f/lib/"
      ln_s "#{prefix}/armv7em-none-eabi/cortex-m4f/lib/libcompiler_rt.a",
           "#{prefix}/armv7em-none-eabi/cortex-m4f/lib/libclang_rt.builtins-armv7em.a.a"
      ln_s "#{prefix}/armv7em-none-eabi/cortex-m4f/lib/libcompiler_rt.a",
           "#{prefix}/armv7em-none-eabi/cortex-m4f/lib/libclang_rt.builtins-arm.a.a"
    end
  end

end
