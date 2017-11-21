require 'formula'

class ArmNoneEabiBinutils229 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.29.1.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '1509dff41369fb70aed23682351b663b56db894034773e6dbf7d5d6071fc55cc'

  depends_on 'gmp'
  depends_on 'mpfr'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-none-eabi",
                "--disable-shared", "--disable-nls",
                "--with-gmp=#{Formulary.factory('gmp').prefix}",
                "--with-mpfr=#{Formulary.factory('mpfr').prefix}",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
