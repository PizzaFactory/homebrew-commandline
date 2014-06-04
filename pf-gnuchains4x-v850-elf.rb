require "formula"

class PfGnuchains4xV850Elf < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.7.4-20140603.tar.gz'
  sha1 'bd9e984efd0ad018a1f63df4fdfd98bbc7294e0e'

  head 'https://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  patch :DATA

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-1.0.0-hotfix-1"
    sha1 "ec02b339a0fe8fea2edd30afff959bef9c061972" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    system "sh 00pizza-generate-link.sh"

    target='v850-pizzafactory-elf'

    Dir.mkdir 'build'
    cd 'build' do
      system "../configure", "--quiet", "--disable-werror",
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
                            "--without-headers",
                            "--without-ppl",
                            "--without-cloog",
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
    resource("libs").stage do
      cd Dir['*'][0] do
        cp_r 'share', prefix
        cp_r Dir['*-*-*'], prefix
      end
    end
  end

  resource 'libs' do
    url 'https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-libs-0.8/pf-gnuchains4x-v850-elf-lib-4.7.4-20140603.mavericks.bottle.tar.gz'
    sha1 '0928334f4e7782fd6076cc421a89f08c12542d0f' #sha1-lib-
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
