class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://releases.llvm.org/7.0.0/llvm-7.0.0.src.tar.xz"
    sha256 "8bc1f844e6cbde1b652c19c1edebc1864456fd9c78b8c1bea038e51b363fe222"

    resource "clang" do
      url "https://releases.llvm.org/7.0.0/cfe-7.0.0.src.tar.xz"
      sha256 "550212711c752697d2f82c648714a7221b1207fd9441543ff4aa9e3be45bba55"
    end

    resource "clang-extra-tools" do
      url "https://releases.llvm.org/7.0.0/clang-tools-extra-7.0.0.src.tar.xz"
      sha256 "937c5a8c8c43bc185e4805144744799e524059cac877a44d9063926cd7a19dbe"
    end

    resource "lld" do
      url "https://releases.llvm.org/7.0.0/lld-7.0.0.src.tar.xz"
      sha256 "fbcf47c5e543f4cdac6bb9bbbc6327ff24217cd7eafc5571549ad6d237287f9c"

      patch do
        url "https://gist.githubusercontent.com/eblot/43552f8c01cc7d2ee4faef42454c2c83/raw/7ccb5c0a86024a3f189acb0f72a58aee57ba8c54/lld_armv6m_thunk_support.diff"
        sha256 "609dbc5d453bada38c410833a3e43b77c5608d2208d46969a4417e47f0612660"
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
        url "https://gist.githubusercontent.com/eblot/43552f8c01cc7d2ee4faef42454c2c83/raw/7ccb5c0a86024a3f189acb0f72a58aee57ba8c54/lld_armv6m_thunk_support.diff"
        sha256 "609dbc5d453bada38c410833a3e43b77c5608d2208d46969a4417e47f0612660"
      end
    end
  end

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
