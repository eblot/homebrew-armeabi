class ArmNoneEabiLlvm < Formula
  desc "Next-gen compiler infrastructure for baremetal ARM Aarch32 targets"
  homepage "https://llvm.org/"

  stable do
    url "https://github.com/llvm/llvm-project/archive/llvmorg-10.0.0.tar.gz"
    sha256 "b81c96d2f8f40dc61b14a167513d87c0d813aae0251e06e11ae8a4384ca15451"

    # D76981: Mark empty NOLOAD output sections SHT_NOBITS instead of SHT_PROGBITS
    # original URL: https://reviews.llvm.org/D76981
    # the orignal patch contains a fix for the test, which does not apply
    # to the v10.0 release; only the fix for LLD is applied
    patch :DATA
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
      -DLLDB_USE_SYSTEM_DEBUGSERVER=ON
    ]

    # Force LLDB_USE_SYSTEM_DEBUGSERVER, otherwise LLDB build fails miserably,
    # trying to link host backend object files while target backend has been
    # built.

    mkdir "build" do
      system "cmake", "-G", "Ninja", "../llvm", *(std_cmake_args + args)
      system "ninja"
      system "ninja", "install"
      # add man files that do not get automatically installed
      system "mkdir -p #{prefix}/share/man/man1 #{prefix}/share/man/man7"
      system "cp ../lld/docs/ld.lld.1 ../llvm/docs/llvm-objdump.1 #{prefix}/share/man/man1/"
      system "cp ../llvm/docs/re_format.7 #{prefix}/share/man/man7/"
    end

  end
end

__END__
diff --git a/lld/ELF/ScriptParser.cpp b/lld/ELF/ScriptParser.cpp
--- a/lld/ELF/ScriptParser.cpp
+++ b/lld/ELF/ScriptParser.cpp
@@ -746,6 +746,7 @@
   expect("(");
   if (consume("NOLOAD")) {
     cmd->noload = true;
+    cmd->type = SHT_NOBITS;
   } else {
     skip(); // This is "COPY", "INFO" or "OVERLAY".
     cmd->nonAlloc = true;
