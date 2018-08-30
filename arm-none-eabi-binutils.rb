require 'formula'

class ArmNoneEabiBinutils <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.31.1.tar.xz'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '5d20086ecf5752cc7d9134246e9588fa201740d540f7eb84d795b1f7a93bca86'

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
