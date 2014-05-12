require "formula"

class PfGnuchains4xLm32Elf < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf3gnuchains4x-4.6.4-20140511.tar.gz'
  sha1 '97e76db2abcb1dc174354e43f31284b481562445'

  head 'http://bitbucket.org/pizzafactory/pf3gnuchains4x.git'

  patch do
    url 'https://sourceware.org/bugzilla/attachment.cgi?id=7544'
    sha1 '26b41944f6afda0a4b1aeb6c59c601a614879f68'
  end

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/1.0.0-beta1"
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    system "sh 00pizza-generate-link.sh"

    target='lm32-pizzafactory-elf'

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
    url 'https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-libs-0.0/pf-gnuchains4x-lm32-elf-lib-20140428.mavericks.bottle.tar.gz'
    sha1 'd10ebc724e5db44465b3ee938245101922c260c9' #sha1-lib-
  end

  test do
    system "lm32-pizzafactory-elf-gcc", "--help"
  end
end
