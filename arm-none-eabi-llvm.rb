class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://releases.llvm.org/5.0.0/llvm-5.0.0.src.tar.xz"
    sha256 "e35dcbae6084adcf4abb32514127c5eabd7d63b733852ccdb31e06f1373136da"

    resource "armv7em_arch_fix" do
      url "https://gist.githubusercontent.com/eblot/84e6ce98ee9e81a580ef9bbcd5ab0c6e/raw/2f85e4266ff29fa4e2313ab4f5acf71134901a6f/armv7em_arch_fix.diff"
      sha256 "113c2ec243960ff111d5962a5d61371ccd4411a0a1e53759f97d2ca594906dff"
    end

    resource "clang" do
      url "https://releases.llvm.org/5.0.0/cfe-5.0.0.src.tar.xz"
      sha256 "019f23c2192df793ac746595e94a403908749f8e0c484b403476d2611dd20970"
    end

    resource "clang-extra-tools" do
      url "https://releases.llvm.org/5.0.0/clang-tools-extra-5.0.0.src.tar.xz"
      sha256 "87d078b959c4a6e5ff9fd137c2f477cadb1245f93812512996f73986a6d973c6"
    end

    resource "lld" do
      url "https://releases.llvm.org/5.0.0/lld-5.0.0.src.tar.xz"
      sha256 "399a7920a5278d42c46a7bf7e4191820ec2301457a7d0d4fcc9a4ac05dd53897"
    end

    resource "armv_lld_fix" do
       url "https://gist.githubusercontent.com/eblot/1dee142c537f2e5ee22b615ee896ca67/raw/271b5dcf4966be206095cb6628626db5cfbf47bb/lld.diff"
       sha256 "1f37482a0991fb79c6e07702aae7e82c0b0b1a9f4d4a36cf6f96ed2213c7a9b3"
    end
  end

  keg_only "conflict with system llvm"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install
    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"tools/clang/tools/extra").install resource("clang-extra-tools")
    (buildpath/"tools/lld").install resource("lld")

    resource("armv7em_arch_fix").stage do
      system "patch", "-p0", "-i", Pathname.pwd/"armv7em_arch_fix.diff", "-d", buildpath/""
    end

    resource("armv_lld_fix").stage do
      system "patch", "-p0", "-i", Pathname.pwd/"lld.diff", "-d", buildpath/"tools/lld"
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
