require "formula"

class PfGnuchains4xArmElf < Formula
  homepage 'http://www.pizzafactory.jp/'

  @arch='arm'
  @vendor='pizzafactory'
  @os='elf'

  depends_on "pf-gnuchains4x-#{@arch}-#{@vendor}-nolib"
  depends_on "pf-gnuchains4x-#{@arch}-#{@vendor}-lib"

  def install
  end

  test do
    system "#{@arch}-#{@vendor}-#{@os}-gcc", "--help"
  end
end
