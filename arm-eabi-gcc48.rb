require 'formula'

class ArmEabiGcc48 <Formula
  url 'http://ftpmirror.gnu.org/gcc/gcc-4.8.2/gcc-4.8.2.tar.bz2'
  homepage 'http://gcc.gnu.org/'
  sha256 '09dc2276c73424bbbfda1dbddc62bbbf900c9f185acf7f3e1d773ce2d7e3cdc8'

  keg_only 'Enable installation of several GCC versions'

  depends_on 'gmp'
  depends_on 'libmpc'
  depends_on 'mpfr'
  depends_on 'arm-eabi-binutils223'
  depends_on 'gcc49' => :build

  resource "newlib20" do
    url 'ftp://sourceware.org/pub/newlib/newlib-2.0.0.tar.gz'
    sha256 '49c29e9129325e7c3b221aa829743ddcd796d024440e47c80fc0d6769af72d8a'
  end

  def patches
    DATA
  end

  def install

    armeabi = 'arm-eabi-binutils223'

    coredir = Dir.pwd

    resource("newlib20").stage do
      system "ditto", Dir.pwd+'/libgloss', coredir+'/libgloss'
      system "ditto", Dir.pwd+'/newlib', coredir+'/newlib'
    end

    gmp = Formula.factory 'gmp'
    mpfr = Formula.factory 'mpfr'
    libmpc = Formula.factory 'libmpc'
    libelf = Formula.factory 'libelf'
    binutils = Formula.factory armeabi
    gcc49 = Formula.factory 'gcc49'

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV['CC'] = "#{gcc49.opt_prefix}/bin/gcc-4.9"
    ENV['CXX'] = "#{gcc49.opt_prefix}/bin/g++-4.9"
    ENV['CFLAGS_FOR_BUILD'] = "-O2"
    ENV['CFLAGS'] = "-O2"
    ENV['CFLAGS_FOR_TARGET'] = "-O2"
    ENV['CXXFLAGS_FOR_BUILD'] = "-O2"
    ENV['CXXFLAGS'] = "-O2"
    ENV['CXXFLAGS_FOR_TARGET'] = "-O2"

    build_dir='build'
    mkdir build_dir
    Dir.chdir build_dir do
      system "../configure", "--prefix=#{prefix}", "--target=arm-eabi",
                  "--disable-shared", "--with-gnu-as", "--with-gnu-ld",
                  "--with-newlib", "--enable-softfloat", "--disable-bigendian",
                  "--disable-fpu", "--disable-underscore", "--enable-multilibs",
                  "--with-float=soft", "--enable-interwork", "--enable-lto",
                  "--with-multilib-list=interwork",
                  "--with-abi=aapcs", "--enable-languages=c,c++",
                  "--with-gmp=#{gmp.opt_prefix}",
                  "--with-mpfr=#{mpfr.opt_prefix}",
                  "--with-mpc=#{libmpc.opt_prefix}",
                  "--with-libelf=#{libelf.opt_prefix}",
                  "--with-gxx-include-dir=#{prefix}/arm-eabi/include",
                  "--disable-debug", "--disable-__cxa_atexit",
                  "--with-pkgversion=SDK2-Legolas"
      # Temp. workaround until GCC installation script is fixed
      system "mkdir -p #{prefix}/arm-eabi/lib/fpu/interwork"
      system "make"
      system "make -j1 -k install"
    end

    ln_s "#{Formula.factory(armeabi).prefix}/arm-eabi/bin",
                   "#{prefix}/arm-eabi/bin"
  end
end

__END__
--- a/gcc/config/arm/t-arm-elf	2011-01-03 21:52:22.000000000 +0100
+++ b/gcc/config/arm/t-arm-elf	2011-07-18 16:03:31.000000000 +0200
@@ -71,8 +71,8 @@
 # MULTILIB_DIRNAMES   += fpu soft
 # MULTILIB_EXCEPTIONS += *mthumb/*mhard-float*
 # 
-# MULTILIB_OPTIONS    += mno-thumb-interwork/mthumb-interwork
-# MULTILIB_DIRNAMES   += normal interwork
+MULTILIB_OPTIONS    += mno-thumb-interwork/mthumb-interwork
+MULTILIB_DIRNAMES   += normal interwork
 # 
 # MULTILIB_OPTIONS    += fno-leading-underscore/fleading-underscore
 # MULTILIB_DIRNAMES   += elf under
