class Armv7emCortexM4fLibcpp < Formula
  desc "LibC++ for baremetal Cortex-M4F targets.

       This is a highly experimental formula, with several C++ features
       disabled for now, such as thread support. You've been warned.
  "
  homepage "https://llvm.org/"

  stable do
    url "https://releases.llvm.org/6.0.0/libcxx-6.0.0.src.tar.xz"
    sha256 "70931a87bde9d358af6cb7869e7535ec6b015f7e6df64def6d2ecdd954040dd9"
    version "6.0.0"

    patch :p0, <<~EOS
      --- CMakeLists.txt  (revision 331442)
      +++ CMakeLists.txt  (working copy)
      @@ -12,6 +12,12 @@
         cmake_policy(SET CMP0022 NEW) # Required when interacting with LLVM and Clang
       endif()
      
      +FOREACH (arg ${EXTRA_CX_FLAGS})
      +  SET (COMPILE_FLAGS "${COMPILE_FLAGS} ${arg}")
      +ENDFOREACH ()
      +SET (CMAKE_C_FLAGS "${COMPILE_FLAGS}")
      +SET (CMAKE_CXX_FLAGS "${COMPILE_FLAGS}")
      +
       # Add path for custom modules
       set(CMAKE_MODULE_PATH
         "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
    EOS

    resource 'libcxxabi' do
      url "https://releases.llvm.org/6.0.0/libcxxabi-6.0.0.src.tar.xz"
      sha256 "91c6d9c5426306ce28d0627d6a4448e7d164d6a3f64b01cb1d196003b16d641b"

      patch :p0, <<~EOS
        --- CMakeLists.txt  (revision 331441)
        +++ CMakeLists.txt  (working copy)
        @@ -10,6 +10,12 @@
           cmake_policy(SET CMP0042 NEW) # Set MACOSX_RPATH=YES by default
         endif()
        
        +FOREACH (arg ${EXTRA_CX_FLAGS})
        +  SET (COMPILE_FLAGS "${COMPILE_FLAGS} ${arg}")
        +ENDFOREACH ()
        +SET (CMAKE_C_FLAGS "${COMPILE_FLAGS}")
        +SET (CMAKE_CXX_FLAGS "${COMPILE_FLAGS}")
        +
         # Add path for custom modules
         set(CMAKE_MODULE_PATH
           "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
      EOS
    end

    resource "libunwind" do
      url "https://releases.llvm.org/6.0.0/libunwind-6.0.0.src.tar.xz"
      sha256 "256c4ed971191bde42208386c8d39e5143fa4afd098e03bd2c140c878c63f1d6"

      patch :p0, <<~EOS
        --- CMakeLists.txt  (revision 331442)
        +++ CMakeLists.txt  (working copy)
        @@ -8,6 +8,12 @@
           cmake_policy(SET CMP0042 NEW) # Set MACOSX_RPATH=YES by default
         endif()
        
        +FOREACH (arg ${EXTRA_CX_FLAGS})
        +  SET (COMPILE_FLAGS "${COMPILE_FLAGS} ${arg}")
        +ENDFOREACH ()
        +SET (CMAKE_C_FLAGS "${COMPILE_FLAGS}")
        +SET (CMAKE_CXX_FLAGS "${COMPILE_FLAGS}")
        +
         # Add path for custom modules
         set(CMAKE_MODULE_PATH
           "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
      EOS
    end
  end

  depends_on "arm-none-eabi-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "armv7em-cortex-m4f"

  def install
    llvm = Formulary.factory "arm-none-eabi-llvm"
    clib = Formulary.factory "armv7em-cortex-m4f"

    sysroot = "#{clib.opt_prefix}/armv7em-none-eabi/cortex-m4f"

    (buildpath/"libunwind").install resource("libunwind")
    (buildpath/"libcxxabi").install resource("libcxxabi")

    ENV.append_path "PATH", "#{llvm.opt_prefix}/bin"

    cx_flags=["-O3",
               "-g",
               "--target=armv7em-none-eabi",
               "-mcpu=cortex-m4",
               "-mfloat-abi=hard",
               "-mfpu=fpv4-sp-d16",
               "-mthumb",
               "-mabi=aapcs",
               "-D_LIBUNWIND_IS_BAREMETAL=1",
               "-D_GNU_SOURCE=1",
               "-D_POSIX_TIMERS=1",
               "-I#{buildpath}/libunwind/include",
               "-I#{buildpath}/libcxxabi/include",
               "-I#{buildpath}/include"]

    # CMake is a mess; passing arguments (such a CXXFLAGS) that contain spaces
    # ends up with a heavily truncated argument line. As a workaround, create
    # a CMake lists with semi-column separator, and used the applied patch
    # to CMakeLists.txt to restore a proper flag list.
    cxx_flags = cx_flags.clone
    libcxx_flags = cxx_flags.join(";")
    unwind_flags = cx_flags.clone
    unwind_flags += ["-D_LIBCPP_HAS_NO_THREADS"]
    libunwind_flags = unwind_flags.join(";")
    libcxxabi_flags = libunwind_flags

    # build libunwind
    mktemp do
      system "cmake",
               "-G", "Ninja", "-Wno-dev",
               "-DCMAKE_SYSTEM_PROCESSOR=arm",
               "-DCMAKE_SYSTEM_NAME=Generic",
               "-DCMAKE_CROSSCOMPILING=ON",
               "-DUNIX=1",
               "-DCMAKE_CXX_COMPILER_FORCED=TRUE",
               "-DCMAKE_INSTALL_PREFIX=#{prefix}",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_C_COMPILER=#{llvm.opt_prefix}/bin/clang",
               "-DCMAKE_CXX_COMPILER=#{llvm.opt_prefix}/bin/clang++",
               "-DCMAKE_LINKER=#{llvm.opt_prefix}/bin/clang",
               "-DCMAKE_AR=#{llvm.opt_prefix}/bin/llvm-ar",
               "-DCMAKE_RANLIB=#{llvm.opt_prefix}/bin/llvm-ranlib",
               "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
               "-DCMAKE_SYSROOT=#{sysroot}",
               "-DCMAKE_SYSROOT_LINK=#{sysroot}",
               "-DCMAKE_EXE_LINKER_FLAGS=-L#{sysroot}/lib",
               "-DCXX_SUPPORTS_CXX11=TRUE",
               "-DLIBUNWIND_ENABLE_ASSERTIONS=1",
               "-DLIBUNWIND_ENABLE_PEDANTIC=1",
               "-DLIBUNWIND_ENABLE_SHARED=OFF",
               "-DLIBUNWIND_ENABLE_THREADS=OFF",
               "-DLLVM_ENABLE_LIBCXX=TRUE",
               "-DEXTRA_CX_FLAGS=#{libunwind_flags}",
               "#{buildpath}/libunwind"
      system "ninja"
      system "cmake", "--build", ".", "--target", "install"
    end

    # build libcxxabi
    mktemp do
      system "cmake",
               "-G", "Ninja", "-Wno-dev",
               "-DCMAKE_SYSTEM_PROCESSOR=arm",
               "-DCMAKE_SYSTEM_NAME=Generic",
               "-DCMAKE_CROSSCOMPILING=ON",
               "-DUNIX=1",
               "-DCMAKE_CXX_COMPILER_FORCED=TRUE",
               "-DCMAKE_INSTALL_PREFIX=#{prefix}",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_C_COMPILER=#{llvm.opt_prefix}/bin/clang",
               "-DCMAKE_CXX_COMPILER=#{llvm.opt_prefix}/bin/clang++",
               "-DCMAKE_LINKER=#{llvm.opt_prefix}/bin/clang",
               "-DCMAKE_AR=#{llvm.opt_prefix}/bin/llvm-ar",
               "-DCMAKE_RANLIB=#{llvm.opt_prefix}/bin/llvm-ranlib",
               "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
               "-DCMAKE_SYSROOT=#{sysroot}",
               "-DCMAKE_SYSROOT_LINK=#{sysroot}",
               "-DCMAKE_EXE_LINKER_FLAGS=-L#{sysroot}/lib",
               "-DCXX_SUPPORTS_CXX11=TRUE",
               "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
               "-DLIBCXXABI_USE_COMPILER_RT=ON",
               "-DLIBCXXABI_ENABLE_THREADS=OFF",
               "-DLIBCXXABI_ENABLE_SHARED=OFF",
               "-DLIBCXXABI_BAREMETAL=ON",
               "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
               "-DLIBCXXABI_INCLUDE_TESTS=OFF",
               "-DLIBCXXABI_LIBUNWIND_INCLUDES=${LIBUNWIND_SRC}/include",
               "-DLIBCXXABI_LIBCXX_INCLUDES=${LIBCXX_SRC}/include",
               "-DLLVM_ENABLE_LIBCXX=TRUE",
               "-DEXTRA_CX_FLAGS=#{libcxxabi_flags}",
               "#{buildpath}/libcxxabi"
      system "ninja"
      system "cmake", "--build", ".", "--target", "install"
    end

    # build libcxx
    mktemp do
      system "cmake",
               "-G", "Ninja", "-Wno-dev",
               "-DCMAKE_SYSTEM_PROCESSOR=arm",
               "-DCMAKE_SYSTEM_NAME=Generic",
               "-DCMAKE_CROSSCOMPILING=ON",
               "-DUNIX=1",
               "-DCMAKE_CXX_COMPILER_FORCED=TRUE",
               "-DCMAKE_INSTALL_PREFIX=#{prefix}",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DCMAKE_C_COMPILER=#{llvm.opt_prefix}/bin/clang",
               "-DCMAKE_CXX_COMPILER=#{llvm.opt_prefix}/bin/clang++",
               "-DCMAKE_LINKER=#{llvm.opt_prefix}/bin/clang",
               "-DCMAKE_AR=#{llvm.opt_prefix}/bin/llvm-ar",
               "-DCMAKE_RANLIB=#{llvm.opt_prefix}/bin/llvm-ranlib",
               "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS",
               "-DCMAKE_SYSROOT=#{sysroot}",
               "-DCMAKE_SYSROOT_LINK=#{sysroot}",
               "-DCMAKE_EXE_LINKER_FLAGS=-L#{sysroot}/lib",
               "-DCXX_SUPPORTS_CXX11=TRUE",
               "-DLIBCXX_ENABLE_SHARED=OFF",
               "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF",
               "-DLIBCXX_ENABLE_FILESYSTEM=OFF",
               "-DLIBCXX_INCLUDE_TESTS=OFF",
               "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
               "-DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF",
               "-DLIBCXX_USE_COMPILER_RT=ON",
               "-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF",
               "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
               "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
               "-DLIBCXX_ENABLE_THREADS=OFF",
               "-DLIBCXX_CXX_ABI=libcxxabi",
               "-DEXTRA_CX_FLAGS=#{libcxx_flags}",
               "#{buildpath}"
      system "ninja"
      system "cmake", "--build", ".", "--target", "install"
    end

  end

end
