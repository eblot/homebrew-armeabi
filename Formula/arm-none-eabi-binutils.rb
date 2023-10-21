require "formula"

class ArmNoneEabiBinutils < Formula
  desc "GNU Binutils for OS-less ARM 32-bit architecture"
  homepage "https://www.gnu.org/software/binutils/"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz"
  sha256 "ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450"

  depends_on "gmp"
  depends_on "mpfr"
  depends_on "texinfo" => :build

  keg_only "conflict with other GNU installations"

  def install
    mkdir "build" do
      system "../configure", "--target=arm-none-eabi",
                  "--prefix=#{prefix}",
                  "--with-gmp=#{Formulary.factory("gmp").prefix}",
                  "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
                  "--disable-cloog-version-check",
                  "--enable-multilibs",
                  "--enable-interwork",
                  "--enable-lto",
                  "--disable-shared",
                  "--disable-nls",
                  "--disable-werror",
                  "--disable-debug"
      system "make"
      system "make install"
      system "rm #{prefix}/lib/bfd-plugins/libdep.a"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/arm-none-eabi-/'); done)"
    end
  end
end
