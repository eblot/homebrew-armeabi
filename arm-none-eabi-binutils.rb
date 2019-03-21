require 'formula'

class ArmNoneEabiBinutils <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.xz'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '0ab6c55dd86a92ed561972ba15b9b70a8b9f75557f896446c82e8b36e473ee04'

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
