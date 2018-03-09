class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://releases.llvm.org/6.0.0/llvm-6.0.0.src.tar.xz"
    sha256 "1ff53c915b4e761ef400b803f07261ade637b0c269d99569f18040f3dcee4408"

    resource "clang" do
      url "https://releases.llvm.org/6.0.0/cfe-6.0.0.src.tar.xz"
      sha256 "e07d6dd8d9ef196cfc8e8bb131cbd6a2ed0b1caf1715f9d05b0f0eeaddb6df32"
    end

    resource "clang-extra-tools" do
      url "https://releases.llvm.org/6.0.0/clang-tools-extra-6.0.0.src.tar.xz"
      sha256 "053b424a4cd34c9335d8918734dd802a8da612d13a26bbb88fcdf524b2d989d2"
    end

    resource "lld" do
      url "https://releases.llvm.org/6.0.0/lld-6.0.0.src.tar.xz"
      sha256 "6b8c4a833cf30230c0213d78dbac01af21387b298225de90ab56032ca79c0e0b"
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

      # patch :p0 do
      #   url "https://reviews.llvm.org/D43468?download=true"
      #   sha256 "19eb8373fad989bcf63475069adfa2a8fb88ea43576887986b65d8a035c5a9af"
      # end
    end

  end

  keg_only "conflict with system llvm"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install
    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"tools/clang/tools/extra").install resource("clang-extra-tools")
    (buildpath/"tools/lld").install resource("lld")

    # if build.head?
    #   resource("armv_lld_fix").stage do
    #     system "patch", "-p0", "-i", Pathname.pwd/"lld.diff", "-d", buildpath/"tools/lld"
    #   end
    # end

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
