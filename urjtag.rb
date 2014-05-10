require "formula"

class Urjtag < Formula
  homepage "http://urjtag.org/"
  url 'ftp://ftp.jaist.ac.jp/pub/sourceforge/u/ur/urjtag/urjtag/0.10/urjtag-0.10.tar.bz2'
  sha1 "f44e666ae484f5a7e3b50574db84df646a8d9fdb"

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/1.0.0-beta1"
    revision 1
    sha1 "a246341346276a69e97328c155c1e440df17241d" => :mavericks
  end

  depends_on "libusb"
  depends_on "libusb-compat"
  depends_on "libftdi"

  def install

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    system "make", "install"
  end

  test do
    system "jtag", "--version"
  end
end
