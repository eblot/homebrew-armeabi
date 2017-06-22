require 'formula'

class ArmNoneEabiGdb <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-8.0.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha256 'f6a24ffe4917e67014ef9273eb8b547cb96a13e5ca74895b06d683b391f3f4ee'

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
