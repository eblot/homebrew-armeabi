require "formula"

class Cramfs < Formula
  url "https://downloads.sourceforge.net/project/cramfs/cramfs/1.1/cramfs-1.1.tar.gz"
  homepage "https://cramfs.sourceforge.net"
  sha256 "133caca2c4e7c64106555154ee0ff693f5cf5beb9421ce2eb86baee997d22368"

  depends_on "cmake"

  def patches
    DATA
  end

  def install
    mkdir "cramfs-build"
    Dir.chdir "cramfs-build" do
      system "cmake .. #{std_cmake_parameters}"
      system "make"
      system "make install"
    end
  end
end

__END__
--- a/cramfs/src/linux/cramfs_fs.h
+++ b/cramfs/src/linux/cramfs_fs.h
@@ -0,0 +1,98 @@
+#ifndef __CRAMFS_H
+#define __CRAMFS_H
+
+#ifndef __KERNEL__
+
+typedef unsigned char u8;
+typedef unsigned short u16;
+typedef unsigned int u32;
+
+#endif
+
+#define CRAMFS_MAGIC		0x28cd3d45	/* some random number */
+#define CRAMFS_SIGNATURE	"Compressed ROMFS"
+
+/*
+ * Width of various bitfields in struct cramfs_inode.
+ * Primarily used to generate warnings in mkcramfs.
+ */
+#define CRAMFS_MODE_WIDTH 16
+#define CRAMFS_UID_WIDTH 16
+#define CRAMFS_SIZE_WIDTH 24
+#define CRAMFS_GID_WIDTH 8
+#define CRAMFS_NAMELEN_WIDTH 6
+#define CRAMFS_OFFSET_WIDTH 26
+
+/*
+ * Since inode.namelen is a unsigned 6-bit number, the maximum cramfs
+ * path length is 63 << 2 = 252.
+ */
+#define CRAMFS_MAXPATHLEN (((1 << CRAMFS_NAMELEN_WIDTH) - 1) << 2)
+
+/*
+ * Reasonably terse representation of the inode data.
+ */
+struct cramfs_inode {
+	u32 mode:CRAMFS_MODE_WIDTH, uid:CRAMFS_UID_WIDTH;
+	/* SIZE for device files is i_rdev */
+	u32 size:CRAMFS_SIZE_WIDTH, gid:CRAMFS_GID_WIDTH;
+	/* NAMELEN is the length of the file name, divided by 4 and
+           rounded up.  (cramfs doesn't support hard links.) */
+	/* OFFSET: For symlinks and non-empty regular files, this
+	   contains the offset (divided by 4) of the file data in
+	   compressed form (starting with an array of block pointers;
+	   see README).  For non-empty directories it is the offset
+	   (divided by 4) of the inode of the first file in that
+	   directory.  For anything else, offset is zero. */
+	u32 namelen:CRAMFS_NAMELEN_WIDTH, offset:CRAMFS_OFFSET_WIDTH;
+};
+
+struct cramfs_info {
+	u32 crc;
+	u32 edition;
+	u32 blocks;
+	u32 files;
+};
+
+/*
+ * Superblock information at the beginning of the FS.
+ */
+struct cramfs_super {
+	u32 magic;			/* 0x28cd3d45 - random number */
+	u32 size;			/* length in bytes */
+	u32 flags;			/* feature flags */
+	u32 future;			/* reserved for future use */
+	u8 signature[16];		/* "Compressed ROMFS" */
+	struct cramfs_info fsid;	/* unique filesystem info */
+	u8 name[16];			/* user-defined name */
+	struct cramfs_inode root;	/* root inode data */
+};
+
+/*
+ * Feature flags
+ *
+ * 0x00000000 - 0x000000ff: features that work for all past kernels
+ * 0x00000100 - 0xffffffff: features that don't work for past kernels
+ */
+#define CRAMFS_FLAG_FSID_VERSION_2	0x00000001	/* fsid version #2 */
+#define CRAMFS_FLAG_SORTED_DIRS		0x00000002	/* sorted dirs */
+#define CRAMFS_FLAG_HOLES		0x00000100	/* support for holes */
+#define CRAMFS_FLAG_WRONG_SIGNATURE	0x00000200	/* reserved */
+#define CRAMFS_FLAG_SHIFTED_ROOT_OFFSET	0x00000400	/* shifted root fs */
+
+/*
+ * Valid values in super.flags.  Currently we refuse to mount
+ * if (flags & ~CRAMFS_SUPPORTED_FLAGS).  Maybe that should be
+ * changed to test super.future instead.
+ */
+#define CRAMFS_SUPPORTED_FLAGS	( 0x000000ff \
+				| CRAMFS_FLAG_HOLES \
+				| CRAMFS_FLAG_WRONG_SIGNATURE \
+				| CRAMFS_FLAG_SHIFTED_ROOT_OFFSET )
+
+/* Uncompression interfaces to the underlying zlib */
+int cramfs_uncompress_block(void *dst, int dstlen, void *src, int srclen);
+int cramfs_uncompress_init(void);
+int cramfs_uncompress_exit(void);
+
+#endif
--- a/cramfs/src/linux/cramfs_fs_sb.h
+++ b/cramfs/src/linux/cramfs_fs_sb.h
@@ -0,0 +1,15 @@
+#ifndef _CRAMFS_FS_SB
+#define _CRAMFS_FS_SB
+
+/*
+ * cramfs super-block data in memory
+ */
+struct cramfs_sb_info {
+			unsigned long magic;
+			unsigned long size;
+			unsigned long blocks;
+			unsigned long files;
+			unsigned long flags;
+};
+
+#endif
--- a/mkcramfs.c
+++ b/mkcramfs.c
@@ -1,3 +1,4 @@
+/* vi: set sw=8 ts=8: */
 /*
  * mkcramfs - make a cramfs file system
  *
@@ -16,14 +17,22 @@
  * You should have received a copy of the GNU General Public License
  * along with this program; if not, write to the Free Software
  * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
+ *
+ * Added device table support (code taken from mkfs.jffs2.c, credit to
+ * Erik Andersen <andersen@codepoet.org>) as well as an option to squash
+ * permissions. - Russ Dill <Russ.Dill@asu.edu> September 2002
+ *
+ * Reworked, cleaned up, and updated for cramfs-1.1, December 2002
+ *  - Erik Andersen <andersen@codepoet.org>
  */

 /*
  * If you change the disk format of cramfs, please update fs/cramfs/README.
  */

+#define _GNU_SOURCE
+#include <stdio.h>
 #include <sys/types.h>
-#include <stdio.h>
 #include <sys/stat.h>
 #include <unistd.h>
 #include <sys/mman.h>
@@ -33,9 +42,30 @@
 #include <errno.h>
 #include <string.h>
 #include <stdarg.h>
+#include <libgen.h>
+#include <ctype.h>
+#include <assert.h>
+#include <getopt.h>
 #include <linux/cramfs_fs.h>
 #include <zlib.h>

