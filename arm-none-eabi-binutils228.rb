require 'formula'

class ArmNoneEabiBinutils228 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.28.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '6297433ee120b11b4b0a1c8f3512d7d73501753142ab9e2daa13c5a3edd32a72'

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
