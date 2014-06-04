require "formula"

class PfGnuchains4xMicroblazeElfLib < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.7.4-20140603.tar.gz'
  sha1 'bd9e984efd0ad018a1f63df4fdfd98bbc7294e0e'

  head 'http://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-gnuchains-libs-0.8"
    sha1 "5237298954d62e896cca6a8400a1cdc87ce99656" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool  => :build
  depends_on "pf-gnuchains4x-microblaze-elf-tools"

  def install
    ENV.j1

    target='microblaze-pizzafactory-elf'

    system "sh 00pizza-generate-link.sh"

    Dir.mkdir 'build'
    cd 'build' do
      system "../configure", "--quiet",
                            "--disable-debug",
                            "--disable-dependency-tracking",
                            "--disable-silent-rules",
                            "--prefix=#{prefix}",
                            "--target=#{target}",
                            "--disable-gdbtk",
                            "--disable-tui",
                            "--disable-rda",
                            "--enable-interwork",
                            "--enable-multilib",
                            "--with-newlib",
                            "--with-headers=`pwd`/../newlib/libc/include",
                            "--without-ppl",
                            "--without-cloog",
                            "--enable-languages=c,c++",
                            "--with-bugurl=http://sourceforge.jp/projects/pf3gnuchains/ticket/",
                            "--datarootdir=#{share}/#{target}",
                            "--mandir=#{man}",
                            "--disable-binutils",
                            "--disable-ld",
                            "--disable-gas",
                            "--disable-gdb",
                            "--disable-sim"

      [ "target-newlib", "target-libgloss", "target-libstdc++-v3" ].each do |t|
        system 'make', "all-#{t}"
      end
      [ "target-newlib", "target-libgloss", "target-libstdc++-v3" ].each do |t|
        system 'make', "install-#{t}"
      end
    end
  end
end
