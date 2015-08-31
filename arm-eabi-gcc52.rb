require 'formula'

class ArmEabiGcc52 <Formula
  homepage 'https://gcc.gnu.org'
  url      'http://ftpmirror.gnu.org/gcc/gcc-5.2.0/gcc-5.2.0.tar.bz2'
  mirror   'https://ftp.gnu.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.bz2'
  sha256   '5f835b04b5f7dd4f4d2dc96190ec1621b8d89f2dc6f638f9f8bc1b1014ba8cad'

  keg_only 'Enable installation of several GCC versions'

  depends_on 'gmp'
  depends_on 'libmpc'
  depends_on 'mpfr'
  depends_on 'isl014'
  depends_on 'arm-eabi-binutils225'
  depends_on 'gcc5' => :build

  resource 'newlib22' do
    url    'ftp://sourceware.org/pub/newlib/newlib-2.2.0.20150623.tar.gz'
    sha256 'b938fa06f61cc54b52cdc1e049982cc2624e6b4301feaf2cbe3a47ca610a7e86'
  end

  def install

    armeabi = 'arm-eabi-binutils225'

    coredir = Dir.pwd

    resource('newlib22').stage do
      system 'ditto', Dir.pwd+'/libgloss', coredir+'/libgloss'
      system 'ditto', Dir.pwd+'/newlib', coredir+'/newlib'
    end

    gmp = Formula.factory 'gmp'
    mpfr = Formula.factory 'mpfr'
    libmpc = Formula.factory 'libmpc'
    libelf = Formula.factory 'libelf'
    isl014 = Formula.factory 'isl014'
    binutils = Formula.factory armeabi
    gcc5 = Formula.factory 'gcc5'

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV['CC'] = "#{gcc5.opt_prefix}/bin/gcc-5"
    ENV['CXX'] = "#{gcc5.opt_prefix}/bin/g++-5"
    ENV['CFLAGS_FOR_BUILD'] = "-O2"
    ENV['CFLAGS'] = "-O2"
    ENV['CFLAGS_FOR_TARGET'] = "-O2"
    ENV['CXXFLAGS_FOR_BUILD'] = "-O2"
    ENV['CXXFLAGS'] = "-O2"
    ENV['CXXFLAGS_FOR_TARGET'] = "-O2"

    build_dir='build'
    mkdir build_dir
    Dir.chdir build_dir do
      system coredir+"/configure", "--prefix=#{prefix}", "--target=arm-eabi",
                  "--disable-shared", "--with-gnu-as", "--with-gnu-ld",
                  "--with-newlib", "--enable-softfloat", "--disable-bigendian",
                  "--disable-fpu", "--disable-underscore", "--enable-multilibs",
                  "--with-float=soft", "--enable-interwork", "--enable-lto",
                  "--with-multilib", "--enable-plugins",
                  "--with-abi=aapcs", "--enable-languages=c,c++",
                  "--with-gmp=#{gmp.opt_prefix}",
                  "--with-mpfr=#{mpfr.opt_prefix}",
                  "--with-mpc=#{libmpc.opt_prefix}",
                  "--with-isl=#{isl014.opt_prefix}",
                  "--with-libelf=#{libelf.opt_prefix}",
                  "--with-gxx-include-dir=#{prefix}/arm-eabi/include",
                  "--disable-debug", "--disable-__cxa_atexit",
                  "--with-pkgversion=SDK2-Xharlion"
      # Temp. workaround until GCC installation script is fixed
      system "mkdir -p #{prefix}/arm-eabi/lib/fpu/interwork"
      system "make"
      system "make -j1 -k install"
    end

    ln_s "#{Formula.factory(armeabi).prefix}/arm-eabi/bin",
                   "#{prefix}/arm-eabi/bin"
  end
end
