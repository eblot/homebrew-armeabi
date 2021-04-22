require "formula"

class ArmNoneEabiGdb < Formula
  desc "GNU debugger for ARM 32-bit architecture"
  homepage "https://www.gnu.org/software/gdb/"
  url "http://ftp.gnu.org/gnu/gdb/gdb-10.1.tar.xz"
  sha256 "f82f1eceeec14a3afa2de8d9b0d3c91d5a3820e23e0a01bbb70ef9f0276b62c0"

  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "readline"
  depends_on "expat"
  depends_on "python3"
  depends_on "arm-none-eabi-binutils"

  # Linux dependencies.
  depends_on "guile" unless OS.mac?

  # need to regenerate configure script after applying patch
  if OS.mac?
    depends_on "autoconf" => :build
    depends_on "automake" => :build

    patch :DATA if OS.mac?
  end

  def install
    if OS.mac?
      # as dirty as it sounds, I'm tired of autotools...
      autoconf = Formulary.factory "autoconf"
      inreplace "config/override.m4", "[2.69]", "[#{autoconf.version}]"
      system "autoreconf gdb 2>/dev/null"
    end
    mkdir "build" do
      system "../configure", "--prefix=#{prefix}",
                "--target=arm-none-eabi",
                "--with-gmp=#{Formulary.factory("gmp").prefix}",
                "--with-mpfr=#{Formulary.factory("mpfr").prefix}",
                "--with-mpc=#{Formulary.factory("libmpc").prefix}",
                "--with-readline=#{Formulary.factory("readline").prefix}",
                "--with-python=#{Formulary.factory("python3").bin}/python3",
                "--with-expat=#{Formulary.factory("expat").prefix}",
                "--without-cloog",
                "--enable-lto", "--disable-werror"
      system "make"
      system "make install"
      system "(cd #{prefix}/share/info && \
               for info in *.info; do \
                  mv $info $(echo $info | sed 's/^/arm-none-eabi-/'); done &&
               rm -f arm-none-eabi-bfd.info; true)"
      # remove bfd.info to avoid conflict with the binutils twin.
    end
  end
end

# This patch addresses a configuration issue where GDB does not include
# string.h, which breaks build as strncmp is no longer declared on macOS 11
__END__
--- a/gdb/acinclude.m4  2020-11-26 10:10:52.000000000 +0100
+++ b/gdb/acinclude.m4  2020-11-26 10:12:25.000000000 +0100
@@ -362,6 +362,7 @@
   AC_CACHE_CHECK([$1], [$2],
   [AC_TRY_LINK(
   [#include <stdlib.h>
+  #include <string.h>
   #include "bfd.h"
   #include "$4"
   ],
