require 'formula'

class ArmEabiGdb79 <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-7.9.1.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha1 '04ba2906279b16b5f99c4f6b25942843a3717cdb'

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
