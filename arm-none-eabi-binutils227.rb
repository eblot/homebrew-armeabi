require 'formula'

class ArmNoneEabiBinutils227 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.27.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '369737ce51587f92466041a97ab7d2358c6d9e1b6490b3940eb09fb0a9a6ac88'

  keg_only 'Enable installation of several binutils versions'

  depends_on 'gmp'
  depends_on 'mpfr'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-none-eabi",
                "--disable-shared", "--disable-nls", "--enable-lto",
                "--with-gmp=#{Formulary.factory('gmp').prefix}",
                "--with-mpfr=#{Formulary.factory('mpfr').prefix}",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
