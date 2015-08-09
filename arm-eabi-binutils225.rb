require 'formula'

class ArmEabiBinutils225 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha1 'b46cc90ebaba7ffcf6c6d996d60738881b14e50d'

  keg_only 'Enable installation of several binutils versions'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'ppl11'
  depends_on 'cloog'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-eabi",
                "--disable-shared", "--disable-nls", "--enable-lto",
                "--with-gmp=#{Formula.factory('gmp').prefix}",
                "--with-mpfr=#{Formula.factory('mpfr').prefix}",
                "--with-ppl=#{Formula.factory('ppl11').prefix}",
                "--with-cloog=#{Formula.factory('cloog').prefix}",
                "--enable-cloog-backend=isl",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
