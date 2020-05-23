require "formula"

class ArmNoneEabiBinutils < Formula
  desc "GNU Binutils for OS-less ARM 32-bit architecture"
  homepage "https://www.gnu.org/software/binutils/"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.34.tar.xz"
  sha256 "f00b0e8803dc9bab1e2165bd568528135be734df3fabf8d0161828cd56028952"

  depends_on "gmp"
  depends_on "mpfr"

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-none-eabi",
                "--disable-shared", "--disable-nls",
                "--with-gmp=#{Formulary.factory("gmp").prefix}",
                "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
