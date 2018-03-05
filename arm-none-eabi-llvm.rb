class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://releases.llvm.org/5.0.1/llvm-5.0.1.src.tar.xz"
    sha256 "5fa7489fc0225b11821cab0362f5813a05f2bcf2533e8a4ea9c9c860168807b0"

    patch "armv7em_arch_fix" do
      url "https://gist.githubusercontent.com/eblot/84e6ce98ee9e81a580ef9bbcd5ab0c6e/raw/2f85e4266ff29fa4e2313ab4f5acf71134901a6f/armv7em_arch_fix.diff"
      sha256 "113c2ec243960ff111d5962a5d61371ccd4411a0a1e53759f97d2ca594906dff"
    end

    resource "clang" do
      url "https://releases.llvm.org/5.0.1/cfe-5.0.1.src.tar.xz"
      sha256 "135f6c9b0cd2da1aff2250e065946258eb699777888df39ca5a5b4fe5e23d0ff"
    end

    resource "clang-extra-tools" do
      url "https://releases.llvm.org/5.0.1/clang-tools-extra-5.0.1.src.tar.xz"
      sha256 "9aada1f9d673226846c3399d13fab6bba4bfd38bcfe8def5ee7b0ec24f8cd225"
    end

    resource "lld" do
      url "https://releases.llvm.org/5.0.1/lld-5.0.1.src.tar.xz"
      sha256 "d5b36c0005824f07ab093616bdff247f3da817cae2c51371e1d1473af717d895"

      patch do
        url "https://gist.githubusercontent.com/eblot/1dee142c537f2e5ee22b615ee896ca67/raw/271b5dcf4966be206095cb6628626db5cfbf47bb/lld.diff"
        sha256 "1f37482a0991fb79c6e07702aae7e82c0b0b1a9f4d4a36cf6f96ed2213c7a9b3"
      end
    end

  end

  head do
    url "http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_600/final", :using => :svn

    resource "clang" do
      url "http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_600/final", :using => :svn
    end

    resource "clang-extra-tools" do
      url "http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_600/final", :using => :svn
    end

    resource "lld" do
      url "http://llvm.org/svn/llvm-project/lld/tags/RELEASE_600/final", :using => :svn

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

    if build.head?
    else
      resource("armv7em_arch_fix").stage do
         system "patch", "-p0", "-i", Pathname.pwd/"armv7em_arch_fix.diff", "-d", buildpath/""
      end
      resource("armv_lld_fix").stage do
        system "patch", "-p0", "-i", Pathname.pwd/"lld.diff", "-d", buildpath/"tools/lld"
      end
    end

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