+#if defined(__CYGWIN__)
+#include "cramfs/src/getline.c"
+typedef long long int loff_t;
+#ifndef MAP_ANON
+#define MAP_ANONYMOUS MAP_ANON
+#endif // MAP_ANON
+#endif /* __CYGWIN__ */
+
+#ifdef DARWIN
+#if ! defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || \
+    (__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 1070)
+#include "cramfs/src/getline.c"
+#endif // OS X < 10.7
+typedef long long int loff_t;
+#define MAP_ANONYMOUS MAP_ANON
+#endif /* DARWIN */
+
 /* Exit codes used by mkfs-type programs */
 #define MKFS_OK          0	/* No errors */
 #define MKFS_ERROR       8	/* Operational error */
@@ -71,11 +98,17 @@
 		  + (1 << CRAMFS_SIZE_WIDTH) - 1 /* filesize */ \
 		  + (1 << CRAMFS_SIZE_WIDTH) * 4 / PAGE_CACHE_SIZE /* block pointers */ )

+
+/* The kernel assumes PAGE_CACHE_SIZE as block size. */
+#define PAGE_CACHE_SIZE (4096)
+
+
 static const char *progname = "mkcramfs";
 static unsigned int blksize = PAGE_CACHE_SIZE;
 static long total_blocks = 0, total_nodes = 1; /* pre-count the root node */
 static int image_length = 0;

