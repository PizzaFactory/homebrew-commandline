require "formula"

class PfGnuchains4xBfinElf < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf3gnuchains4x/downloads/pf-gnuchains4x-dummy-4.6.4-20140428.tar.gz'
  sha1 '731f28d55048172fa607670844d5d24fad42751d'

  resource "tools" do
    url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-tools-0.0/pf-gnuchains4x-bfin-elf-tools-4.6.4-20140428.mavericks.bottle.tar.gz"
    sha1 "2308943a3dc48db08e568dc10e8218a9ba64ae4f"
  end

#  resource "libs" do
#    url ""
#  end

  def install
#    resource("libs").stage do
#      cp_r "#{version}/bfin-pizzafactory-elf", prefix
#    end
    resource("tools").stage do
      cp_r "#{version}/bfin-pizzafactory-elf", prefix
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
