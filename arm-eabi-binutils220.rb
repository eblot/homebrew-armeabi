require 'formula'

class ArmEabiBinutils220 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.20.1a.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '71d37c96451333c5c0b84b170169fdcb138bbb27397dc06281905d9717c8ed64'

  keg_only 'Enable installation of several binutils versions'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'ppl011'

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-eabi",
                "--disable-shared", "--disable-nls",
                "--with-gmp=#{Formula.factory('gmp').prefix}",
                "--with-mpfr=#{Formula.factory('mpfr').prefix}",
                "--with-ppl=#{Formula.factory('ppl011').prefix}",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end
