class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "http://releases.llvm.org/7.0.1/llvm-7.0.1.src.tar.xz"
    sha256 "a38dfc4db47102ec79dcc2aa61e93722c5f6f06f0a961073bd84b78fb949419b"

    resource "clang" do
      url "https://releases.llvm.org/7.0.1/cfe-7.0.1.src.tar.xz"
      sha256 "a45b62dde5d7d5fdcdfa876b0af92f164d434b06e9e89b5d0b1cbc65dfe3f418"
    end

    resource "clang-extra-tools" do
      url "https://releases.llvm.org/7.0.1/clang-tools-extra-7.0.1.src.tar.xz"
      sha256 "4c93c7d2bb07923a8b272da3ef7914438080aeb693725f4fc5c19cd0e2613bed"
    end

    resource "lld" do
      url "https://releases.llvm.org/7.0.1/lld-7.0.1.src.tar.xz"
      sha256 "8869aab2dd2d8e00d69943352d3166d159d7eae2615f66a684f4a0999fc74031"

      patch do
        url "https://gist.githubusercontent.com/eblot/43552f8c01cc7d2ee4faef42454c2c83/raw/157c5fee1d9e2ea4c87af78511ce81702a473e80/lld_armv6m_thunk_support.diff"
        sha256 "74ede4c6d02d12dce51c147a2d3a8e7113915df556e112828406ba9c927385ed"
      end
    end

  end

  head do
    url "http://llvm.org/svn/llvm-project/llvm/trunk", :using => :svn

    resource "clang" do
      url "http://llvm.org/svn/llvm-project/cfe/trunk", :using => :svn
    end

    resource "clang-extra-tools" do
      url "http://llvm.org/svn/llvm-project/clang-tools-extra/trunk", :using => :svn
    end

    resource "lld" do
      url "http://llvm.org/svn/llvm-project/lld/trunk", :using => :svn

      patch do
        url "https://reviews.llvm.org/file/data/rivp5hm6gvgvm6lvpdft/PHID-FILE-c65sxsav2henidhqxxsq/D55555.diff"
        sha256 "609dbc5d453bada38c410833a3e43b77c5608d2208d46969a4417e47f0612660"
      end
    end
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

    args = %w[
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_SPHINX=False
      -DLLVM_INCLUDE_TESTS=False
      -DLLVM_TARGETS_TO_BUILD=ARM
      -DLLVM_INSTALL_UTILS=ON
    ]

    mktemp do
      system "cmake", "-G", "Ninja", buildpath, *(args + std_cmake_args)
      system "ninja"
      system "cmake", "--build", ".", "--target", "install"
    end

  end
end
