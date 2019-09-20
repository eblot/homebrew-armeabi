class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://github.com/llvm/llvm-project/archive/llvmorg-9.0.0.tar.gz"
    sha256 "7807fac25330e24e9955ca46cd855dd34bbc9cc4fdba8322366206654d1036f2"
  end

  head do
    url "https://github.com/llvm/llvm-project", :using => :git
  end

  # beware that forcing link may seriously break your installation, as
  # some header files may be symlinked in /usr/local/include and /usr/local/lib
  # which can in turn be included/loaded by the system toolchain...
  keg_only "conflict with system llvm"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld
      -DLLVM_ENABLE_SPHINX=False
      -DLLVM_INCLUDE_TESTS=False
      -DLLVM_TARGET_ARCH=ARM
      -DLLVM_TARGETS_TO_BUILD=ARM
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_DEFAULT_TARGET_TRIPLE=arm-none-eabi
      -DCMAKE_CROSSCOMPILING=True
    ]

    mkdir "build" do
      system "cmake", "-G", "Ninja", "../llvm", *(std_cmake_args + args)
      system "ninja"
      system "ninja", "install"
    end

  end
end
