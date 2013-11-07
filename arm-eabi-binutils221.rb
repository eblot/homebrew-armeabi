require 'formula'

class ArmEabiBinutils221 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.21.1a.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha1 '525255ca6874b872540c9967a1d26acfbc7c8230'

  keg_only 'Enable installation of several binutils versions'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'ppl11'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-eabi",
                "--disable-shared", "--disable-nls",
                "--with-gmp=#{Formula.factory('gmp').prefix}",
                "--with-mpfr=#{Formula.factory('mpfr').prefix}",
                "--with-ppl=#{Formula.factory('ppl11').prefix}",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
