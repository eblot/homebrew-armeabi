require "formula"

class ArmNoneEabiGcc < Formula
  desc "GNU C/C++ compiler for OS-less ARM 32-bit architecture"
  homepage "https://gcc.gnu.org"
  url 'http://ftpmirror.gnu.org/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz'
  sha256 'e549cf9cf3594a00e27b6589d4322d70e0720cdd213f39beb4181e06926230ff'

  depends_on "arm-none-eabi-binutils"
  depends_on "gmp"
  depends_on "isl"
  depends_on "libelf"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "texinfo" => :build

  resource "newlib" do
    url "ftp://sourceware.org/pub/newlib/newlib-4.2.0.20211231.tar.gz"
    sha256 "c3a0e8b63bc3bef1aeee4ca3906b53b3b86c8d139867607369cb2915ffc54435"
  end

  def install
    xtarget = "arm-none-eabi"
    xbinutils = xtarget + "-binutils"

    coredir = Dir.pwd

    resource("newlib").stage do
      cp_r Dir.pwd+"/newlib", coredir+"/newlib"
    end

    gmp = Formulary.factory "gmp"
    mpfr = Formulary.factory "mpfr"
    libmpc = Formulary.factory "libmpc"
    libelf = Formulary.factory "libelf"
    isl = Formulary.factory "isl"
    binutils = Formulary.factory xbinutils

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV["CFLAGS_FOR_BUILD"] = "-O2"
    ENV["CFLAGS"] = "-O2"
    ENV["CFLAGS_FOR_TARGET"] = "-O2"
    ENV["CXXFLAGS_FOR_BUILD"] = "-O2"
    ENV["CXXFLAGS"] = "-O2"
    ENV["CXXFLAGS_FOR_TARGET"] = "-O2"

    build_dir="build"
    mkdir build_dir
    Dir.chdir build_dir do
      system coredir+"/configure",
          "--prefix=#{prefix}", "--target=#{xtarget}",
          "--libdir=#{lib}/gcc/#{xtarget}",
          "--disable-shared", "--with-gnu-as", "--with-gnu-ld",
          "--with-newlib", "--enable-softfloat", "--disable-bigendian",
          "--disable-fpu", "--disable-underscore", "--enable-multilibs",
          "--with-float=soft", "--enable-interwork", "--enable-lto",
          "--with-multilib", "--enable-plugins",
          "--with-abi=aapcs", "--enable-languages=c,c++",
          "--with-gmp=#{gmp.opt_prefix}",
          "--with-mpfr=#{mpfr.opt_prefix}",
          "--with-mpc=#{libmpc.opt_prefix}",
          "--with-isl=#{isl.opt_prefix}",
          "--with-libelf=#{libelf.opt_prefix}",
          "--with-gxx-include-dir=#{prefix}/#{xtarget}/c++/include",
          "--enable-checking=release",
          "--disable-debug", "--disable-__cxa_atexit"
      # Temp. workaround until GCC installation script is fixed
      system "mkdir -p #{prefix}/#{xtarget}/lib/fpu/interwork"
      system "make"
      system "make -j1 -k install"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/arm-none-eabi-/'); done)"
    end

    ln_s "#{binutils.prefix}/#{xtarget}/bin",
         "#{prefix}/#{xtarget}/bin"
  end
end
