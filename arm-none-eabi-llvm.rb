class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "http://releases.llvm.org/8.0.0/llvm-8.0.0.src.tar.xz"
    sha256 "8872be1b12c61450cacc82b3d153eab02be2546ef34fa3580ed14137bb26224c"

    resource "clang" do
      url "https://releases.llvm.org/8.0.0/cfe-8.0.0.src.tar.xz"
      sha256 "084c115aab0084e63b23eee8c233abb6739c399e29966eaeccfc6e088e0b736b"
    end

    resource "clang-extra-tools" do
      url "https://releases.llvm.org/8.0.0/clang-tools-extra-8.0.0.src.tar.xz"
      sha256 "4f00122be408a7482f2004bcf215720d2b88cf8dc78b824abb225da8ad359d4b"
    end

    resource "lld" do
      url "https://releases.llvm.org/8.0.0/lld-8.0.0.src.tar.xz"
      sha256 "9caec8ec922e32ffa130f0fb08e4c5a242d7e68ce757631e425e9eba2e1a6e37"
    end

  end

  head do
    url "https://github.com/llvm/llvm-project", :using => :git, :branch => "release/9.x"
  end

  # beware that forcing link may seriously break your installation, as
  # some header files may be symlinked in /usr/local/include and /usr/local/lib
  # which can in turn be included/loaded by the system toolchain...
  keg_only "conflict with system llvm"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install

    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"tools/clang/tools/extra").install resource("clang-extra-tools")
    (buildpath/"tools/lld").install resource("lld")

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_SPHINX=False
      -DLLVM_INCLUDE_TESTS=False
      -DLLVM_TARGETS_TO_BUILD=ARM
      -DLLVM_INSTALL_UTILS=ON
    ]

    mkdir "build" do
      system "cmake", "-G", "Ninja", "..", *(std_cmake_args + args)
      system "ninja"
      system "cmake", "--build", ".", "--target", "install"
    end

  end
end
