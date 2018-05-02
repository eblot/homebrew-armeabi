class Armv7mCortexM3 < Formula
  desc "Newlib & compiler runtime for baremetal Cortex-M3 targets"
  homepage "https://sourceware.org/newlib/"
  # and homepage "http://compiler-rt.llvm.org/"

  stable do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/00bb3af1f74ee0f27afb0e5e9ce7ee4fedcefe28/CMakeLists.txt"
    sha256 "578874c9cedecca03a96a134389534a5922ba4362c0a883cdfb2de554a415901"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "6.0.0"

    resource 'newlib' do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.0.0.tar.gz'
      sha256 'c8566335ee74e5fcaeb8595b4ebd0400c4b043d6acb3263ecb1314f8f5501332'

      patch :p1, :DATA
    end

    resource "compiler-rt" do
      url "https://releases.llvm.org/6.0.0/compiler-rt-6.0.0.src.tar.xz"
      sha256 "d0cc1342cf57e9a8d52f5498da47a3b28d24ac0d39cbc92308781b3ee0cea79a"
    end
  end

  head do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/00bb3af1f74ee0f27afb0e5e9ce7ee4fedcefe28/CMakeLists.txt"
    sha256 "578874c9cedecca03a96a134389534a5922ba4362c0a883cdfb2de554a415901"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "7.0.0-dev"

    resource 'newlib' do
      url 'ftp://sourceware.org/pub/newlib/newlib-3.0.0.tar.gz'
      sha256 'c8566335ee74e5fcaeb8595b4ebd0400c4b043d6acb3263ecb1314f8f5501332'

      patch :p1, :DATA
    end

    resource "compiler-rt" do
      url "http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_600/final", :using => :svn
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
                "--disable-nls",
                "--disable-libgloss"
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

