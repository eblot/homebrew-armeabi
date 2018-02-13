require 'formula'

class ArmNoneEabiGdb <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-8.1.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha256 'af61a0263858e69c5dce51eab26662ff3d2ad9aa68da9583e8143b5426be4b34'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'libmpc'
  depends_on 'readline'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-none-eabi",
                "--with-gmp=#{Formulary.factory('gmp').prefix}",
                "--with-mpfr=#{Formulary.factory('mpfr').prefix}",
                "--with-mpc=#{Formulary.factory('libmpc').prefix}",
                "--with-readline=#{Formulary.factory('readline').prefix}",
                "--without-cloog",
                "--enable-lto","--disable-werror"
    system "make"
    system "make install"
  end
end
