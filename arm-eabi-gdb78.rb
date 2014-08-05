require 'formula'

class ArmEabiGdb78 <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-7.8.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha1 'fc43f1f2e651df1c69e7707130fd6864c2d7a428'

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
