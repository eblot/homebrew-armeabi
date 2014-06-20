require 'formula'

class ArmEabiGcc46 <Formula
  url       'http://ftpmirror.gnu.org/gcc/gcc-4.6.4/gcc-core-4.6.4.tar.bz2'
  homepage  'http://gcc.gnu.org/'
  sha1      '9b2f25ac248d81c97bbe46690dc2c350e51996a5'

  keg_only 'Enable installation of several GCC versions'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'libmpc'
  depends_on 'ppl011'
  depends_on 'cloog-ppl015'
  depends_on 'libelf'
  depends_on 'arm-eabi-binutils221'
  depends_on 'gcc48' => :build

  resource "newlib19" do
    url       'ftp://sources.redhat.com/pub/newlib/newlib-1.19.0.tar.gz'
    sha1      'b2269d30ce7b93b7c714b90ef2f40221c2df0fcd'
  end

  resource "gpp46" do
    url       'http://ftpmirror.gnu.org/gcc/gcc-4.6.4/gcc-g++-4.6.4.tar.bz2'
    sha1      'e9a47df1bc5e39a9ef995484c315f5d47114daeb'
  end

  def patches
    DATA
  end

  def install

    armeabi = 'arm-eabi-binutils221'

    coredir = Dir.pwd

    resource("gpp46").stage do
      system "ditto", Dir.pwd, coredir 
    end

    resource("newlib19").stage do
      system "ditto", Dir.pwd+'/libgloss', coredir+'/libgloss'
      system "ditto", Dir.pwd+'/newlib', coredir+'/newlib'
    end

    gmp = Formula.factory 'gmp'
    mpfr = Formula.factory 'mpfr'
    libmpc = Formula.factory 'libmpc'
    ppl = Formula.factory 'ppl011'
    cloogppl = Formula.factory 'cloog-ppl015'
    libelf = Formula.factory 'libelf'
    binutils = Formula.factory armeabi
    gcc48 = Formula.factory 'gcc48'

    # Fix up CFLAGS for cross compilation (default switches cause build issues)
    ENV['CC'] = "#{gcc48.opt_prefix}/bin/gcc-4.8"
    ENV['CXX'] = "#{gcc48.opt_prefix}/bin/g++-4.8"
    ENV['CFLAGS_FOR_BUILD'] = "-O2"
    ENV['CFLAGS'] = "-O2"
    ENV['CFLAGS_FOR_TARGET'] = "-O2"
    ENV['CXXFLAGS_FOR_BUILD'] = "-O2"
    ENV['CXXFLAGS'] = "-O2"
    ENV['CXXFLAGS_FOR_TARGET'] = "-O2"

    build_dir='build'
    mkdir build_dir
    Dir.chdir build_dir do
      system "../configure", "--prefix=#{prefix}", "--target=arm-eabi",
                  "--enable-shared", "--with-gnu-as", "--with-gnu-ld",
                  "--with-newlib", "--enable-softfloat", "--disable-bigendian",
                  "--disable-fpu", "--disable-underscore", "--enable-multilibs",
                  "--with-float=soft", "--enable-interwork", "--enable-lto",
                  "--enable-plugin", "--with-multilib-list=interwork", 
                  "--with-abi=aapcs", "--enable-languages=c,c++",
                  "--with-gmp=#{gmp.opt_prefix}",
                  "--with-mpfr=#{mpfr.opt_prefix}",
                  "--with-mpc=#{libmpc.opt_prefix}",
                  "--with-ppl=#{ppl.prefix}",
                  "--with-cloog=#{cloogppl.opt_prefix}",
                  "--with-libelf=#{libelf.opt_prefix}",
                  "--with-gxx-include-dir=#{prefix}/arm-eabi/include",
                  "--disable-debug", "--disable-__cxa_atexit",
                  "--with-pkgversion=SDK-Tylyn"
      system "make"
      system "make -j1 -k install"
    end

    ln_s "#{Formula.factory(armeabi).prefix}/arm-eabi/bin",
                   "#{prefix}/arm-eabi/bin"
  end
end

__END__
--- a/gcc/config/arm/t-arm-elf  2011-01-03 21:52:22.000000000 +0100
+++ b/gcc/config/arm/t-arm-elf  2011-07-18 16:03:31.000000000 +0200
@@ -71,8 +71,8 @@
 # MULTILIB_DIRNAMES   += fpu soft
 # MULTILIB_EXCEPTIONS += *mthumb/*mhard-float*
 # 
-# MULTILIB_OPTIONS    += mno-thumb-interwork/mthumb-interwork
-# MULTILIB_DIRNAMES   += normal interwork
+MULTILIB_OPTIONS    += mno-thumb-interwork/mthumb-interwork
+MULTILIB_DIRNAMES   += normal interwork
 # 
 # MULTILIB_OPTIONS    += fno-leading-underscore/fleading-underscore
 # MULTILIB_DIRNAMES   += elf under
--- a/gcc/config/i386/i386.c  2011-06-18 11:07:20.000000000 +0200
+++ b/gcc/config/i386/i386.c  2011-07-18 16:03:31.000000000 +0200
@@ -6145,7 +6145,9 @@
    See the x86-64 PS ABI for details.
 */
 
-static int
+int classify_argument (enum machine_mode, const_tree,
+                       enum x86_64_reg_class [MAX_CLASSES], int);
+int
 classify_argument (enum machine_mode mode, const_tree type,
       enum x86_64_reg_class classes[MAX_CLASSES], int bit_offset)
 {
@@ -6526,7 +6528,8 @@
 
 /* Examine the argument and return set number of register required in each
    class.  Return 0 iff parameter should be passed in memory.  */
-static int
+int examine_argument (enum machine_mode, const_tree, int, int *, int *);
+int
 examine_argument (enum machine_mode mode, const_tree type, int in_return,
      int *int_nregs, int *sse_nregs)
 {