+
 /*
  * If opt_holes is set, then mkcramfs can create explicit holes in the
  * data, which saves 26 bytes per hole (which is a lot smaller a
@@ -91,11 +124,15 @@
 static int opt_holes = 0;
 static int opt_pad = 0;
 static int opt_verbose = 0;
+static int opt_squash = 0;
 static char *opt_image = NULL;
 static char *opt_name = NULL;

 static int warn_dev, warn_gid, warn_namelen, warn_skip, warn_size, warn_uid;
+static int swap_endian = 0;

+static const char *const memory_exhausted = "memory exhausted";
+
 /* In-core version of inode / directory entry. */
 struct entry {
 	/* stats */
@@ -123,49 +160,168 @@
 {
 	FILE *stream = status ? stderr : stdout;

-	fprintf(stream, "usage: %s [-h] [-e edition] [-i file] [-n name] dirname outfile\n"
+	fprintf(stream, "usage: %s [-h] [-e edition] [-i file] [-n name] [-D file] dirname outfile\n"
 		" -h         print this help\n"
 		" -E         make all warnings errors (non-zero exit status)\n"
 		" -e edition set edition number (part of fsid)\n"
 		" -i file    insert a file image into the filesystem (requires >= 2.4.0)\n"
 		" -n name    set name of cramfs filesystem\n"
 		" -p         pad by %d bytes for boot code\n"
+		" -r         reverse endian-ness of filesystem\n"
 		" -s         sort directory entries (old option, ignored)\n"
 		" -v         be more verbose\n"
 		" -z         make explicit holes (requires >= 2.3.39)\n"
-		" dirname    root of the directory tree to be compressed\n"
+		" -D         Use the named FILE as a device table file\n"
+		" -q         squash permissions (make everything owned by root)\n"
+		" dirname    root of the filesystem to be compressed\n"
 		" outfile    output file\n", progname, PAD_SIZE);

 	exit(status);
 }

-static void die(int status, int syserr, const char *fmt, ...)
+static void verror_msg(const char *s, va_list p)
 {
-	va_list arg_ptr;
-	int save = errno;
+	fflush(stdout);
+	fprintf(stderr, "mkcramfs: ");
+	vfprintf(stderr, s, p);
+}

-	fflush(0);
-	va_start(arg_ptr, fmt);
-	fprintf(stderr, "%s: ", progname);
-	vfprintf(stderr, fmt, arg_ptr);
-	if (syserr) {
-		fprintf(stderr, ": %s", strerror(save));
+static void vperror_msg(const char *s, va_list p)
+{
+	int err = errno;
+
+	if (s == 0)
+		s = "";
+	verror_msg(s, p);
+	if (*s)
+		s = ": ";
+	fprintf(stderr, "%s%s\n", s, strerror(err));
+}
+
+static void perror_msg(const char *s, ...)
+{
+	va_list p;
+
+	va_start(p, s);
+	vperror_msg(s, p);
+	va_end(p);
+}
+
+static void error_msg_and_die(const char *s, ...)
+{
+	va_list p;
+
+	va_start(p, s);
+	verror_msg(s, p);
+	va_end(p);
+	putc('\n', stderr);
+	exit(MKFS_ERROR);
+}
+
+static void perror_msg_and_die(const char *s, ...)
+{
+	va_list p;
+
+	va_start(p, s);
+	vperror_msg(s, p);
+	va_end(p);
+	exit(MKFS_ERROR);
+}
+#ifndef DMALLOC
+extern char *xstrdup(const char *s)
+{
+	char *t;
+
+	if (s == NULL)
+		return NULL;
+	t = strdup(s);
+	if (t == NULL)
+		error_msg_and_die(memory_exhausted);
+	return t;
+}
+
+extern void *xmalloc(size_t size)
+{
+	void *ptr = malloc(size);
+
+	if (ptr == NULL && size != 0)
+		error_msg_and_die(memory_exhausted);
+	return ptr;
+}
+
+extern void *xcalloc(size_t nmemb, size_t size)
+{
+	void *ptr = calloc(nmemb, size);
+
+	if (ptr == NULL && nmemb != 0 && size != 0)
+		error_msg_and_die(memory_exhausted);
+	return ptr;
+}
+
+extern void *xrealloc(void *ptr, size_t size)
+{
+	ptr = realloc(ptr, size);
+	if (ptr == NULL && size != 0)
+		error_msg_and_die(memory_exhausted);
+	return ptr;
+}
+#endif
+
+static FILE *xfopen(const char *path, const char *mode)
+{
+	FILE *fp;
+
+	if ((fp = fopen(path, mode)) == NULL)
+		perror_msg_and_die("%s", path);
+	return fp;
+}
+
+extern int xopen(const char *pathname, int flags, mode_t mode)
+{
+	int ret;
+	
+	if (flags & O_CREAT)
+		ret = open(pathname, flags, mode);
+	else
+		ret = open(pathname, flags);
+	if (ret == -1) {
+		perror_msg_and_die("%s", pathname);
 	}
-	fprintf(stderr, "\n");
-	va_end(arg_ptr);
-	exit(status);
+	return ret;
 }

+extern char *xreadlink(const char *path)
+{
+	static const int GROWBY = 80; /* how large we will grow strings by */
+
+	char *buf = NULL;
+	int bufsize = 0, readsize = 0;
+
+	do {
+		buf = xrealloc(buf, bufsize += GROWBY);
+		readsize = readlink(path, buf, bufsize); /* 1st try */
+		if (readsize == -1) {
+		    perror_msg("%s:%s", progname, path);
+		    return NULL;
+		}
+	}
+	while (bufsize < readsize + 1);
+
+	buf[readsize] = '\0';
+
+	return buf;
+}
+
 static void map_entry(struct entry *entry)
 {
 	if (entry->path) {
 		entry->fd = open(entry->path, O_RDONLY);
 		if (entry->fd < 0) {
-			die(MKFS_ERROR, 1, "open failed: %s", entry->path);
+			error_msg_and_die("open failed: %s", entry->path);
 		}
 		entry->uncompressed = mmap(NULL, entry->size, PROT_READ, MAP_PRIVATE, entry->fd, 0);
 		if (entry->uncompressed == MAP_FAILED) {
-			die(MKFS_ERROR, 1, "mmap failed: %s", entry->path);
+			error_msg_and_die("mmap failed: %s", entry->path);
 		}
 	}
 }
@@ -174,8 +330,9 @@
 {
 	if (entry->path) {
 		if (munmap(entry->uncompressed, entry->size) < 0) {
-			die(MKFS_ERROR, 1, "munmap failed: %s", entry->path);
+			error_msg_and_die("munmap failed: %s", entry->path);
 		}
+		entry->uncompressed=NULL;
 		close(entry->fd);
 	}
 }
@@ -204,7 +361,8 @@
 		find_identical_file(orig->next, newfile));
 }

-static void eliminate_doubles(struct entry *root, struct entry *orig) {
+static void eliminate_doubles(struct entry *root, struct entry *orig)
+{
 	if (orig) {
 		if (orig->size && (orig->path || orig->uncompressed))
 			find_identical_file(root, orig);
@@ -217,7 +375,11 @@
  * We define our own sorting function instead of using alphasort which
  * uses strcoll and changes ordering based on locale information.
  */
+#if defined(__CYGWIN__)
+static int cramsort (const struct dirent ** a, const struct dirent ** b)
+#else /* !(__CYGWIN__)*/
 static int cramsort (const void *a, const void *b)
+#endif /* __CYGWIN__ */
 {
 	return strcmp ((*(const struct dirent **) a)->d_name,
 		       (*(const struct dirent **) b)->d_name);
@@ -232,10 +394,7 @@

 	/* Set up the path. */
 	/* TODO: Reuse the parent's buffer to save memcpy'ing and duplication. */
-	path = malloc(len + 1 + MAX_INPUT_NAMELEN + 1);
-	if (!path) {
-		die(MKFS_ERROR, 1, "malloc failed");
-	}
+	path = xmalloc(len + 1 + MAX_INPUT_NAMELEN + 1);
 	memcpy(path, name, len);
 	endpath = path + len;
 	*endpath = '/';
@@ -245,7 +404,7 @@
 	dircount = scandir(name, &dirlist, 0, cramsort);

 	if (dircount < 0) {
-		die(MKFS_ERROR, 1, "scandir failed: %s", name);
+		error_msg_and_die("scandir failed: %s", name);
 	}

 	/* process directory */
@@ -269,25 +428,20 @@
 		}
 		namelen = strlen(dirent->d_name);
 		if (namelen > MAX_INPUT_NAMELEN) {
-			die(MKFS_ERROR, 0,
-				"very long (%u bytes) filename found: %s\n"
-				"please increase MAX_INPUT_NAMELEN in mkcramfs.c and recompile",
+			error_msg_and_die(
+				"Very long (%u bytes) filename `%s' found.\n"
+				" Please increase MAX_INPUT_NAMELEN in mkcramfs.c and recompile.  Exiting.\n",
 				namelen, dirent->d_name);
 		}
 		memcpy(endpath, dirent->d_name, namelen + 1);

 		if (lstat(path, &st) < 0) {
+			perror(endpath);
 			warn_skip = 1;
 			continue;
 		}
-		entry = calloc(1, sizeof(struct entry));
-		if (!entry) {
-			die(MKFS_ERROR, 1, "calloc failed");
-		}
-		entry->name = strdup(dirent->d_name);
-		if (!entry->name) {
-			die(MKFS_ERROR, 1, "strdup failed");
-		}
+		entry = xcalloc(1, sizeof(struct entry));
+		entry->name = xstrdup(dirent->d_name);
 		/* truncate multi-byte UTF-8 filenames on character boundary */
 		if (namelen > CRAMFS_MAXPATHLEN) {
 			namelen = CRAMFS_MAXPATHLEN;
@@ -297,24 +451,25 @@
 				namelen--;
 				/* are we reasonably certain it was UTF-8 ? */
 				if (entry->name[namelen] < 0x80 || !namelen) {
-					die(MKFS_ERROR, 0, "cannot truncate filenames not encoded in UTF-8");
+					error_msg_and_die("cannot truncate filenames not encoded in UTF-8");
 				}
 			}
 			entry->name[namelen] = '\0';
 		}
 		entry->mode = st.st_mode;
 		entry->size = st.st_size;
-		entry->uid = st.st_uid;
+		entry->uid = opt_squash ? 0 : st.st_uid;
 		if (entry->uid >= 1 << CRAMFS_UID_WIDTH)
 			warn_uid = 1;
-		entry->gid = st.st_gid;
-		if (entry->gid >= 1 << CRAMFS_GID_WIDTH)
+		entry->gid = opt_squash ? 0 : st.st_gid;
+		if (entry->gid >= 1 << CRAMFS_GID_WIDTH) {
 			/* TODO: We ought to replace with a default
 			   gid instead of truncating; otherwise there
 			   are security problems.  Maybe mode should
 			   be &= ~070.  Same goes for uid once Linux
 			   supports >16-bit uids. */
 			warn_gid = 1;
+		}
 		size = sizeof(struct cramfs_inode) + ((namelen + 3) & ~3);
 		*fslen_ub += size;
 		if (S_ISDIR(st.st_mode)) {
@@ -325,21 +480,15 @@
 					warn_skip = 1;
 					continue;
 				}
-				entry->path = strdup(path);
-				if (!entry->path) {
-					die(MKFS_ERROR, 1, "strdup failed");
-				}
+				entry->path = xstrdup(path);
 				if ((entry->size >= 1 << CRAMFS_SIZE_WIDTH)) {
 					warn_size = 1;
 					entry->size = (1 << CRAMFS_SIZE_WIDTH) - 1;
 				}
 			}
 		} else if (S_ISLNK(st.st_mode)) {
-			entry->uncompressed = malloc(entry->size);
+			entry->uncompressed = xreadlink(path);
 			if (!entry->uncompressed) {
-				die(MKFS_ERROR, 1, "malloc failed");
-			}
-			if (readlink(path, entry->uncompressed, entry->size) < 0) {
 				warn_skip = 1;
 				continue;
 			}
@@ -347,11 +496,28 @@
 			/* maybe we should skip sockets */
 			entry->size = 0;
 		} else if (S_ISCHR(st.st_mode) || S_ISBLK(st.st_mode)) {
+#if defined(__CYGWIN__) || defined(DARWIN)
+			/* The stat stucture returned by lstat() should be adapted to
+			 * Linux format.  Translate to Cygwin's minor and major number
+			 * format (/usr/include/sys/sysmacros.h)
+			 */
+			int major = ((int)((st.st_rdev) >> 16) & 0xffff);
+			int minor = ((int)((st.st_rdev) & 0xffff));
+
+			/* Fill fs entry with a Linux compliant file attribute (see
+			 * same header file under Linux)
+			 */
+
+			entry->size = ((minor & 0xff) | ((major & 0xfff) << 8)
+					| (((unsigned long long int) (minor & ~0xff)) << 12)
+					| (((unsigned long long int) (major & ~0xfff)) << 32));
+#else
 			entry->size = st.st_rdev;
+#endif /* __CYGWIN__ || DARWIN */
 			if (entry->size & -(1<<CRAMFS_SIZE_WIDTH))
 				warn_dev = 1;
 		} else {
-			die(MKFS_ERROR, 0, "bogus file type: %s", entry->name);
+			error_msg_and_die("bogus file type: %s", entry->name);
 		}

 		if (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode)) {
@@ -372,13 +538,59 @@
 	return totalsize;
 }

+/* routines to swap endianness/bitfields in inode/superblock block data */
+static void fix_inode(struct cramfs_inode *inode)
+{
+#define wswap(x)    (((x)>>24) | (((x)>>8)&0xff00) | (((x)&0xff00)<<8) | (((x)&0xff)<<24))
+	/* attempt #2 */
+	inode->mode = (inode->mode >> 8) | ((inode->mode&0xff)<<8);
+	inode->uid = (inode->uid >> 8) | ((inode->uid&0xff)<<8);
+	inode->size = (inode->size >> 16) | (inode->size&0xff00) |
+		((inode->size&0xff)<<16);
+	((u32*)inode)[2] = wswap(inode->offset | (inode->namelen<<26));
+}
+
+static void fix_offset(struct cramfs_inode *inode, u32 offset)
+{
+	u32 tmp = wswap(((u32*)inode)[2]);
+	((u32*)inode)[2] = wswap((offset >> 2) | (tmp&0xfc000000));
+}
+
+static void fix_block_pointer(u32 *p)
+{
+	*p = wswap(*p);
+}
+
+static void fix_super(struct cramfs_super *super)
+{
+	u32 *p = (u32*)super;
+
+	/* fix superblock fields */
+	p[0] = wswap(p[0]);     /* magic */
+	p[1] = wswap(p[1]);     /* size */
+	p[2] = wswap(p[2]);     /* flags */
+	p[3] = wswap(p[3]);     /* future */
+
+	/* fix filesystem info fields */
+	p = (u32*)&super->fsid;
+	p[0] = wswap(p[0]);     /* crc */
+	p[1] = wswap(p[1]);     /* edition */
+	p[2] = wswap(p[2]);     /* blocks */
+	p[3] = wswap(p[3]);     /* files */
+
+	fix_inode(&super->root);
+#undef wswap
+}
+
 /* Returns sizeof(struct cramfs_super), which includes the root inode. */
 static unsigned int write_superblock(struct entry *root, char *base, int size)
 {
 	struct cramfs_super *super = (struct cramfs_super *) base;
 	unsigned int offset = sizeof(struct cramfs_super) + image_length;

-	offset += opt_pad;	/* 0 if no padding */
+	if (opt_pad) {
+		offset += opt_pad;	/* 0 if no padding */
+	}

 	super->magic = CRAMFS_MAGIC;
 	super->flags = CRAMFS_FLAG_FSID_VERSION_2 | CRAMFS_FLAG_SORTED_DIRS;
@@ -406,6 +618,9 @@
 	super->root.size = root->size;
 	super->root.offset = offset >> 2;

+	if (swap_endian)
+		fix_super(super);
+
 	return offset;
 }

@@ -414,12 +629,16 @@
 	struct cramfs_inode *inode = (struct cramfs_inode *) (base + entry->dir_offset);

 	if ((offset & 3) != 0) {
-		die(MKFS_ERROR, 0, "illegal offset of %lu bytes", offset);
+		error_msg_and_die("illegal offset of %lu bytes", offset);
 	}
 	if (offset >= (1 << (2 + CRAMFS_OFFSET_WIDTH))) {
-		die(MKFS_ERROR, 0, "filesystem too big");
+		error_msg_and_die("filesystem too big");
 	}
-	inode->offset = (offset >> 2);
+
+	if (swap_endian)
+		fix_offset(inode, offset);
+	else
+		inode->offset = (offset >> 2);
 }

 /*
@@ -429,7 +648,7 @@
  */
 static void print_node(struct entry *e)
 {
-	char info[10];
+	char info[12];
 	char type = '?';

 	if (S_ISREG(e->mode)) type = 'f';
@@ -442,11 +661,11 @@

 	if (S_ISCHR(e->mode) || (S_ISBLK(e->mode))) {
 		/* major/minor numbers can be as high as 2^12 or 4096 */
-		snprintf(info, 10, "%4d,%4d", major(e->size), minor(e->size));
+		snprintf(info, 11, "%4d,%4d", major(e->size), minor(e->size));
 	}
 	else {
 		/* size be as high as 2^24 or 16777216 */
-		snprintf(info, 10, "%9d", e->size);
+		snprintf(info, 11, "%9d", e->size);
 	}

 	printf("%c %04o %s %5d:%-3d %s\n",
@@ -462,17 +681,9 @@
 {
 	int stack_entries = 0;
 	int stack_size = 64;
-	struct entry **entry_stack;
+	struct entry **entry_stack = NULL;

-	entry_stack = malloc(stack_size * sizeof(struct entry *));
-	if (!entry_stack) {
-		die(MKFS_ERROR, 1, "malloc failed");
-	}
-
-	if (opt_verbose) {
-		printf("root:\n");
-	}
-
+	entry_stack = xmalloc(stack_size * sizeof(struct entry *));
 	for (;;) {
 		int dir_start = stack_entries;
 		while (entry) {
@@ -506,15 +717,14 @@
 			if (entry->child) {
 				if (stack_entries >= stack_size) {
 					stack_size *= 2;
-					entry_stack = realloc(entry_stack, stack_size * sizeof(struct entry *));
-					if (!entry_stack) {
-						die(MKFS_ERROR, 1, "realloc failed");
-					}
+					entry_stack = xrealloc(entry_stack, stack_size * sizeof(struct entry *));
 				}
 				entry_stack[stack_entries] = entry;
 				stack_entries++;
 			}
 			entry = entry->next;
+			if (swap_endian)
+				fix_inode(inode);
 		}

 		/*
@@ -543,7 +753,7 @@

 		set_data_offset(entry, base, offset);
 		if (opt_verbose) {
-			printf("%s:\n", entry->name);
+		    printf("'%s':\n", entry->name);
 		}
 		entry = entry->child;
 	}
@@ -553,16 +763,21 @@

 static int is_zero(char const *begin, unsigned len)
 {
-	/* Returns non-zero iff the first LEN bytes from BEGIN are all NULs. */
-	return (len-- == 0 ||
-		(begin[0] == '\0' &&
-		 (len-- == 0 ||
-		  (begin[1] == '\0' &&
-		   (len-- == 0 ||
-		    (begin[2] == '\0' &&
-		     (len-- == 0 ||
-		      (begin[3] == '\0' &&
-		       memcmp(begin, begin + 4, len) == 0))))))));
+	if (opt_holes)
+		/* Returns non-zero iff the first LEN bytes from BEGIN are
+		   all NULs. */
+		return (len-- == 0 ||
+			(begin[0] == '\0' &&
+			 (len-- == 0 ||
+			  (begin[1] == '\0' &&
+			   (len-- == 0 ||
+			    (begin[2] == '\0' &&
+			     (len-- == 0 ||
+			      (begin[3] == '\0' &&
+			       memcmp(begin, begin + 4, len) == 0))))))));
+	else
+		/* Never create holes. */
+		return 0;
 }

 /*
@@ -575,40 +790,39 @@
  * Note that size > 0, as a zero-sized file wouldn't ever
  * have gotten here in the first place.
  */
-static unsigned int do_compress(char *base, unsigned int offset, char const *name, char *uncompressed, unsigned int size)
+static unsigned int do_compress(char *base, unsigned int offset, struct entry *entry)
 {
+	unsigned int size = entry->size;
 	unsigned long original_size = size;
 	unsigned long original_offset = offset;
 	unsigned long new_size;
 	unsigned long blocks = (size - 1) / blksize + 1;
 	unsigned long curr = offset + 4 * blocks;
 	int change;
+	char *uncompressed = entry->uncompressed;

-	total_blocks += blocks;
+	total_blocks += blocks;

 	do {
 		unsigned long len = 2 * blksize;
 		unsigned int input = size;
-		int err;
-
 		if (input > blksize)
 			input = blksize;
 		size -= input;
-		if (!(opt_holes && is_zero (uncompressed, input))) {
-			err = compress2(base + curr, &len, uncompressed, input, Z_BEST_COMPRESSION);
-			if (err != Z_OK) {
-				die(MKFS_ERROR, 0, "compression error: %s", zError(err));
-			}
+		if (!is_zero (uncompressed, input)) {
+			compress(base + curr, &len, uncompressed, input);
 			curr += len;
 		}
 		uncompressed += input;

 		if (len > blksize*2) {
 			/* (I don't think this can happen with zlib.) */
-			die(MKFS_ERROR, 0, "AIEEE: block \"compressed\" to > 2*blocklength (%ld)", len);
+			error_msg_and_die("AIEEE: block \"compressed\" to > 2*blocklength (%ld)\n", len);
 		}

 		*(u32 *) (base + offset) = curr;
+		if (swap_endian)
+			fix_block_pointer((u32*)(base + offset));
 		offset += 4;
 	} while (size);

@@ -618,10 +832,12 @@
 	   st_blocks * 512.  But if you say that then perhaps
 	   administrative data should also be included in both. */
 	change = new_size - original_size;
-	if (opt_verbose > 1) {
-		printf("%6.2f%% (%+d bytes)\t%s\n",
-		       (change * 100) / (double) original_size, change, name);
+#if 0
+	if (opt_verbose) {
+	    printf("%6.2f%% (%+d bytes)\t%s\n",
+		    (change * 100) / (double) original_size, change, entry->name);
 	}
+#endif

 	return curr;
 }
@@ -644,7 +860,7 @@
 				set_data_offset(entry, base, offset);
 				entry->offset = offset;
 				map_entry(entry);
-				offset = do_compress(base, offset, entry->name, entry->uncompressed, entry->size);
+				offset = do_compress(base, offset, entry);
 				unmap_entry(entry);
 			}
 		}
@@ -660,13 +876,10 @@
 	int fd;
 	char *buf;

-	fd = open(file, O_RDONLY);
-	if (fd < 0) {
-		die(MKFS_ERROR, 1, "open failed: %s", file);
-	}
+	fd = xopen(file, O_RDONLY, 0);
 	buf = mmap(NULL, image_length, PROT_READ, MAP_PRIVATE, fd, 0);
 	if (buf == MAP_FAILED) {
-		die(MKFS_ERROR, 1, "mmap failed");
+		error_msg_and_die("mmap failed");
 	}
 	memcpy(base + offset, buf, image_length);
 	munmap(buf, image_length);
@@ -679,6 +892,336 @@
 	return (offset + image_length);
 }

+static struct entry *find_filesystem_entry(struct entry *dir, char *name, mode_t type)
+{
+	struct entry *e = dir;
+
+	if (S_ISDIR(dir->mode)) {
+		e = dir->child;
+	}
+	while (e) {
+		/* Only bother to do the expensive strcmp on matching file types */
+		if (type == (e->mode & S_IFMT) && e->name) {
+			if (S_ISDIR(e->mode)) {
+				int len = strlen(e->name);
+
+				/* Check if we are a parent of the correct path */
+				if (strncmp(e->name, name, len) == 0) {
+					/* Is this an _exact_ match? */
+					if (strcmp(name, e->name) == 0) {
+						return (e);
+					}
+					/* Looks like we found a parent of the correct path */
+					if (name[len] == '/') {
+						if (e->child) {
+							name = strchr (name, '/');
+							return (find_filesystem_entry (e, name + len + 1, type));
+						} else {
+							return NULL;
+						}
+					}
+				}
+			} else {
+				if (strcmp(name, e->name) == 0) {
+					return (e);
+				}
+			}
+		}
+		e = e->next;
+	}
+	return (NULL);
+}
+
+void modify_entry(char *full_path, unsigned long uid, unsigned long gid,
+	unsigned long mode, unsigned long rdev, struct entry *root, loff_t *fslen_ub)
+{
+	char *name, *path, *full;
+	struct entry *curr, *parent, *entry, *prev;
+	
+	full = xstrdup(full_path);
+	path = xstrdup(dirname(full));
+	name = full_path + strlen(path) + 1;
+	free(full);
+	if (strcmp(path, "/") == 0) {
+		parent = root;
+		name = full_path + 1;
+	} else {
+		if (!(parent = find_filesystem_entry(root, path+1, S_IFDIR)))
+			error_msg_and_die("%s/%s: could not find parent\n", path, name);
+	}
+	if ((entry = find_filesystem_entry(parent, name, (mode & S_IFMT)))) {
+		/* its there, just modify permissions */
+		entry->mode = mode;
+		entry->uid = uid;
+		entry->gid = gid;
+	} else { /* make a new entry */
+	
+		/* code partially replicated from parse_directory() */
+		size_t namelen;
+		if (S_ISREG(mode)) {
+			error_msg_and_die("%s: regular file from device_table file must exist on disk!", full_path);
+		}
+
+		namelen = strlen(name);
+		if (namelen > MAX_INPUT_NAMELEN) {
+			error_msg_and_die(
+				"Very long (%u bytes) filename `%s' found.\n"
+				" Please increase MAX_INPUT_NAMELEN in mkcramfs.c and recompile.  Exiting.\n",
+				namelen, name);
+		}
+		entry = xcalloc(1, sizeof(struct entry));
+		entry->name = xstrdup(name);
+		/* truncate multi-byte UTF-8 filenames on character boundary */
+		if (namelen > CRAMFS_MAXPATHLEN) {
+			namelen = CRAMFS_MAXPATHLEN;
+			warn_namelen = 1;
+			/* the first lost byte must not be a trail byte */
+			while ((entry->name[namelen] & 0xc0) == 0x80) {
+				namelen--;
+				/* are we reasonably certain it was UTF-8 ? */
+				if (entry->name[namelen] < 0x80 || !namelen) {
+					error_msg_and_die("cannot truncate filenames not encoded in UTF-8");
+				}
+			}
+			entry->name[namelen] = '\0';
+		}
+		entry->mode = mode;
+		entry->uid = uid;
+		entry->gid = gid;
+		entry->size = 0;
+		if (S_ISBLK(mode) || S_ISCHR(mode)) {
+			entry->size = rdev;
+			if (entry->size & -(1<<CRAMFS_SIZE_WIDTH))
+				warn_dev = 1;
+		}
+		
+		/* ok, now we have to backup and correct the size of all the entries above us */
+		*fslen_ub += sizeof(struct cramfs_inode) + ((namelen + 3) & ~3);
+		parent->size += sizeof(struct cramfs_inode) + ((namelen + 3) & ~3);
+
+		/* alright, time to link us in */
+		curr = parent->child;
+		prev = NULL;
+		while (curr && strcmp(name, curr->name) > 0) {
+			prev = curr;
+			curr = curr->next;
+		}
+		if (!prev) parent->child = entry;
+		else prev->next = entry;
+		entry->next = curr;
+		entry->child = NULL;
+	}
+	if (entry->uid >= 1 << CRAMFS_UID_WIDTH)
+		warn_uid = 1;
+	if (entry->gid >= 1 << CRAMFS_GID_WIDTH) {
+		/* TODO: We ought to replace with a default
+		   gid instead of truncating; otherwise there
+		   are security problems.  Maybe mode should
+		   be &= ~070.  Same goes for uid once Linux
+		   supports >16-bit uids. */
+		warn_gid = 1;
+	}
+	free(path);
+}
+
+/* the GNU C library has a wonderful scanf("%as", string) which will
+ allocate the string with the right size, good to avoid buffer overruns.
+ the following macros use it if available or use a hacky workaround...
+ */
+
+#if defined __GNUC__ && !defined __CYGWIN__
+#define SCANF_PREFIX "a"
+#define SCANF_STRING(s) (&s)
+#define GETCWD_SIZE 0
+#else
+#define SCANF_PREFIX "511"
+#define SCANF_STRING(s) (s = xmalloc(512))
+#define GETCWD_SIZE -1
+#define UNUSED __attribute__ ((__unused__))
+#if MISSING_SNPRINTF
+inline int snprintf(char *str, size_t n UNUSED, const char *fmt, ...)
+{
+	int ret;
+	va_list ap;
+
+	va_start(ap, fmt);
+	ret = vsprintf(str, fmt, ap);
+	va_end(ap);
+	return ret;
+}
+#endif // MISSING_SNPRINTF
+#endif
+
+/*  device table entries take the form of:
+    <path>	<type> <mode>	<uid>	<gid>	<major>	<minor>	<start>	<inc>	<count>
+    /dev/mem     c    640       0       0         1       1       0     0         -
+
+    type can be one of:
+	f	A regular file
+	d	Directory
+	c	Character special device file
+	b	Block special device file
+	p	Fifo (named pipe)
+
+    I don't bother with symlinks (permissions are irrelevant), hard
+    links (special cases of regular files), or sockets (why bother).
+
+    Regular files must exist in the target root directory.  If a char,
+    block, fifo, or directory does not exist, it will be created.
+*/
+
+static int interpret_table_entry(char *line, struct entry *root, loff_t *fslen_ub)
+{
+	char type, *name = NULL;
+	unsigned long mode = 0755, uid = 0, gid = 0, major = 0, minor = 0;
+	unsigned long start = 0, increment = 1, count = 0;
+
+	if (sscanf (line, "%" SCANF_PREFIX "s %c %lo %lu %lu %lu %lu %lu %lu %lu",
+		 SCANF_STRING(name), &type, &mode, &uid, &gid, &major, &minor,
+		 &start, &increment, &count) < 0)
+	{
+		return 1;
+	}
+
+	if (!strcmp(name, "/")) {
+		error_msg_and_die("Device table entries require absolute paths");
+	}
+
+	switch (type) {
+	case 'd':
+		mode |= S_IFDIR;
+		modify_entry(name, uid, gid, mode, 0, root, fslen_ub);
+		break;
+	case 'f':
+		mode |= S_IFREG;
+		modify_entry(name, uid, gid, mode, 0, root, fslen_ub);
+		break;
+	case 'p':
+		mode |= S_IFIFO;
+		modify_entry(name, uid, gid, mode, 0, root, fslen_ub);
+		break;
+	case 'c':
+	case 'b':
+		mode |= (type == 'c') ? S_IFCHR : S_IFBLK;
+		if (count > 0) {
+			char *buf;
+			unsigned long i;
+			dev_t rdev;
+
+			for (i = start; i < count; i++) {
+				asprintf(&buf, "%s%lu", name, i);
+				rdev = makedev(major, minor + (i * increment - start));
+				modify_entry(buf, uid, gid, mode, rdev, root, fslen_ub);
+				free(buf);
+			}
+		} else {
+			dev_t rdev = makedev(major, minor);
+			modify_entry(name, uid, gid, mode, rdev, root, fslen_ub);
+		}
+		break;
+	case 'l':
+		mode |= S_IFLNK;
+		modify_entry(name, uid, gid, mode, 0, root, fslen_ub);
+		break;
+	default:
+		error_msg_and_die("Unsupported file type");
+	}
+	free(name);
+	return 0;
+}
+
+static int parse_device_table(FILE *file, struct entry *root, loff_t *fslen_ub)
+{
+	char *line;
+	int status = 0;
+	size_t length = 0;
+
+	/* Turn off squash, since we must ensure that values
+	 * entered via the device table are not squashed */
+	opt_squash = 0;
+
+	/* Looks ok so far.  The general plan now is to read in one
+	 * line at a time, check for leading comment delimiters ('#'),
+	 * then try and parse the line as a device table.  If we fail
+	 * to parse things, try and help the poor fool to fix their
+	 * device table with a useful error msg... */
+	line = NULL;
+	while (getline(&line, &length, file) != -1) {
+		/* First trim off any whitespace */
+		int len = strlen(line);
+
+		/* trim trailing whitespace */
+		while (len > 0 && isspace(line[len - 1]))
+			line[--len] = '\0';
+		/* trim leading whitespace */
+		memmove(line, &line[strspn(line, " \n\r\t\v")], len);
+
+		/* How long are we after trimming? */
+		len = strlen(line);
+
+		/* If this is NOT a comment line, try to interpret it */
+		if (len && *line != '#') {
+			if (interpret_table_entry(line, root, fslen_ub))
+				status = 1;
+		}
+
+		free(line);
+		line = NULL;
+	}
+	free(line);
+	fclose(file);
+
+	return status;
+}
+
+void traverse(struct entry *entry, int depth)
+{
+	struct entry *curr = entry;
+	int i;
+
+	while (curr) {
+		for (i = 0; i < depth; i++) putchar(' ');
+		printf("%s: size=%d mode=%d same=%p\n",
+			(curr->name)? (char*)curr->name : "/",
+			curr->size, curr->mode, curr->same);
+		if (curr->child) traverse(curr->child, depth + 4);
+		curr = curr->next;
+	}
+}
+
+static void free_filesystem_entry(struct entry *dir)
+{
+	struct entry *e = dir, *last;
+
+	if (S_ISDIR(dir->mode)) {
+		e = dir->child;
+	}
+	while (e) {
+		if (e->name)
+			free(e->name);
+		if (e->path)
+			free(e->path);
+		if (e->uncompressed)
+			free(e->uncompressed);
+		last = e;
+		if (e->child) {
+			free_filesystem_entry(e);
+		}
+		e = e->next;
+		free(last);
+	}
+}
+
+
+/*
+ * Usage:
+ *
+ *      mkcramfs directory-name outfile
+ *
+ * where "directory-name" is simply the root of the directory
+ * tree that we want to generate a compressed filesystem out
+ * of.
+ */
 int main(int argc, char **argv)
 {
 	struct stat st;		/* used twice... */
@@ -692,6 +1235,7 @@
 	u32 crc;
 	int c;			/* for getopt */
 	char *ep;		/* for strtoul */
+	FILE *devtable = NULL;

 	total_blocks = 0;

@@ -699,7 +1243,7 @@
 		progname = argv[0];

 	/* command line options */
-	while ((c = getopt(argc, argv, "hEe:i:n:psvz")) != EOF) {
+	while ((c = getopt(argc, argv, "hEe:i:n:prsvzD:q")) != EOF) {
 		switch (c) {
 		case 'h':
 			usage(MKFS_OK);
@@ -715,7 +1259,7 @@
 		case 'i':
 			opt_image = optarg;
 			if (lstat(opt_image, &st) < 0) {
-				die(MKFS_ERROR, 1, "lstat failed: %s", opt_image);
+				error_msg_and_die("lstat failed: %s", opt_image);
 			}
 			image_length = st.st_size; /* may be padded later */
 			fslen_ub += (image_length + 3); /* 3 is for padding */
@@ -736,6 +1280,19 @@
 		case 'z':
 			opt_holes = 1;
 			break;
+		case 'r':
+			swap_endian = 1;
+			break;
+		case 'q':
+			opt_squash = 1;
+			break;
+		case 'D':
+			devtable = xfopen(optarg, "r");
+			if (fstat(fileno(devtable), &st) < 0)
+				perror_msg_and_die(optarg);
+			if (st.st_size < 10)
+				error_msg_and_die("%s: not a proper device table file\n", optarg);
+			break;
 		}
 	}

@@ -745,25 +1302,23 @@
 	outfile = argv[optind + 1];

 	if (stat(dirname, &st) < 0) {
-		die(MKFS_USAGE, 1, "stat failed: %s", dirname);
+		error_msg_and_die("stat failed: %s", dirname);
 	}
-	fd = open(outfile, O_WRONLY | O_CREAT | O_TRUNC, 0666);
-	if (fd < 0) {
-		die(MKFS_USAGE, 1, "open failed: %s", outfile);
-	}
+	fd = xopen(outfile, O_WRONLY | O_CREAT | O_TRUNC, 0666);

-	root_entry = calloc(1, sizeof(struct entry));
-	if (!root_entry) {
-		die(MKFS_ERROR, 1, "calloc failed");
-	}
+	root_entry = xcalloc(1, sizeof(struct entry));
 	root_entry->mode = st.st_mode;
 	root_entry->uid = st.st_uid;
 	root_entry->gid = st.st_gid;

 	root_entry->size = parse_directory(root_entry, dirname, &root_entry->child, &fslen_ub);

+	if (devtable) {
+		parse_device_table(devtable, root_entry, &fslen_ub);
+	}
+
 	/* always allocate a multiple of blksize bytes because that's
-	   what we're going to write later on */
+           what we're going to write later on */
 	fslen_ub = ((fslen_ub - 1) | (blksize - 1)) + 1;

 	if (fslen_ub > MAXFSLEN) {
@@ -790,7 +1345,7 @@
 	rom_image = mmap(NULL, fslen_ub?fslen_ub:1, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

 	if (rom_image == MAP_FAILED) {
-		die(MKFS_ERROR, 1, "mmap failed");
+		error_msg_and_die("mmap failed");
 	}

 	/* Skip the first opt_pad bytes for boot loader code */
@@ -807,37 +1362,46 @@
 	}

 	offset = write_directory_structure(root_entry->child, rom_image, offset);
-	printf("Directory data: %d bytes\n", offset);
+	if (opt_verbose)
+	printf("Directory data: %ld bytes\n", offset);

 	offset = write_data(root_entry, rom_image, offset);

 	/* We always write a multiple of blksize bytes, so that
 	   losetup works. */
 	offset = ((offset - 1) | (blksize - 1)) + 1;
-	printf("Everything: %d kilobytes\n", offset >> 10);
+	if (opt_verbose)
+	printf("Everything: %ld kilobytes\n", offset >> 10);

 	/* Write the superblock now that we can fill in all of the fields. */
 	write_superblock(root_entry, rom_image+opt_pad, offset);
-	printf("Super block: %d bytes\n", sizeof(struct cramfs_super));
+	if (opt_verbose)
+	printf("Super block: %ld bytes\n", sizeof(struct cramfs_super));

 	/* Put the checksum in. */
 	crc = crc32(0L, Z_NULL, 0);
 	crc = crc32(crc, (rom_image+opt_pad), (offset-opt_pad));
 	((struct cramfs_super *) (rom_image+opt_pad))->fsid.crc = crc;
+	if (opt_verbose)
 	printf("CRC: %x\n", crc);

 	/* Check to make sure we allocated enough space. */
 	if (fslen_ub < offset) {
-		die(MKFS_ERROR, 0, "not enough space allocated for ROM image (%Ld allocated, %d used)", fslen_ub, offset);
+		error_msg_and_die("not enough space allocated for ROM "
+			"image (%Ld allocated, %d used)", fslen_ub, offset);
 	}

 	written = write(fd, rom_image, offset);
 	if (written < 0) {
-		die(MKFS_ERROR, 1, "write failed");
+		error_msg_and_die("write failed");
 	}
 	if (offset != written) {
-		die(MKFS_ERROR, 0, "ROM image write failed (wrote %d of %d bytes)", written, offset);
+		error_msg_and_die("ROM image write failed (wrote %d of %d bytes)", written, offset);
 	}
+	
+	/* Free up memory */
+	free_filesystem_entry(root_entry);
+	free(root_entry);

 	/* (These warnings used to come at the start, but they scroll off the
 	   screen too quickly.) */
--- a/cramfs/src/getline.c
+++ b/cramfs/src/getline.c
@@ -0,0 +1,157 @@
+/* getline.c -- Replacement for GNU C library function getline
+
+Copyright (C) 1993, 1996 Free Software Foundation, Inc.
+
+This program is free software; you can redistribute it and/or
+modify it under the terms of the GNU General Public License as
+published by the Free Software Foundation; either version 2 of the
+License, or (at your option) any later version.
+
+This program is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+You should have received a copy of the GNU General Public License
+along with this program; if not, write to the Free Software
+Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */
+
+/* Written by Jan Brittenson, bson@gnu.ai.mit.edu.  */
+
+#if HAVE_CONFIG_H
+# include <config.h>
+#endif
+
+/* The `getdelim' function is only declared if the following symbol
+   is defined.  */
+#ifndef _GNU_SOURCE
+#define _GNU_SOURCE	1
+#endif
+#include <stdio.h>
+#include <sys/types.h>
+
+#if defined __GNU_LIBRARY__ && HAVE_GETDELIM
+
+int
+getline (lineptr, n, stream)
+     char **lineptr;
+     size_t *n;
+     FILE *stream;
+{
+  return getdelim (lineptr, n, '\n', stream);
+}
+
+
+#else /* ! have getdelim */
+
+# define NDEBUG
+# include <assert.h>
+
+# if STDC_HEADERS || defined(DARWIN) || defined(__CYGWIN__)
+#  include <stdlib.h>
+# else
+char *malloc (), *realloc ();
+# endif
+
+/* Always add at least this many bytes when extending the buffer.  */
+# define MIN_CHUNK 64
+
+/* Read up to (and including) a TERMINATOR from STREAM into *LINEPTR
+   + OFFSET (and null-terminate it). *LINEPTR is a pointer returned from
+   malloc (or NULL), pointing to *N characters of space.  It is realloc'd
+   as necessary.  Return the number of characters read (not including the
+   null terminator), or -1 on error or EOF.  */
+
+int
+getstr (lineptr, n, stream, terminator, offset)
+     char **lineptr;
+     size_t *n;
+     FILE *stream;
+     char terminator;
+     size_t offset;
+{
+  int nchars_avail;		/* Allocated but unused chars in *LINEPTR.  */
+  char *read_pos;		/* Where we're reading into *LINEPTR. */
+  int ret;
+
+  if (!lineptr || !n || !stream)
+    return -1;
+
+  if (!*lineptr)
+    {
+      *n = MIN_CHUNK;
+      *lineptr = malloc (*n);
+      if (!*lineptr)
+	return -1;
+    }
+
+  nchars_avail = *n - offset;
+  read_pos = *lineptr + offset;
+
+  for (;;)
+    {
+      register int c = getc (stream);
+
+      /* We always want at least one char left in the buffer, since we
+	 always (unless we get an error while reading the first char)
+	 NUL-terminate the line buffer.  */
+
+      assert(*n - nchars_avail == read_pos - *lineptr);
+      if (nchars_avail < 2)
+	{
+	  if (*n > MIN_CHUNK)
+	    *n *= 2;
+	  else
+	    *n += MIN_CHUNK;
+
+	  nchars_avail = *n + *lineptr - read_pos;
+	  *lineptr = realloc (*lineptr, *n);
+	  if (!*lineptr)
+	    return -1;
+	  read_pos = *n - nchars_avail + *lineptr;
+	  assert(*n - nchars_avail == read_pos - *lineptr);
+	}
+
+      if (c == EOF || ferror (stream))
+	{
+	  /* Return partial line, if any.  */
+	  if (read_pos == *lineptr)
+	    return -1;
+	  else
+	    break;
+	}
+
+      *read_pos++ = c;
+      nchars_avail--;
+
+      if (c == terminator)
+	/* Return the line.  */
+	break;
+    }
+
+  /* Done - NUL terminate and return the number of chars read.  */
+  *read_pos = '\0';
+
+  ret = read_pos - (*lineptr + offset);
+  return ret;
+}
+
+int
+getline (lineptr, n, stream)
+     char **lineptr;
+     size_t *n;
+     FILE *stream;
+{
+  return getstr (lineptr, n, stream, '\n', 0);
+}
+
+int
+getdelim (lineptr, n, delimiter, stream)
+     char **lineptr;
+     size_t *n;
+     int delimiter;
+     FILE *stream;
+{
+  return getstr (lineptr, n, stream, delimiter, 0);
+}
+#endif
--- a/cramfsck.c
+++ b/cramfsck.c
@@ -47,14 +47,47 @@
 #include <stdlib.h>
 #include <errno.h>
 #include <string.h>
-#include <sys/sysmacros.h>
 #include <utime.h>
 #include <sys/ioctl.h>
 #define _LINUX_STRING_H_
+#if ! (defined(__CYGWIN__) || defined(DARWIN))
 #include <linux/fs.h>
+#endif /* !__CYGWIN__ || DARWIN */
+#ifdef DARWIN
+#define MAP_ANONYMOUS MAP_ANON
+#endif // DARWIN
 #include <linux/cramfs_fs.h>
 #include <zlib.h>

+#if defined(__CYGWIN__) || defined(DARWIN)
+#define _IOC_NRBITS	8
+#define _IOC_TYPEBITS	8
+#define _IOC_SIZEBITS	14
+#define _IOC_DIRBITS	2
+#define _IOC_NRMASK	((1 << _IOC_NRBITS)-1)
+#define _IOC_TYPEMASK	((1 << _IOC_TYPEBITS)-1)
+#define _IOC_SIZEMASK	((1 << _IOC_SIZEBITS)-1)
+#define _IOC_DIRMASK	((1 << _IOC_DIRBITS)-1)
+#define _IOC_NRSHIFT	0
+#define _IOC_TYPESHIFT	(_IOC_NRSHIFT+_IOC_NRBITS)
+#define _IOC_SIZESHIFT	(_IOC_TYPESHIFT+_IOC_TYPEBITS)
+#define _IOC_DIRSHIFT	(_IOC_SIZESHIFT+_IOC_SIZEBITS)
+#define _IOC_NONE	0U
+#define _IOC_WRITE	1U
+#define _IOC_REA	2U
+#ifndef DARWIN
+#ifndef __CYGWIN__
+#define _IOC(dir,type,nr,size) \
+        (((dir)  << _IOC_DIRSHIFT) | \
+         ((type) << _IOC_TYPESHIFT) | \
+         ((nr)   << _IOC_NRSHIFT) | \
+         ((size) << _IOC_SIZESHIFT))
+#endif // __CYGWIN__
+#define _IO(type,nr)	_IOC(_IOC_NONE,(type),(nr),0)
+#endif // DARWIN
+#define BLKGETSIZE _IO(0x12,96)
+#endif /* __CYGWIN__ || DARWIN */
+
 /* Exit codes used by fsck-type programs */
 #define FSCK_OK          0	/* No errors */
 #define FSCK_NONDESTRUCT 1	/* File system errors corrected */
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -0,0 +1,46 @@
+#-----------------------------------------------------------------------------
+# MKCRAMFS & CRAMFSCK
+#-----------------------------------------------------------------------------
+
+#-----------------------------------------------------------------------------
+# Global definitions
+#-----------------------------------------------------------------------------
+
+CMAKE_MINIMUM_REQUIRED (VERSION 2.6)
+
+PROJECT (cramfs)
+
+EXEC_PROGRAM (${CMAKE_C_COMPILER}
+              ARGS --version
+              OUTPUT_VARIABLE _gcc_COMPILER_VERSION)
+STRING (REGEX REPLACE ".* ([0-9])\\.([0-9])\\.[0-9] .*" "\\1\\2"
+        _gcc_COMPILER_VERSION ${_gcc_COMPILER_VERSION})
+
+ADD_DEFINITIONS ("-Wall -Wno-format")
+# GCC 4.x detects more issues than 3.x
+# we do not want to fix alien code, so disable the warning, however the
+# option switch we want to use is not supported in previous compiler release
+IF ( NOT ${_gcc_COMPILER_VERSION} LESS 40 )
+    ADD_DEFINITIONS ("-Wno-pointer-sign")
+ENDIF ( NOT ${_gcc_COMPILER_VERSION} LESS 40 )
+
+IF (CYGWIN)
+    ADD_DEFINITIONS ("-D__CYGWIN__")
+ENDIF (CYGWIN)
+
+IF (APPLE)
+    ADD_DEFINITIONS ("-DDARWIN")
+ENDIF(APPLE)
+
+INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR})
+
+ADD_EXECUTABLE (mkcramfs
+                mkcramfs.c)
+TARGET_LINK_LIBRARIES (mkcramfs z)
+
+ADD_EXECUTABLE (cramfsck
+                cramfsck.c)
+TARGET_LINK_LIBRARIES (cramfsck z)
+
+INSTALL (TARGETS cramfsck mkcramfs
+         RUNTIME DESTINATION bin)
+
