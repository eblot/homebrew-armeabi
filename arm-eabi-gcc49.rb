require 'formula'

class ArmEabiGcc49 <Formula
  url       'http://ftpmirror.gnu.org/gcc/gcc-4.9.1/gcc-4.9.1.tar.bz2'
  homepage  'http://gcc.gnu.org/'
  sha1      '3f303f403053f0ce79530dae832811ecef91197e'

  keg_only 'Enable installation of several GCC versions'

  depends_on 'gmp'
  depends_on 'libmpc'
  depends_on 'mpfr'
  depends_on 'cloog'
  depends_on 'isl'
  depends_on 'arm-eabi-binutils224'
  depends_on 'gcc49' => :build

  resource "newlib21" do
    url       'ftp://sourceware.org/pub/newlib/newlib-2.1.0.tar.gz'
    sha1      '364d569771866bf55cdbd1f8c4a6fa5c9cf2ef6c'
  end


  def install

    armeabi = 'arm-eabi-binutils224'

    coredir = Dir.pwd

    resource("newlib21").stage do
      system "ditto", Dir.pwd+'/libgloss', coredir+'/libgloss'
      system "ditto", Dir.pwd+'/newlib', coredir+'/newlib'
    end

    gmp = Formula.factory 'gmp'
    mpfr = Formula.factory 'mpfr'
    libmpc = Formula.factory 'libmpc'
    cloog = Formula.factory 'cloog'
    isl = Formula.factory 'isl'
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
                  "--with-cloog=#{cloog.opt_prefix}",
                  "--enable-cloog-backend=isl",
                  "--with-isl=#{isl.opt_prefix}",
                  "--with-libelf=#{libelf.opt_prefix}",
                  "--with-gxx-include-dir=#{prefix}/arm-eabi/include",
                  "--disable-debug", "--disable-__cxa_atexit",
                  "--with-pkgversion=SDK2-Quennar"
      # Temp. workaround until GCC installation script is fixed
      system "mkdir -p #{prefix}/arm-eabi/lib/fpu/interwork"
      system "make"
      system "make -j1 -k install"
    end

    ln_s "#{Formula.factory(armeabi).prefix}/arm-eabi/bin",
                   "#{prefix}/arm-eabi/bin"
  end
end
