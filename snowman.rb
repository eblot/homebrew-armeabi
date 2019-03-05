class Snowman < Formula
  desc "Native code to C/C++ decompiler, supporting x86, AMD64, and ARM architectures."
  homepage "http://derevenets.com/"
  url "https://github.com/yegord/snowman/archive/v0.1.3.tar.gz"
  sha256 "4516b5fa6afd1298902eb09869d61e5617ee62441c36a87106e93abfe1431544"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "boost" => :build
  depends_on "qt5"

  def install
    mktemp do
      system "cmake", "-G", "Ninja", "-D", "NC_QT5=YES",
             buildpath/"src", *std_cmake_args
      system "cmake", "--build", ".", "--target", "install"
    end
  end

end
