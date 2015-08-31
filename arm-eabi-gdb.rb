require 'formula'

class ArmEabiGdb <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-7.10.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha256 '7ebdaa44f9786ce0c142da4e36797d2020c55fa091905ac5af1846b5756208a8'

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
