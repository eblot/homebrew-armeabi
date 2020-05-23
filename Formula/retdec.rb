require "formula"

class Retdec < Formula
  desc "Retargetable machine-code decompiler based on LLVM"
  homepage "https://retdec.com/"
  url "https://github.com/avast-tl/retdec/archive/v3.2.tar.gz"
  sha256 "d1ec301a1024887431abb0fbac9478fb2cd66cbf48706174fc6a423aab4c3d60"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "flex" => :build
  depends_on "bison" => :build
  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "libtool" => :build
  depends_on "python"
  depends_on "perl"
  depends_on "git"

  def install
    mktemp do
      system "cmake", buildpath, *std_cmake_args
      system "cmake", "--build", ".", "--target", "install"
    end
  end

end
