require 'formula'

class Armv6mNoneEabiGdb <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-7.12.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha256 '834ff3c5948b30718343ea57b11cbc3235d7995c6a4f3a5cecec8c8114164f94'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'libmpc'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=armv6m-none-eabi",
                "--with-gmp=#{Formulary.factory('gmp').prefix}",
                "--with-mpfr=#{Formulary.factory('mpfr').prefix}",
                "--with-mpc=#{Formulary.factory('libmpc').prefix}",
                "--without-cloog",
                "--enable-lto","--disable-werror"
    system "make"
    system "make install"
  end
end
