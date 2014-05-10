require "formula"

class PfGnuchains4xM68kElf < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf3gnuchains4x-4.6.4-20140428.tgz'
  sha1 '217c2e3f3bdb6729e1e75b1a6eb6a03a04b6bf69'

  head 'http://bitbucket.org/pizzafactory/pf3gnuchains4x.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/1.0.0-beta1"
    sha1 "86fa6bbfe6ab219820a6dfbf790db25a1afb2bcc" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    system "sh 00pizza-generate-link.sh"

    target='m68k-pizzafactory-elf'

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
                            "--without-headers",
                            "--enable-languages=c,c++",
                            "--with-bugurl=http://sourceforge.jp/projects/pf3gnuchains/ticket/",
                            "--datarootdir=#{share}/#{target}",
                            "--mandir=#{man}"
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        ohai "Building #{t}..."
        %x[make all-#{t}]
        ohai "Building #{t}...finished."
      end
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        ohai "Installing #{t}..."
        %x[make install-#{t}]
        ohai "Installing #{t}...finished."
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
    url 'https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-libs-0.0/pf-gnuchains4x-m68k-elf-lib-20140428.mavericks.bottle.tar.gz'
    sha1 'a7405d2d34a37ece86910042937e5bc98c526a56' #sha1-lib-
  end

  test do
    system "m68k-pizzafactory-elf-gcc", "--help"
  end
end
