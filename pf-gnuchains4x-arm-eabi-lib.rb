require "formula"

class PfGnuchains4xArmEabiLib < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf3gnuchains4x-20140428.tgz'
  sha1 '217c2e3f3bdb6729e1e75b1a6eb6a03a04b6bf69'

  depends_on "pf-gnuchains4x-arm-eabi-tools"

  resource "tools" do
    url "file:///usr/local/Library/Taps/pizzafactory/homebrew-commandline/pf-gnuchains4x-arm-eabi-tools-20140428.mavericks.bottle.tar.gz"
    sha1 '80bf3204091b7146945cc97e29babb6f07cd0065'
  end

  resource "libs" do
    url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/test-0.0/pf-gnuchains4x-arm-eabi-20140428.any.bottle.tar.gz"
  end

  def install
    resource("libs").stage do
      cp_r "#{version}/arm-pizzafactory-eabi", prefix
    end
    resource("tools").stage do
      cp_r "#{version}/arm-pizzafactory-eabi", prefix
      cp_r "#{version}/bin", prefix
      cp_r "#{version}/lib", prefix
      cp_r "#{version}/libexec", prefix
      cp_r "#{version}/share", prefix
    end
  end

  test do
    system "#{target}-gcc", "--help"
  end
end
