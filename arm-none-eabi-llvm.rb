class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://github.com/llvm/llvm-project/archive/llvmorg-9.0.0.tar.gz"
    sha256 "7807fac25330e24e9955ca46cd855dd34bbc9cc4fdba8322366206654d1036f2"

    patch do
      # D65722: Expand regions for gaps due to explicit address
      # short .got sections may trigger an overlapping issue w/o it
      url "https://github.com/llvm/llvm-project/commit/179dc276ebc1e592fb831bb4716e1b70c7f13cd4.diff"
      sha256 "68fedca404e1208c9d740d0f729403f455fbf4e5994f2880404b5d11da826041"
    end
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
  depends_on "swig" => :build
  depends_on "python"
  depends_on "ncurses"
  depends_on "libedit"

  def install

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb
      -DLLVM_ENABLE_SPHINX=False
      -DLLVM_INCLUDE_TESTS=False
      -DLLVM_TARGET_ARCH=ARM
      -DLLVM_TARGETS_TO_BUILD=ARM
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_DEFAULT_TARGET_TRIPLE=arm-none-eabi
      -DCMAKE_CROSSCOMPILING=ON
    ]

    mkdir "build" do
      system "cmake", "-G", "Ninja", "../llvm", *(std_cmake_args + args)
      system "ninja"
      system "ninja", "install"
      # add man files that do not get automatically installed
      system "mkdir -p #{prefix}/share/man/man1 #{prefix}/share/man/man7"
      system "cp ../lld/docs/ld.lld.1 ../lldb/docs/lldb.1 ../llvm/docs/llvm-objdump.1 #{prefix}/share/man/man1/"
      system "cp ../llvm/docs/re_format.7 #{prefix}/share/man/man7/"
    end

  end
end
