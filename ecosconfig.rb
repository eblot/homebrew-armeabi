require 'formula'

class Ecosconfig < Formula
  homepage 'https://github.com/eblot/ecos'
  url 'https://github.com/eblot/ecos.git'
  version '3.10'
  sha1 ''

  def install

    ENV['CFLAGS'] = "-O2 -D__unix__"
    ENV['CXXFLAGS'] = "-O2 -D__unix__"

    build_dir='build'
    mkdir build_dir
    Dir.chdir build_dir do
      system "../host/configure", "--disable-debug",
                                  "--disable-dependency-tracking",
                                  "--disable-silent-rules",
                                  "--prefix=#{prefix}",
                                  "--with-tcl-version=8.4"
      # dirty kludge: make invoke install, which fails to create an existing
      # dir. Force it twice as this does not prevent from actually building
      # the ecosconfig tool, then perform the actual build
      system "make; true"
      system "make; true"
      system "make", "install"
    end

  end

end
