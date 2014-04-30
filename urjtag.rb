require "formula"

class Urjtag < Formula
  homepage "http://urjtag.org/"
  url 'ftp://ftp.jaist.ac.jp/pub/sourceforge/u/ur/urjtag/urjtag/0.10/urjtag-0.10.tar.bz2'
  sha1 "f44e666ae484f5a7e3b50574db84df646a8d9fdb"

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/test-0.0"
    sha1 "409b805828dd440990850d9aba4bd9a658b6e4bf" => :mavericks
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
