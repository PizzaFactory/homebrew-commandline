require "formula"

class BfinGdbproxy < Formula
  homepage "http://urjtag.org/"
  url 'https://github.com/pf3gnuchains/bfin-gdbproxy/archive/pf-gdbproxy-0.7.2.20140611.tar.gz'
  sha1 "4f3d58634ba956afc2e4e967cadcc9695aa6a5ed"

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-1.0.1"
    cellar :any
    sha1 "764b4a0dfe7a57855887b031f4a57374ecce4dc2" => :mavericks
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
