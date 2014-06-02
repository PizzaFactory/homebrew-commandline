require "formula"

class PfGnuchains4xV850ElfTools < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.6.4-20140516.tar.gz'
  sha1 '4b14822c6afeb6c554428dec3dfc58a0f40a9dbe'

  patch do
    url 'https://sourceware.org/bugzilla/attachment.cgi?id=7604'
    sha1 '0af6ab71e692c05a1a9906985030e2cad9310e0a'
  end
  patch :DATA

  head 'http://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-gnuchains-tools-0.10"
    sha1 "bf3dffd258d97993caeb4c58f075c6cc1c6b7cd8" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    target='v850-pizzafactory-elf'

    system "sh 00pizza-generate-link.sh"

    Dir.mkdir 'build'
    cd 'build' do
      system "../configure", "--disable-werror",
                            "--disable-debug",
                            "--disable-dependency-tracking",
                            "--disable-silent-rules",
                            "--prefix=#{prefix}",
                            "--target=#{target}",
                            "--disable-gdbtk",
                            "--disable-tui",
                            "--disable-rda",
                            "--enable-interwork",
                            "--enable-multilib",
                            "--with-newlib",
                            "--without-ppl",
                            "--without-cloog",
                            "--without-headers",
                            "--enable-languages=c,c++",
                            "--with-bugurl=http://sourceforge.jp/projects/pf3gnuchains/ticket/",
                            "--datarootdir=#{share}/#{target}",
                            "--mandir=#{man}"
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        system 'make', "all-#{t}"
      end
      [ "binutils", "ld", "gas", "gdb", "sim", "gcc", "target-libgcc" ].each do |t|
        system 'make', "install-#{t}"
      end
    end
    man7.rmtree
    include.rmtree
  end

  test do
    system "v850-pizzafactory-elf-gcc", "--help"
  end
end
__END__
diff --git a/gcc.git/gcc/config/v850/v850.h b/gcc.git/gcc/config/v850/v850.h
index f5b64de..fcfe9aa 100644
--- a/gcc.git/gcc/config/v850/v850.h
+++ b/gcc.git/gcc/config/v850/v850.h
@@ -89,7 +89,7 @@ extern GTY(()) rtx v850_compare_op1;
 
 #define TARGET_V850E2_ALL      (TARGET_V850E2 || TARGET_V850E2V3) 
 
-#define ASM_SPEC "%{mv850es:-mv850e1}%{!mv850es:%{mv*:-mv%*}}"
+#define ASM_SPEC "-mgcc-abi %{mv850es:-mv850e1}%{!mv850es:%{mv*:-mv%*}}"
 #define CPP_SPEC "\
   %{mv850e2v3:-D__v850e2v3__} \
   %{mv850e2:-D__v850e2__} \
