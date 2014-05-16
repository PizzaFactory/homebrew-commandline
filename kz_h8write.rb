require "formula"

class KzH8write < Formula
  homepage "http://sourceforge.jp/projects/kz-h8write/"
  url 'ftp://ftp.jaist.ac.jp/pub/sourceforge.jp/kz-h8write/57645/kz_h8write-v0.2.1.zip'
  sha1 "ac9f226825ec57f33e269d7a8ed37ae79215f311"

  head 'git://git.sourceforge.jp/gitroot/kz-h8write/kz_h8write.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-1.0.0-beta2-hostfix-7"
    cellar :any
    sha1 "d8058919a59aa06f46131af0bba235fa731fd0e4" => :mavericks
  end

  def install

    cd "src" do
      system "make"
    end

    bin.install "src/kz_h8write"
    bin.install "src/motdump"
  end

  test do
    %x[kz_h8write -v]
    a = $?
    %x[motdump]
    a == 256 and $? == 256
  end
end
