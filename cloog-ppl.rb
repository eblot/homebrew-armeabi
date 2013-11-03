require 'formula'

class CloogPpl <Formula
  url 'http://www.bastoul.net/cloog/pages/download/cloog-0.18.1.tar.gz'
  homepage 'http://www.bastoul.net/cloog/'
  sha1 '2dc70313e8e2c6610b856d627bce9c9c3f848077'

  depends_on 'gmp'
  depends_on 'ppl11'
  depends_on 'libtool' => :build

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--with-gmp=#{Formula.factory('gmp').prefix}",
                          "--with-ppl=#{Formula.factory('ppl11').prefix}"
    system "make"
    system "make install"
  end
end
