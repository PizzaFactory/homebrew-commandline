require "formula"

class PfGnuchains4xBfinElfTools < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.6.4-20140513.tar.gz'
  sha1 'c40286bf6b0c555f62334a6a15f656790cf4ddda'

  head 'http://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  patch do
    url 'https://sourceware.org/bugzilla/attachment.cgi?id=7544'
    sha1 '26b41944f6afda0a4b1aeb6c59c601a614879f68'
  end

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-tools-0.0"
    sha1 "2308943a3dc48db08e568dc10e8218a9ba64ae4f" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    target='bfin-pizzafactory-elf'

    system "sh 00pizza-generate-link.sh"

    Dir.mkdir 'build'
    cd 'build' do
      system "../configure", "--quiet", "--disable-werror",
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
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        system 'make', "all-#{t}"
      end
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        system 'make', "install-#{t}"
      end
    end
    man7.rmtree
    include.rmtree
  end

  test do
    system "bfin-pizzafactory-elf-gcc", "--help"
  end
end
