require "formula"

class PfGnuchains4xMicroblazeElfTools < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.6.4-20140516.tar.gz'
  sha1 '4b14822c6afeb6c554428dec3dfc58a0f40a9dbe'

  head 'http://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-gnuchains-tools-0.10"
    sha1 "9718ea5a9a54e24d464e6e1db215e1185ca9f8fe" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    target='microblaze-pizzafactory-elf'

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
    system "microblaze-pizzafactory-elf-gcc", "--help"
  end
end
