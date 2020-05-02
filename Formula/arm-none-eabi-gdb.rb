require 'formula'

class ArmNoneEabiGdb <Formula
  url 'http://ftp.gnu.org/gnu/gdb/gdb-8.2.1.tar.xz'
  homepage 'http://www.gnu.org/software/gdb/'
  sha256 '0a6a432907a03c5c8eaad3c3cffd50c00a40c3a5e3c4039440624bae703f2202'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'libmpc'
  depends_on 'readline'

  # Linux dependencies.
  depends_on 'python@2' unless OS.mac?
  depends_on 'guile' unless OS.mac?

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-none-eabi",
                "--with-gmp=#{Formulary.factory('gmp').prefix}",
                "--with-mpfr=#{Formulary.factory('mpfr').prefix}",
                "--with-mpc=#{Formulary.factory('libmpc').prefix}",
                "--with-readline=#{Formulary.factory('readline').prefix}",
                "--with-python",
                "--without-cloog",
                "--enable-lto","--disable-werror"
    system "make"
    system "make install"
  end
end
