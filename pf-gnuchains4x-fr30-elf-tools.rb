require "formula"

class PfGnuchains4xFr30ElfTools < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.7.4-20140603.tar.gz'
  sha1 'bd9e984efd0ad018a1f63df4fdfd98bbc7294e0e'

  head 'http://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-gnuchains-tools-0.10"
    sha1 "4d8d2711dc41c7fafc8fc8b665a8a16b62e0cc8a" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    target='fr30-pizzafactory-elf'

    system "sh 00pizza-generate-link.sh"

    Dir.mkdir 'build'
    cd 'build' do
      system "../configure", "--disable-werror",
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
                            "--without-ppl",
                            "--without-cloog",
                            "--without-headers",
                            "--enable-languages=c,c++",
                            "--with-bugurl=http://sourceforge.jp/projects/pf3gnuchains/ticket/",
                            "--datarootdir=#{share}/#{target}",
                            "--mandir=#{man}"
      [ "binutils", "ld", "gas", "gcc", "target-libgcc" ].each do |t|
        system 'make', "all-#{t}"
      end
      [ "binutils", "ld", "gas", "gcc", "target-libgcc" ].each do |t|
        system 'make', "install-#{t}"
      end
    end
    man7.rmtree
    include.rmtree
  end

  test do
    system "fr30-pizzafactory-elf-gcc", "--help"
  end
end
