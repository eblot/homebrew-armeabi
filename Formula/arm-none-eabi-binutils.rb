require "formula"

class ArmNoneEabiBinutils < Formula
  desc "GNU Binutils for OS-less ARM 32-bit architecture"
  homepage "https://www.gnu.org/software/binutils/"
  url "https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz"
  sha256 "0f8a4c272d7f17f369ded10a4aca28b8e304828e95526da482b0ccc4dfc9d8e1"

  depends_on "gmp"
  depends_on "mpfr"
  depends_on "texinfo" => :build

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
