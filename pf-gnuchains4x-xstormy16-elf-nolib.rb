require "formula"

class PfGnuchains4xXstormy16ElfNolib < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf3gnuchains4x-20140428.tgz'
  sha1 '217c2e3f3bdb6729e1e75b1a6eb6a03a04b6bf69'

  head 'http://bitbucket.org/pizzafactory/pf3gnuchains4x.git'

  depends_on :autoconf
  depends_on :automake
  depends_on :libtool
  depends_on "gettext"

  def install
    ENV.j1

    target='xstormy16-pizzafactory-elf'

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
  end

  test do
    system "#{target}-gcc", "--help"
  end
end