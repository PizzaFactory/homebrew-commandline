require "formula"

class PfGnuchains4xMips64Toppershrp < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.6.4-20140512.tar.gz'
  sha1 '55efd85ba1a78c98fb65ce309ce454c8e38aec09'

  head 'https://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  patch do
    url 'https://sourceware.org/bugzilla/attachment.cgi?id=7544'
    sha1 '26b41944f6afda0a4b1aeb6c59c601a614879f68'
  end

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/1.0.0-beta1"
    sha1 "01fac630a2f95fa65df9d9088e738add071253af" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    system "sh 00pizza-generate-link.sh"

    target='mips64-pizzafactory-toppershrp'

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
    resource("libs").stage do
      cd Dir['*'][0] do
        cp_r 'share', prefix
        cp_r Dir['*-*-*'], prefix
      end
    end
  end

  resource 'libs' do
    url 'https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-libs-0.0/pf-gnuchains4x-mips64-toppershrp-lib-20140428.mavericks.bottle.tar.gz'
    sha1 '5230a707f38fc50e2a7dbb218c3b03b3afa3bf50' #sha1-lib-
  end

  test do
    system "mips64-pizzafactory-toppershrp-gcc", "--help"
  end
end
