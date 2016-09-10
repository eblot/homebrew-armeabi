require 'formula'

class Ppl11 < Formula
  homepage 'http://bugseng.com/products/ppl/'
  url 'http://bugseng.com/products/ppl/download/ftp/releases/1.1/ppl-1.1.tar.gz'
  sha256 '46f073c0626234f0b1a479356c0022fe5dc3c9cf10df1a246c9cde81f7cf284d'

  depends_on 'homebrew/dupes/m4' => :build if MacOS.version < :leopard
  depends_on 'gmp'

  def install
    args = [
      "--prefix=#{prefix}",
      "--disable-dependency-tracking",
      "--with-gmp-prefix=#{Formula.factory('gmp').opt_prefix}"
    ]

    system "./configure", *args
    system "make install"
  end
end
