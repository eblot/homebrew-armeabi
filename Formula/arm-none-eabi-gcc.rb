require "formula"

class ArmNoneEabiGcc < Formula
  desc "GNU C/C++ compiler for OS-less ARM 32-bit architecture"
  homepage "https://gcc.gnu.org"
  url 'http://ftpmirror.gnu.org/gcc/gcc-10.3.0/gcc-10.3.0.tar.xz'
  sha256 '64f404c1a650f27fc33da242e1f2df54952e3963a49e06e73f6940f3223ac344'

  depends_on "arm-none-eabi-binutils"
  depends_on "gmp"
  depends_on "isl"
  depends_on "libelf"
  depends_on "libmpc"
  depends_on "mpfr"

  resource "newlib" do
    url "ftp://sourceware.org/pub/newlib/newlib-4.1.0.tar.gz"
    sha256 "f296e372f51324224d387cc116dc37a6bd397198756746f93a2b02e9a5d40154"
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
