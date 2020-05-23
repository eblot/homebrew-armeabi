require "formula"

class ArmNoneEabiGcc < Formula
  desc "GNU C/C++ compiler for OS-less ARM 32-bit architecture"
  homepage "https://gcc.gnu.org"
  url "https://ftp.gnu.org/gnu/gcc/gcc-9.3.0/gcc-9.3.0.tar.xz"
  sha256 "71e197867611f6054aa1119b13a0c0abac12834765fe2d81f35ac57f84f742d1"

  depends_on "gcc@9" => :build
  depends_on "arm-none-eabi-binutils"
  depends_on "gmp"
  depends_on "isl"
  depends_on "libelf"
  depends_on "libmpc"
  depends_on "mpfr"

  resource "newlib" do
    url "ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz"
    sha256 "58dd9e3eaedf519360d92d84205c3deef0b3fc286685d1c562e245914ef72c66"
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
    gcc9 = Formulary.factory "gcc@9"

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV["CC"] = "#{gcc9.opt_prefix}/bin/gcc-9"
    ENV["CXX"] = "#{gcc9.opt_prefix}/bin/g++-9"
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
          "--with-gxx-include-dir=#{prefix}/#{xtarget}/include",
          "--enable-checking=release",
          "--disable-debug", "--disable-__cxa_atexit"
      # Temp. workaround until GCC installation script is fixed
      system "mkdir -p #{prefix}/#{xtarget}/lib/fpu/interwork"
      system "make"
      system "make -j1 -k install"
    end

    ln_s "#{binutils.prefix}/#{xtarget}/bin",
         "#{prefix}/#{xtarget}/bin"
  end
end
