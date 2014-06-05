require "formula"

class BfinGdbproxy < Formula
  homepage "http://urjtag.org/"
  url 'https://github.com/pf3gnuchains/bfin-gdbproxy/archive/pf-gdbproxy-0.7.2.20140516.tar.gz'
  sha1 "bc5aa99c7c851326b8ccb45a9bbe7bc5ab7d4502"

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-1.0.1"
    cellar :any
    sha1 "54c2cffa4c1ad55a29d3b8584334adae006ccfc4" => :mavericks
  end

  depends_on "urjtag"
  depends_on "pkg-config" => :build

  def install

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--program-prefix=bfin-"

    system "make", "install"
  end

  test do
    system "bfin-gdbproxy", "--version"
  end
end
