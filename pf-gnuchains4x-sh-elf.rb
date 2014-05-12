require "formula"

class PfGnuchains4xShElf < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf3gnuchains4x-4.6.4-20140511.tar.gz'
  sha1 '97e76db2abcb1dc174354e43f31284b481562445'

  head 'http://bitbucket.org/pizzafactory/pf3gnuchains4x.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/1.0.0-beta1"
    sha1 "6c6c3c103dc99c91d73d6a19f61e3bfa03800589" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    system "sh 00pizza-generate-link.sh"

    target='sh-pizzafactory-elf'

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
                            "--without-headers",
                            "--enable-languages=c,c++",
                            "--with-bugurl=http://sourceforge.jp/projects/pf3gnuchains/ticket/",
                            "--datarootdir=#{share}/#{target}",
                            "--mandir=#{man}",
                            "--with-multilib-list=sh2,sh4,sh4-nofpu"
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        system 'make', "all-#{t}"
      end
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        system 'make', "install-#{t}"
      end
    end
    man7.rmtree
    include.rmtree
    resource("libs").stage do
      cd Dir['*'][0] do
        cp_r 'share', prefix
        cp_r Dir['*-*-*'], prefix
      end
    end
  end

  resource 'libs' do
    url 'https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-libs-0.0/pf-gnuchains4x-sh-elf-lib-20140428.mavericks.bottle.tar.gz'
    sha1 '89f92e094cda32436ac0e5fb57db5bcff792e855' #sha1-lib-
  end

  test do
    system "sh-pizzafactory-elf-gcc", "--help"
  end
end
