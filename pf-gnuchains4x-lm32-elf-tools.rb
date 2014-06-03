require "formula"

class PfGnuchains4xLm32ElfTools < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.7.4-20140603.tar.gz'
  sha1 'bd9e984efd0ad018a1f63df4fdfd98bbc7294e0e'

  patch :DATA

  head 'http://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  bottle do
    root_url "https://github.com/PizzaFactory/homebrew-commandline/releases/download/release-gnuchains-tools-0.10"
    sha1 "c7c3d9bc447f9f7d43c487a1930717917d9457f6" => :mavericks
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    target='lm32-pizzafactory-elf'

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
      [ "binutils", "ld", "gas", "gcc", "target-libgcc" ].each do |t|
        system 'make', "all-#{t}"
      end
      [ "binutils", "ld", "gas", "gcc", "target-libgcc" ].each do |t|
        system 'make', "install-#{t}"
      end
    end
    man7.rmtree
    include.rmtree
  end

  test do
    system "lm32-pizzafactory-elf-gcc", "--help"
  end
end
__END__
Index: gcc/config/lm32/lm32.c
===================================================================
--- a/gcc.git/gcc/config/lm32/lm32.c	(revision 193866)
+++ b/gcc.git/gcc/config/lm32/lm32.c	(working copy)
@@ -81,7 +81,6 @@
 static void lm32_function_arg_advance (cumulative_args_t cum,
 				       enum machine_mode mode,
 				       const_tree type, bool named);
-static bool lm32_legitimate_constant_p (enum machine_mode, rtx);
 
 #undef TARGET_OPTION_OVERRIDE
 #define TARGET_OPTION_OVERRIDE lm32_option_override
@@ -109,8 +108,6 @@
 #define TARGET_CAN_ELIMINATE lm32_can_eliminate
 #undef TARGET_LEGITIMATE_ADDRESS_P
 #define TARGET_LEGITIMATE_ADDRESS_P lm32_legitimate_address_p
-#undef TARGET_LEGITIMATE_CONSTANT_P
-#define TARGET_LEGITIMATE_CONSTANT_P lm32_legitimate_constant_p
 
 struct gcc_target targetm = TARGET_INITIALIZER;
 
@@ -1230,15 +1227,3 @@
     return register_or_zero_operand (operands[1], mode);
   return true;
 }
-
-/* Implement TARGET_LEGITIMATE_CONSTANT_P.  */
-
-static bool
-lm32_legitimate_constant_p (enum machine_mode mode, rtx x)
-{
-  /* 32-bit addresses require multiple instructions.  */  
-  if (!flag_pic && reloc_operand (x, mode))
-    return false; 
-  
-  return true;
-}
Index: gcc/config/lm32/lm32.md
===================================================================
--- a/gcc.git/gcc/config/lm32/lm32.md	(revision 193866)
+++ b/gcc.git/gcc/config/lm32/lm32.md	(working copy)
@@ -293,8 +293,8 @@
 )
 
 (define_insn "movsi_insn"
-  [(set (match_operand:SI 0 "nonimmediate_operand" "=r,r,m,m,r,r,r,r,r")
-        (match_operand:SI 1 "movsi_rhs_operand" "m,r,r,J,K,L,U,S,Y"))]
+  [(set (match_operand:SI 0 "nonimmediate_operand" "=r,r,m,m,r,r,r,r,r,r")
+        (match_operand:SI 1 "general_operand" "m,r,r,J,K,L,U,S,Y,n"))]
   "lm32_move_ok (SImode, operands)"
   "@
    lw       %0, %1
@@ -305,8 +305,9 @@
    ori      %0, r0, %1
    orhi     %0, r0, hi(%1)
    mva      %0, gp(%1)
-   orhi     %0, r0, hi(%1)"
-  [(set_attr "type" "load,arith,store,store,arith,arith,arith,arith,arith")]   
+   orhi     %0, r0, hi(%1)
+   ori      %0, r0, lo(%1); orhi     %0, %0, hi(%1)"
+  [(set_attr "type" "load,arith,store,store,arith,arith,arith,arith,arith,arith")]   
 )
 
 ;; ---------------------------------
@@ -636,13 +637,32 @@
   [(set_attr "type" "uibranch")]  
 )
 
-(define_insn "return"
+(define_expand "return"
   [(return)]
   "lm32_can_use_return ()"
+  ""
+) 
+
+(define_expand "simple_return"
+  [(simple_return)]
+  ""
+  ""
+) 
+
+(define_insn "*return"
+  [(return)]
+  "reload_completed"
   "ret"
   [(set_attr "type" "uibranch")]  
 ) 
 
+(define_insn "*simple_return"
+  [(simple_return)]
+  ""
+  "ret"
+  [(set_attr "type" "uibranch")]  
+) 
+
 ;; ---------------------------------
 ;;       switch/case statements 
 ;; ---------------------------------
Index: gcc/config/lm32/predicates.md
===================================================================
--- a/gcc.git/gcc/config/lm32/predicates.md	(revision 193866)
+++ b/gcc.git/gcc/config/lm32/predicates.md	(working copy)
@@ -70,8 +70,3 @@
   (ior (match_code "symbol_ref")
        (match_operand 0 "register_operand")))
 
-(define_predicate "movsi_rhs_operand"
-  (ior (match_operand 0 "nonimmediate_operand")
-       (ior (match_code "const_int")
-            (ior (match_test "satisfies_constraint_S (op)")
-                 (match_test "satisfies_constraint_Y (op)")))))
