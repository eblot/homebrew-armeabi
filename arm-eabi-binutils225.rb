require 'formula'

class ArmEabiBinutils225 <Formula
  url 'http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.bz2'
  homepage 'http://www.gnu.org/software/binutils/'
  sha256 '22defc65cfa3ef2a3395faaea75d6331c6e62ea5dfacfed3e2ec17b08c882923'

  keg_only 'Enable installation of several binutils versions'

  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'ppl11'
  depends_on 'cloog'

  def patches
    DATA
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--target=arm-eabi",
                "--disable-shared", "--disable-nls", "--enable-lto",
                "--with-gmp=#{Formula.factory('gmp').prefix}",
                "--with-mpfr=#{Formula.factory('mpfr').prefix}",
                "--with-ppl=#{Formula.factory('ppl11').prefix}",
                "--with-cloog=#{Formula.factory('cloog').prefix}",
                "--enable-cloog-backend=isl",
                "--disable-cloog-version-check",
                "--enable-multilibs", "--enable-interwork", "--enable-lto",
                "--disable-werror", "--disable-debug"
    system "make"
    system "make install"
  end
end

__END__
--- a/gprof/gmon_out.h	2013-11-04 16:33:39.000000000 +0100
+++ b/gprof/gmon_out.h	2015-08-05 15:10:53.000000000 +0200
@@ -26,7 +26,7 @@
 #define gmon_out_h
 
 #define	GMON_MAGIC	"gmon"	/* magic cookie */
-#define GMON_VERSION	1	/* version number */
+#define GMON_VERSION	1024	/* version number */
 
 /* Raw header as it appears on file (without padding).  */
 struct gmon_hdr
--- a/gprof/gprof.c	2013-11-04 16:33:39.000000000 +0100
+++ b/gprof/gprof.c	2015-08-05 15:10:53.000000000 +0200
@@ -157,6 +157,7 @@
 usage (FILE *stream, int status)
 {
   fprintf (stream, _("\
+Special gprof version for Neotion targets with 32-bit hit counters\n\n\
 Usage: %s [-[abcDhilLsTvwxyz]] [-[ACeEfFJnNOpPqSQZ][name]] [-I dirs]\n\
 	[-d[num]] [-k from/to] [-m min-count] [-t table-length]\n\
 	[--[no-]annotated-source[=name]] [--[no-]exec-counts[=name]]\n\
--- a/gprof/gprof.h	2013-11-04 16:33:39.000000000 +0100
+++ b/gprof/gprof.h	2015-08-05 15:10:53.000000000 +0200
@@ -104,7 +104,7 @@
   }
 File_Format;
 
-typedef unsigned char UNIT[2];	/* unit of profiling */
+typedef unsigned char UNIT[4];	/* unit of profiling */
 
 extern const char *whoami;	/* command-name, for error messages */
 extern const char *function_mapping_file; /* file mapping functions to files */
--- a/gprof/hist.c	2013-11-04 16:33:39.000000000 +0100
+++ b/gprof/hist.c	2015-08-05 15:10:53.000000000 +0200
@@ -231,7 +231,7 @@
 		   whoami, filename, i, record->num_bins);
 	  done (1);
 	}
-      record->sample[i] += bfd_get_16 (core_bfd, (bfd_byte *) & count[0]);
+      record->sample[i] += bfd_get_32 (core_bfd, (bfd_byte *) & count[0]);
       DBG (SAMPLEDEBUG,
 	   printf ("[hist_read_rec] 0x%lx: %u\n",
 		   (unsigned long) (record->lowpc 
