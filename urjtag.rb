require "formula"

class Urjtag < Formula
  homepage "http://urjtag.org/"
  url 'https://github.com/pf3gnuchains/urjtag/archive/pf-urjtag-0.10.20140516.tar.gz'
  sha1 "b41153c2329c12edbb02e89ef6ec6a8b14f6f235"

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-1.0.0-beta2-hostfix-7"
    sha1 "f44d2b35dd9f8698d9c6b78d214e562869079bc9" => :mavericks
  end

  depends_on "libusb"
  depends_on "libusb-compat"
  depends_on "libftdi0"

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
