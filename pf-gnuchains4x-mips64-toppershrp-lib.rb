require "formula"

class PfGnuchains4xMips64ToppershrpLib < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf3gnuchains4x-20140428.tgz'
  sha1 '217c2e3f3bdb6729e1e75b1a6eb6a03a04b6bf69'

  head 'http://bitbucket.org/pizzafactory/pf3gnuchains4x.git'

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool  => :build
  depends_on "pf-gnuchains4x-mips64-toppershrp-tools"

  def install
    ENV.j1

    target='mips64-pizzafactory-toppershrp'

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
                            "--without-headers",
                            "--enable-languages=c,c++",
                            "--with-bugurl=http://sourceforge.jp/projects/pf3gnuchains/ticket/",
                            "--datarootdir=#{share}/#{target}",
                            "--mandir=#{man}",
                            "--disable-binutils",
                            "--disable-ld",
                            "--disable-gas",
                            "--disable-gdb",
                            "--disable-sim"

      [ "gcc", "target-libstdc++-v3", "target-newlib", "target-libgloss" ].each do |t|
        ohai "Building #{t}..."
        %x[make all-#{t}]
        ohai "Building #{t}...finished."
      end
      [ "target-libstdc++-v3", "target-newlib", "target-libgloss" ].each do |t|
        ohai "Installing #{t}..."
        %x[make install-#{t}]
        ohai "Installing #{t}...finished."
      end
    end
  end

  test do
    system "#{target}-gcc", "--help"
  end
end
