require 'formula'

class Ppl11 < Formula
  homepage 'http://bugseng.com/products/ppl/'
  url 'http://bugseng.com/products/ppl/download/ftp/releases/1.1/ppl-1.1.tar.gz'
  sha1 'd24c79f7299320e6a344711aaec74bd2d5015b15'

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
