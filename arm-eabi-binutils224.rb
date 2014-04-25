require 'formula'

class ArmEabiBinutils224 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha1 '7ac75404ddb3c4910c7594b51ddfc76d4693debb'

  keg_only 'Enable installation of several binutils versions'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'ppl11'
  depends_on 'cloog'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-eabi",
                "--disable-shared", "--disable-nls",
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
