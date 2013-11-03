require 'formula'

class ArmEabiGdb76 <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-7.6.1.tar.bz2'
  homepage 'http://www.gnu.org/software/gdb/'
  sha1 '0e38633b3902070d9c6755e4c54602148a094361'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'libmpc'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-eabi",
                "--with-gmp=#{Formula.factory('gmp').prefix}",
                "--with-mpfr=#{Formula.factory('mpfr').prefix}",
                "--with-mpc=#{Formula.factory('libmpc').prefix}",
                "--without-cloog",
                "--enable-lto","--disable-werror"
    system "make"
    system "make install"
  end
end
