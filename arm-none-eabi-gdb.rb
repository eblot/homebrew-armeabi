require 'formula'

class ArmNoneEabiGdb <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-8.0.1.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha256 '3dbd5f93e36ba2815ad0efab030dcd0c7b211d7b353a40a53f4c02d7d56295e3'

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
