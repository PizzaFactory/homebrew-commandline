require "formula"

class Urjtag < Formula
  homepage "http://urjtag.org/"
  url 'https://github.com/pf3gnuchains/urjtag/archive/pf-urjtag-0.10.20140516.tar.gz'
  sha1 "b41153c2329c12edbb02e89ef6ec6a8b14f6f235"

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-1.0.0-beta2-2"
    revision 2
    sha1 "29f210df007f0cb286b4cebb207f28a4ec0cd671" => :mavericks
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
