require "formula"

class PfGnuchains4xNios2Elf < Formula
  homepage 'http://www.pizzafactory.jp/'
  url 'https://bitbucket.org/pizzafactory/pf-binutils-gdb/downloads/pf-binutils-gdb-4.6.4-20140516.tar.gz'
  sha1 '4b14822c6afeb6c554428dec3dfc58a0f40a9dbe'

  head 'https://bitbucket.org/pizzafactory/pf-binutils-gdb.git'

  patch :DATA

  bottle do
  end

  depends_on :autoconf => :build
  depends_on :automake => :build
  depends_on :libtool => :build

  def install
    ENV.j1

    target='nios2-pizzafactory-elf'

    system "sh 00pizza-generate-link.sh"

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
    url 'https://github.com/PizzaFactory/homebrew-commandline/releases/download/gnuchains-libs-0.0/pf-gnuchains4x-nios2-elf-lib-20140428.mavericks.bottle.tar.gz'
    sha1 '56c9b86e9b9d5dd1bee62f4f38ff5ff3c4697f7b' #sha1-lib-
  end

  test do
    system "nios2-pizzafactory-elf-gcc", "--help"
  end
end
__END__
diff --git a/gcc/common/config/nios2/nios2-common.c b/gcc/common/config/nios2/nios2-common.c
new file mode 100644
index 0000000..d3831f7
--- /dev/null
+++ b/gcc/common/config/nios2/nios2-common.c
@@ -0,0 +1,45 @@
+/* Common hooks for Altera Nios II.
+   Copyright (C) 2012
+   Free Software Foundation, Inc.
+
+This file is part of GCC.
+
+GCC is free software; you can redistribute it and/or modify
+it under the terms of the GNU General Public License as published by
+the Free Software Foundation; either version 3, or (at your option)
+any later version.
+
+GCC is distributed in the hope that it will be useful,
+but WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+GNU General Public License for more details.
+
+You should have received a copy of the GNU General Public License
+along with GCC; see the file COPYING3.  If not see
+<http://www.gnu.org/licenses/>.  */
+
+#include "config.h"
+#include "system.h"
+#include "coretypes.h"
+#include "diagnostic-core.h"
+#include "tm.h"
+#include "common/common-target.h"
+#include "common/common-target-def.h"
+#include "opts.h"
+#include "flags.h"
+
+/* Implement TARGET_OPTION_OPTIMIZATION_TABLE.  */
+static const struct default_options nios2_option_optimization_table[] =
+  {
+    { OPT_LEVELS_1_PLUS, OPT_fomit_frame_pointer, NULL, 1 },
+    { OPT_LEVELS_3_PLUS, OPT_mfast_sw_div, NULL, 1 },
+    { OPT_LEVELS_NONE, 0, NULL, 0 }
+  };
+
+#undef TARGET_DEFAULT_TARGET_FLAGS
+#define TARGET_DEFAULT_TARGET_FLAGS TARGET_DEFAULT
+
+#undef TARGET_OPTION_OPTIMIZATION_TABLE
+#define TARGET_OPTION_OPTIMIZATION_TABLE nios2_option_optimization_table
+
+struct gcc_targetm_common targetm_common = TARGETM_COMMON_INITIALIZER;
diff --git a/gcc/config.gcc b/gcc/config.gcc
index 9f70998..5380f88 100644
--- a/gcc/config.gcc
+++ b/gcc/config.gcc
@@ -413,6 +413,10 @@ mips*-*-*)
 	extra_headers="loongson.h"
 	extra_options="${extra_options} g.opt mips/mips-tables.opt"
 	;;
+nios2-*-*)
+	cpu_type=nios2
+	extra_options="${extra_options} g.opt"
+	;;	
 picochip-*-*)
         cpu_type=picochip
         ;;
@@ -1950,6 +1954,19 @@ mn10300-*-*)
 	use_collect2=no
 	use_gcc_stdint=wrap
 	;;
+nios2-*-*)
+	tm_file="elfos.h ${tm_file}"
+        tmake_file="${tmake_file} nios2/t-nios2"
+        case ${target} in
+        nios2-*-linux*)
+                tm_file="${tm_file} gnu-user.h linux.h glibc-stdint.h nios2/linux.h "
+                ;;
+	nios2-*-elf*)
+		tm_file="${tm_file} newlib-stdint.h nios2/elf.h"
+		extra_options="${extra_options} nios2/elf.opt"
+		;;
+        esac
+	;;
 pdp11-*-*)
 	tm_file="${tm_file} newlib-stdint.h"
 	use_gcc_stdint=wrap
diff --git a/gcc/config/nios2/constraints.md b/gcc/config/nios2/constraints.md
new file mode 100644
index 0000000..45c37d2
--- /dev/null
+++ b/gcc/config/nios2/constraints.md
@@ -0,0 +1,120 @@
+;; Constraint definitions for Altera Nios II.
+;; Copyright (C) 2012 Free Software Foundation, Inc.
+;; Contributed by Chung-Lin Tang <cltang@codesourcery.com>
+;;
+;; This file is part of GCC.
+;;
+;; GCC is free software; you can redistribute it and/or modify
+;; it under the terms of the GNU General Public License as published by
+;; the Free Software Foundation; either version 3, or (at your option)
+;; any later version.
+;;
+;; GCC is distributed in the hope that it will be useful,
+;; but WITHOUT ANY WARRANTY; without even the implied warranty of
+;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+;; GNU General Public License for more details.
+;;
+;; You should have received a copy of the GNU General Public License
+;; along with GCC; see the file COPYING3.  If not see
+;; <http://www.gnu.org/licenses/>.
+
+;; We use the following constraint letters for constants
+;;
+;;  I: -32768 to -32767
+;;  J: 0 to 65535
+;;  K: $nnnn0000 for some nnnn
+;;  L: 0 to 31 (for shift counts)
+;;  M: 0
+;;  N: 0 to 255 (for custom instruction numbers)
+;;  O: 0 to 31 (for control register numbers)
+;;
+;; We use the following built-in register classes:
+;;
+;;  r: general purpose register (r0..r31)
+;;  m: memory operand
+;;
+;; Plus, we define the following constraint strings:
+;;
+;;  S: symbol that is in the "small data" area
+;;  Dnn: Dnn_REG (just rnn)
+
+;; Register constraints
+
+(define_register_constraint "j" "SIB_REGS"
+  "A register suitable for an indirect sibcall.")
+
+;; These are documented for use in inline asm.
+(define_register_constraint "D00" "D00_REG" "Hard register 0.")
+(define_register_constraint "D01" "D01_REG" "Hard register 1.")
+(define_register_constraint "D02" "D02_REG" "Hard register 2.")
+(define_register_constraint "D03" "D03_REG" "Hard register 3.")
+(define_register_constraint "D04" "D04_REG" "Hard register 4.")
+(define_register_constraint "D05" "D05_REG" "Hard register 5.")
+(define_register_constraint "D06" "D06_REG" "Hard register 6.")
+(define_register_constraint "D07" "D07_REG" "Hard register 7.")
+(define_register_constraint "D08" "D08_REG" "Hard register 8.")
+(define_register_constraint "D09" "D09_REG" "Hard register 9.")
+(define_register_constraint "D10" "D10_REG" "Hard register 10.")
+(define_register_constraint "D11" "D11_REG" "Hard register 11.")
+(define_register_constraint "D12" "D12_REG" "Hard register 12.")
+(define_register_constraint "D13" "D13_REG" "Hard register 13.")
+(define_register_constraint "D14" "D14_REG" "Hard register 14.")
+(define_register_constraint "D15" "D15_REG" "Hard register 15.")
+(define_register_constraint "D16" "D16_REG" "Hard register 16.")
+(define_register_constraint "D17" "D17_REG" "Hard register 17.")
+(define_register_constraint "D18" "D18_REG" "Hard register 18.")
+(define_register_constraint "D19" "D19_REG" "Hard register 19.")
+(define_register_constraint "D20" "D20_REG" "Hard register 20.")
+(define_register_constraint "D21" "D21_REG" "Hard register 21.")
+(define_register_constraint "D22" "D22_REG" "Hard register 22.")
+(define_register_constraint "D23" "D23_REG" "Hard register 23.")
+(define_register_constraint "D24" "D24_REG" "Hard register 24.")
+(define_register_constraint "D25" "D25_REG" "Hard register 25.")
+(define_register_constraint "D26" "D26_REG" "Hard register 26.")
+(define_register_constraint "D27" "D27_REG" "Hard register 27.")
+(define_register_constraint "D28" "D28_REG" "Hard register 28.")
+(define_register_constraint "D29" "D29_REG" "Hard register 29.")
+(define_register_constraint "D30" "D30_REG" "Hard register 30.")
+(define_register_constraint "D31" "D31_REG" "Hard register 31.")
+
+;; Integer constraints
+
+(define_constraint "I"
+  "A signed 16-bit constant (for arithmetic instructions)."
+  (and (match_code "const_int")
+       (match_test "SMALL_INT (ival)")))
+
+(define_constraint "J"
+  "An unsigned 16-bit constant (for logical instructions)."
+  (and (match_code "const_int")
+       (match_test "SMALL_INT_UNSIGNED (ival)")))
+
+(define_constraint "K"
+  "An unsigned 16-bit high constant (for logical instructions)."
+  (and (match_code "const_int")
+       (match_test "UPPER16_INT (ival)")))
+
+(define_constraint "L"
+  "An unsigned 5-bit constant (for shift counts)."
+  (and (match_code "const_int")
+       (match_test "ival >= 0 && ival <= 31")))
+
+(define_constraint "M"
+  "Integer zero."
+  (and (match_code "const_int")
+       (match_test "ival == 0")))
+
+(define_constraint "N"
+  "An unsigned 8-bit constant (for custom instruction codes)."
+  (and (match_code "const_int")
+       (match_test "ival >= 0 && ival <= 255")))
+
+(define_constraint "O"
+  "An unsigned 5-bit constant (for control register numbers)."
+  (and (match_code "const_int")
+       (match_test "ival >= 0 && ival <= 31")))
+
+(define_constraint "S"
+  "An immediate stored in small data, accessible by GP."
+  (and (match_code "symbol_ref")
+       (match_test "SYMBOL_REF_IN_NIOS2_SMALL_DATA_P (op)")))
diff --git a/gcc/config/nios2/elf.h b/gcc/config/nios2/elf.h
new file mode 100644
index 0000000..30229e5
--- /dev/null
+++ b/gcc/config/nios2/elf.h
@@ -0,0 +1,52 @@
+/* Definitions of ELF target support for Altera Nios II.
+   Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Jonah Graham (jgraham@altera.com), 
+   Will Reece (wreece@altera.com), and Jeff DaSilva (jdasilva@altera.com).
+   Contributed by Mentor Graphics, Inc.
+
+   This file is part of GCC.
+
+   GCC is free software; you can redistribute it and/or modify it
+   under the terms of the GNU General Public License as published
+   by the Free Software Foundation; either version 3, or (at your
+   option) any later version.
+
+   GCC is distributed in the hope that it will be useful, but WITHOUT
+   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
+   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
+   License for more details.
+
+   You should have received a copy of the GNU General Public License
+   along with GCC; see the file COPYING3.  If not see
+   <http://www.gnu.org/licenses/>.  */
+
+
+/* Specs to support the additional command-line options for Nios II ELF
+   toolchains.  */
+
+/* -msmallc chooses an alternate C library.
+   -msys-lib= specifies an additional low-level system/hosting library and
+   is typically used to suck in a library provided by a HAL BSP.  */
+#undef LIB_SPEC
+#define LIB_SPEC \
+"--start-group %{msmallc: -lsmallc} %{!msmallc: -lc} -lgcc \
+ %{msys-lib=*: -l%*} \
+ --end-group \
+"
+
+/* Linking with -mhal suppresses inclusion of the GCC-provided crt* begin/end
+   code.  Normally in this case you also link with -msys-crt0= to specify
+   the startup code provided by the HAL BSP instead.  */
+#undef STARTFILE_SPEC
+#define STARTFILE_SPEC						\
+  "%{mhal:"							\
+  "%{msys-crt0=*:%*} %{!msys-crt0=*:crt0%O%s} "			\
+  "%{msys-crt0=:%eYou need a C startup file for -msys-crt0=};"	\
+  ":crti%O%s crtbegin%O%s}"
+
+#undef  ENDFILE_SPEC
+#define ENDFILE_SPEC "%{!mhal:crtend%O%s crtn%O%s}"
+
+/* The ELF target doesn't support the Nios II Linux ABI.  */
+#define TARGET_LINUX_ABI 0
+
diff --git a/gcc/config/nios2/elf.opt b/gcc/config/nios2/elf.opt
new file mode 100644
index 0000000..e9555c2
--- /dev/null
+++ b/gcc/config/nios2/elf.opt
@@ -0,0 +1,38 @@
+; Options for the Altera Nios II port of the compiler.
+; Copyright (C) 2012 Free Software Foundation, Inc.
+; Contributed by Altera and Mentor Graphics, Inc.
+;
+; This file is part of GCC.
+;
+; GCC is free software; you can redistribute it and/or modify
+; it under the terms of the GNU General Public License as published by
+; the Free Software Foundation; either version 3, or (at your option)
+; any later version.
+;
+; GCC is distributed in the hope that it will be useful,
+; but WITHOUT ANY WARRANTY; without even the implied warranty of
+; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+; GNU General Public License for more details.
+;
+; You should have received a copy of the GNU General Public License
+; along with GCC; see the file COPYING3.  If not see
+; <http://www.gnu.org/licenses/>.
+
+; These additional options are supported for ELF (bare-metal) Nios II
+; toolchains.
+
+msmallc
+Target Report RejectNegative
+Link with a limited version of the C library
+
+msys-lib=
+Target RejectNegative Joined Var(nios2_sys_lib_string)
+Name of system library to link against
+
+msys-crt0=
+Target RejectNegative Joined Var(nios2_sys_crt0_string)
+Name of the startfile
+
+mhal
+Target Report RejectNegative
+Link with HAL BSP
diff --git a/gcc/config/nios2/linux.h b/gcc/config/nios2/linux.h
new file mode 100644
index 0000000..feb9d66
--- /dev/null
+++ b/gcc/config/nios2/linux.h
@@ -0,0 +1,55 @@
+/* Definitions of target support for Altera Nios II systems
+   running GNU/Linux with ELF format.
+   Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Mentor Graphics, Inc.
+
+   This file is part of GCC.
+
+   GCC is free software; you can redistribute it and/or modify it
+   under the terms of the GNU General Public License as published
+   by the Free Software Foundation; either version 3, or (at your
+   option) any later version.
+
+   GCC is distributed in the hope that it will be useful, but WITHOUT
+   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
+   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
+   License for more details.
+
+   You should have received a copy of the GNU General Public License
+   along with GCC; see the file COPYING3.  If not see
+   <http://www.gnu.org/licenses/>.  */
+
+#undef LIB_SPEC
+#define LIB_SPEC "-lc \
+ %{pthread:-lpthread}"
+
+#undef STARTFILE_SPEC
+#define STARTFILE_SPEC \
+"%{!shared: crt1.o%s} \
+ crti.o%s %{static:crtbeginT.o%s;shared|pie:crtbeginS.o%s;:crtbegin.o%s}"
+
+#undef ENDFILE_SPEC
+#define ENDFILE_SPEC \
+"%{shared|pie:crtendS.o%s;:crtend.o%s} crtn.o%s"
+
+#define TARGET_OS_CPP_BUILTINS()                \
+  do                                            \
+    {                                           \
+      GNU_USER_TARGET_OS_CPP_BUILTINS();           \
+    }                                           \
+  while (0)
+
+#undef SYSROOT_SUFFIX_SPEC
+#define SYSROOT_SUFFIX_SPEC \
+  "%{EB:/EB}"
+
+#undef LINK_SPEC
+#define LINK_SPEC LINK_SPEC_ENDIAN \
+  " %{shared:-shared} \
+    %{static:-Bstatic} \
+    %{rdynamic:-export-dynamic}"
+
+/* This toolchain implements the ABI for Linux Systems documented in the
+   Nios II Processor Reference Handbook.  */
+#define TARGET_LINUX_ABI 1
+
diff --git a/gcc/config/nios2/nios2-opts.h b/gcc/config/nios2/nios2-opts.h
new file mode 100644
index 0000000..640833b
--- /dev/null
+++ b/gcc/config/nios2/nios2-opts.h
@@ -0,0 +1,70 @@
+/* Definitions for option handling for Nios II.
+   Copyright (C) 2013
+   Free Software Foundation, Inc.
+
+This file is part of GCC.
+
+GCC is free software; you can redistribute it and/or modify
+it under the terms of the GNU General Public License as published by
+the Free Software Foundation; either version 3, or (at your option)
+any later version.
+
+GCC is distributed in the hope that it will be useful,
+but WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+GNU General Public License for more details.
+
+You should have received a copy of the GNU General Public License
+along with GCC; see the file COPYING3.  If not see
+<http://www.gnu.org/licenses/>.  */
+
+#ifndef NIOS2_OPTS_H
+#define NIOS2_OPTS_H
+
+/* Enumeration of all FPU insn codes.  */
+#define N2FPU_ALL_CODES							\
+  N2FPU_CODE(fadds) N2FPU_CODE(fsubs) N2FPU_CODE(fmuls) N2FPU_CODE(fdivs) \
+  N2FPU_CODE(fmins) N2FPU_CODE(fmaxs)					\
+  N2FPU_CODE(fnegs) N2FPU_CODE(fabss) N2FPU_CODE(fsqrts)		\
+  N2FPU_CODE(fsins) N2FPU_CODE(fcoss) N2FPU_CODE(ftans) N2FPU_CODE(fatans) \
+  N2FPU_CODE(fexps) N2FPU_CODE(flogs)					\
+  N2FPU_CODE(fcmpeqs) N2FPU_CODE(fcmpnes)				\
+  N2FPU_CODE(fcmplts) N2FPU_CODE(fcmples)				\
+  N2FPU_CODE(fcmpgts) N2FPU_CODE(fcmpges)				\
+  									\
+  N2FPU_CODE(faddd) N2FPU_CODE(fsubd) N2FPU_CODE(fmuld) N2FPU_CODE(fdivd) \
+  N2FPU_CODE(fmind) N2FPU_CODE(fmaxd)					\
+  N2FPU_CODE(fnegd) N2FPU_CODE(fabsd) N2FPU_CODE(fsqrtd)		\
+  N2FPU_CODE(fsind) N2FPU_CODE(fcosd) N2FPU_CODE(ftand) N2FPU_CODE(fatand) \
+  N2FPU_CODE(fexpd) N2FPU_CODE(flogd)					\
+  N2FPU_CODE(fcmpeqd) N2FPU_CODE(fcmpned)				\
+  N2FPU_CODE(fcmpltd) N2FPU_CODE(fcmpled)				\
+  N2FPU_CODE(fcmpgtd) N2FPU_CODE(fcmpged)				\
+  									\
+  N2FPU_CODE(floatis) N2FPU_CODE(floatus)				\
+  N2FPU_CODE(floatid) N2FPU_CODE(floatud)				\
+  N2FPU_CODE(fixsi) N2FPU_CODE(fixsu)					\
+  N2FPU_CODE(fixdi) N2FPU_CODE(fixdu)					\
+  N2FPU_CODE(fextsd) N2FPU_CODE(ftruncds)				\
+									\
+  N2FPU_CODE(fwrx) N2FPU_CODE(fwry)					\
+  N2FPU_CODE(frdxlo) N2FPU_CODE(frdxhi) N2FPU_CODE(frdy)
+
+enum n2fpu_code {
+#define N2FPU_CODE(name) n2fpu_ ## name,
+  N2FPU_ALL_CODES
+#undef N2FPU_CODE
+  n2fpu_code_num
+};
+
+/* An enumeration to indicate the custom code status; if values within 0--255
+   are registered to an FPU insn, or custom insn.  */
+enum nios2_ccs_code
+{
+  CCS_UNUSED,
+  CCS_FPU,
+  CCS_BUILTIN_CALL
+};
+
+#endif
+
diff --git a/gcc/config/nios2/nios2-protos.h b/gcc/config/nios2/nios2-protos.h
new file mode 100644
index 0000000..f0e4560
--- /dev/null
+++ b/gcc/config/nios2/nios2-protos.h
@@ -0,0 +1,59 @@
+/* Subroutine declarations for Altera Nios II target support.
+   Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Jonah Graham (jgraham@altera.com).
+   Contributed by Mentor Graphics, Inc.
+
+   This file is part of GCC.
+
+   GCC is free software; you can redistribute it and/or modify it
+   under the terms of the GNU General Public License as published
+   by the Free Software Foundation; either version 3, or (at your
+   option) any later version.
+
+   GCC is distributed in the hope that it will be useful, but WITHOUT
+   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
+   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
+   License for more details.
+
+   You should have received a copy of the GNU General Public License
+   along with GCC; see the file COPYING3.  If not see
+   <http://www.gnu.org/licenses/>.  */
+
+#ifndef GCC_NIOS2_PROTOS_H
+#define GCC_NIOS2_PROTOS_H
+
+extern int nios2_initial_elimination_offset (int, int);
+extern int nios2_can_use_return_insn (void);
+extern void expand_prologue (void);
+extern void expand_epilogue (bool);
+extern void nios2_function_profiler (FILE *, int);
+
+#ifdef RTX_CODE
+extern int nios2_emit_move_sequence (rtx *, enum machine_mode);
+extern int nios2_emit_expensive_div (rtx *, enum machine_mode);
+extern void nios2_adjust_call_address (rtx *);
+
+extern rtx nios2_get_return_address (int);
+extern void nios2_set_return_address (rtx, rtx);
+
+extern bool nios2_supported_compare_p (enum machine_mode);
+extern bool nios2_validate_compare (enum machine_mode, rtx*, rtx*, rtx*);
+
+extern bool nios2_fpu_insn_enabled (enum n2fpu_code);
+extern const char* nios2_fpu_insn_asm (enum n2fpu_code);
+
+extern bool nios2_legitimate_pic_operand_p (rtx x);
+
+#ifdef TREE_CODE
+#ifdef ARGS_SIZE_RTX
+/* expr.h defines both ARGS_SIZE_RTX and `enum direction' */
+extern enum direction nios2_function_arg_padding (enum machine_mode, const_tree);
+extern enum direction nios2_block_reg_padding (enum machine_mode, tree, int);
+#endif /* ARGS_SIZE_RTX */
+
+extern void nios2_init_cumulative_args (CUMULATIVE_ARGS *, tree, rtx, tree, int);
+
+#endif /* TREE_CODE */
+#endif /* RTX_CODE */
+
+#endif /* GCC_NIOS2_PROTOS_H */
diff --git a/gcc/config/nios2/nios2.c b/gcc/config/nios2/nios2.c
new file mode 100644
index 0000000..c6434a8
--- /dev/null
+++ b/gcc/config/nios2/nios2.c
@@ -0,0 +1,3250 @@
+/* Target machine subroutines for Altera Nios II.
+   Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Jonah Graham (jgraham@altera.com), 
+   Will Reece (wreece@altera.com), and Jeff DaSilva (jdasilva@altera.com).
+   Contributed by Mentor Graphics, Inc.
+
+   This file is part of GCC.
+
+   GCC is free software; you can redistribute it and/or modify it
+   under the terms of the GNU General Public License as published
+   by the Free Software Foundation; either version 3, or (at your
+   option) any later version.
+
+   GCC is distributed in the hope that it will be useful, but WITHOUT
+   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
+   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
+   License for more details.
+
+   You should have received a copy of the GNU General Public License
+   along with GCC; see the file COPYING3.  If not see
+   <http://www.gnu.org/licenses/>.  */
+
+#include <stdio.h>
+#include "config.h"
+#include "system.h"
+#include "coretypes.h"
+#include "tm.h"
+#include "rtl.h"
+#include "tree.h"
+#include "regs.h"
+#include "hard-reg-set.h"
+#include "insn-config.h"
+#include "conditions.h"
+#include "output.h"
+#include "insn-attr.h"
+#include "flags.h"
+#include "recog.h"
+#include "expr.h"
+#include "optabs.h"
+#include "function.h"
+#include "ggc.h"
+#include "basic-block.h"
+#include "diagnostic-core.h"
+#include "toplev.h"
+#include "target.h"
+#include "target-def.h"
+#include "tm_p.h"
+#include "langhooks.h"
+#include "df.h"
+#include "debug.h"
+#include "real.h"
+#include "integrate.h"
+#include "reload.h"
+
+/* Local prototypes.  */
+static bool nios2_rtx_costs (rtx, int, int, int, int *, bool);
+static reg_class_t nios2_preferred_reload_class (rtx, reg_class_t);
+static void nios2_print_operand (FILE *, rtx, int);
+static void nios2_print_operand_address (FILE *, rtx);
+static void nios2_asm_function_prologue (FILE *, HOST_WIDE_INT);
+static int nios2_issue_rate (void);
+static struct machine_function *nios2_init_machine_status (void);
+static bool nios2_in_small_data_p (const_tree);
+static void dump_frame_size (FILE *);
+static HOST_WIDE_INT compute_frame_size (void);
+static void save_reg (int, unsigned);
+static void restore_reg (int, unsigned);
+static unsigned int nios2_section_type_flags (tree, const char *, int);
+static bool nios2_can_eliminate (const int, const int);
+static void nios2_load_pic_register (void);
+static bool nios2_cannot_force_const_mem (enum machine_mode, rtx);
+static rtx nios2_legitimize_pic_address (rtx orig, enum machine_mode mode,
+					 rtx reg);
+static bool nios2_legitimate_constant_p (enum machine_mode, rtx);
+static rtx nios2_legitimize_address (rtx x, rtx orig_x, enum machine_mode mode);
+static bool nios2_legitimate_address_p (enum machine_mode mode, rtx, bool);
+static void nios2_init_builtins (void);
+static rtx nios2_expand_builtin (tree, rtx, rtx, enum machine_mode, int);
+static void nios2_init_libfuncs (void);
+static rtx nios2_function_arg (cumulative_args_t, enum machine_mode,
+			       const_tree, bool);
+static void nios2_function_arg_advance (cumulative_args_t, enum machine_mode,
+					const_tree, bool);
+static void nios2_setup_incoming_varargs (cumulative_args_t, enum machine_mode, 
+					  tree, int *, int);
+static int nios2_arg_partial_bytes (cumulative_args_t,
+				    enum machine_mode, tree, bool);
+static void nios2_trampoline_init (rtx, tree, rtx);
+static rtx nios2_function_value (const_tree, const_tree, bool);
+static rtx nios2_libcall_value (enum machine_mode, const_rtx);
+static bool nios2_function_value_regno_p (const unsigned int);
+static bool nios2_return_in_memory (const_tree, const_tree);
+static void nios2_encode_section_info (tree, rtx, int);
+static void nios2_output_dwarf_dtprel (FILE *fuke, int size, rtx x);
+static void nios2_option_override (void);
+static void nios2_option_save (struct cl_target_option*);
+static void nios2_option_restore (struct cl_target_option*);
+static void nios2_set_current_function (tree);
+static bool nios2_valid_target_attribute_p (tree, tree, tree, int);
+static bool nios2_pragma_target_parse (tree, tree);
+static tree nios2_merge_decl_attributes (tree, tree);
+static void nios2_custom_check_insns (void);
+static void nios2_handle_custom_fpu_cfg (const char*, bool);
+static void nios2_handle_custom_fpu_insn_option (int);
+static void nios2_register_custom_code (unsigned int, enum nios2_ccs_code, int);
+static void nios2_deregister_custom_code (unsigned int);
+
+/* Initialize the GCC target structure.  */
+#undef TARGET_ASM_FUNCTION_PROLOGUE
+#define TARGET_ASM_FUNCTION_PROLOGUE nios2_asm_function_prologue
+
+#undef TARGET_SCHED_ISSUE_RATE
+#define TARGET_SCHED_ISSUE_RATE nios2_issue_rate
+#undef TARGET_IN_SMALL_DATA_P
+#define TARGET_IN_SMALL_DATA_P nios2_in_small_data_p
+#undef  TARGET_ENCODE_SECTION_INFO
+#define TARGET_ENCODE_SECTION_INFO nios2_encode_section_info
+#undef  TARGET_SECTION_TYPE_FLAGS
+#define TARGET_SECTION_TYPE_FLAGS  nios2_section_type_flags
+
+#undef TARGET_INIT_BUILTINS
+#define TARGET_INIT_BUILTINS nios2_init_builtins
+#undef TARGET_EXPAND_BUILTIN
+#define TARGET_EXPAND_BUILTIN nios2_expand_builtin
+
+#undef TARGET_INIT_LIBFUNCS
+#define TARGET_INIT_LIBFUNCS nios2_init_libfuncs
+
+#undef TARGET_FUNCTION_OK_FOR_SIBCALL
+#define TARGET_FUNCTION_OK_FOR_SIBCALL hook_bool_tree_tree_true
+
+#undef TARGET_CAN_ELIMINATE
+#define TARGET_CAN_ELIMINATE nios2_can_eliminate
+
+#undef TARGET_FUNCTION_ARG
+#define TARGET_FUNCTION_ARG nios2_function_arg
+
+#undef TARGET_FUNCTION_ARG_ADVANCE
+#define TARGET_FUNCTION_ARG_ADVANCE nios2_function_arg_advance
+
+#undef TARGET_ARG_PARTIAL_BYTES
+#define TARGET_ARG_PARTIAL_BYTES nios2_arg_partial_bytes
+
+#undef TARGET_TRAMPOLINE_INIT
+#define TARGET_TRAMPOLINE_INIT nios2_trampoline_init
+
+#undef TARGET_FUNCTION_VALUE
+#define TARGET_FUNCTION_VALUE nios2_function_value
+
+#undef TARGET_LIBCALL_VALUE
+#define TARGET_LIBCALL_VALUE nios2_libcall_value
+
+#undef TARGET_FUNCTION_VALUE_REGNO_P
+#define TARGET_FUNCTION_VALUE_REGNO_P nios2_function_value_regno_p
+
+#undef TARGET_RETURN_IN_MEMORY
+#define TARGET_RETURN_IN_MEMORY nios2_return_in_memory
+
+#undef TARGET_PROMOTE_PROTOTYPES
+#define TARGET_PROMOTE_PROTOTYPES hook_bool_const_tree_true
+
+#undef TARGET_SETUP_INCOMING_VARARGS
+#define TARGET_SETUP_INCOMING_VARARGS nios2_setup_incoming_varargs
+
+#undef TARGET_MUST_PASS_IN_STACK
+#define TARGET_MUST_PASS_IN_STACK must_pass_in_stack_var_size
+
+#undef TARGET_LEGITIMATE_CONSTANT_P
+#define TARGET_LEGITIMATE_CONSTANT_P nios2_legitimate_constant_p
+
+#undef TARGET_LEGITIMIZE_ADDRESS
+#define TARGET_LEGITIMIZE_ADDRESS nios2_legitimize_address
+
+#undef TARGET_LEGITIMATE_ADDRESS_P
+#define TARGET_LEGITIMATE_ADDRESS_P nios2_legitimate_address_p
+
+#undef TARGET_PREFERRED_RELOAD_CLASS
+#define TARGET_PREFERRED_RELOAD_CLASS nios2_preferred_reload_class
+
+#undef TARGET_RTX_COSTS
+#define TARGET_RTX_COSTS nios2_rtx_costs
+
+#undef TARGET_HAVE_TLS
+#define TARGET_HAVE_TLS TARGET_LINUX_ABI
+
+#undef TARGET_CANNOT_FORCE_CONST_MEM
+#define TARGET_CANNOT_FORCE_CONST_MEM nios2_cannot_force_const_mem
+
+#undef TARGET_ASM_OUTPUT_DWARF_DTPREL
+#define TARGET_ASM_OUTPUT_DWARF_DTPREL nios2_output_dwarf_dtprel
+
+#undef TARGET_PRINT_OPERAND
+#define TARGET_PRINT_OPERAND nios2_print_operand
+
+#undef TARGET_PRINT_OPERAND_ADDRESS
+#define TARGET_PRINT_OPERAND_ADDRESS nios2_print_operand_address
+
+#undef TARGET_OPTION_OVERRIDE
+#define TARGET_OPTION_OVERRIDE nios2_option_override
+
+#undef TARGET_OPTION_SAVE
+#define TARGET_OPTION_SAVE nios2_option_save
+
+#undef TARGET_OPTION_RESTORE
+#define TARGET_OPTION_RESTORE nios2_option_restore
+
+#undef TARGET_SET_CURRENT_FUNCTION
+#define TARGET_SET_CURRENT_FUNCTION nios2_set_current_function
+
+#undef TARGET_OPTION_VALID_ATTRIBUTE_P
+#define TARGET_OPTION_VALID_ATTRIBUTE_P nios2_valid_target_attribute_p
+
+#undef TARGET_OPTION_PRAGMA_PARSE
+#define TARGET_OPTION_PRAGMA_PARSE nios2_pragma_target_parse
+
+#undef TARGET_MERGE_DECL_ATTRIBUTES
+#define TARGET_MERGE_DECL_ATTRIBUTES nios2_merge_decl_attributes
+
+/* ??? Might want to redefine TARGET_RETURN_IN_MSB here to handle
+   big-endian case; depends on what ABI we choose.  */
+
+struct gcc_target targetm = TARGET_INITIALIZER;
+
+
+/* Threshold for data being put into the small data/bss area, instead
+   of the normal data area (references to the small data/bss area take
+   1 instruction, and use the global pointer, references to the normal
+   data area takes 2 instructions).  */
+unsigned HOST_WIDE_INT nios2_section_threshold = NIOS2_DEFAULT_GVALUE;
+
+struct GTY (()) machine_function
+{
+  /* Current frame information, to be filled in by compute_frame_size
+     with register save masks, and offsets for the current function.  */
+
+  unsigned HOST_WIDE_INT save_mask; /* Mask of registers to save.  */
+  long total_size;       /* # bytes that the entire frame takes up.  */
+  long var_size;         /* # bytes that variables take up.  */
+  long args_size;        /* # bytes that outgoing arguments take up.  */
+  int save_reg_size;     /* # bytes needed to store gp regs.  */
+  long save_regs_offset; /* Offset from new sp to store gp registers.  */
+  int initialized;       /* != 0 if frame size already calculated.  */
+};
+
+/* State to track the assignment of custom codes to FPU/custom builtins.  */
+static enum nios2_ccs_code custom_code_status[256];
+static int custom_code_index[256];
+/* Set to true if any conflicts (re-use of a code between 0-255) are found.  */
+static bool custom_code_conflict = false;
+
+
+
+/* Definition of builtin function types for nios2.  */
+
+#define N2_FTYPES				\
+  N2_FTYPE(1, (SF))				\
+  N2_FTYPE(1, (VOID))				\
+  N2_FTYPE(2, (DF, DF))				\
+  N2_FTYPE(3, (DF, DF, DF))			\
+  N2_FTYPE(2, (DF, SF))				\
+  N2_FTYPE(2, (DF, SI))				\
+  N2_FTYPE(2, (DF, UI))				\
+  N2_FTYPE(2, (SF, DF))				\
+  N2_FTYPE(2, (SF, SF))				\
+  N2_FTYPE(3, (SF, SF, SF))			\
+  N2_FTYPE(2, (SF, SI))				\
+  N2_FTYPE(2, (SF, UI))				\
+  N2_FTYPE(2, (SI, CVPTR))			\
+  N2_FTYPE(2, (SI, DF))				\
+  N2_FTYPE(3, (SI, DF, DF))			\
+  N2_FTYPE(2, (SI, SF))				\
+  N2_FTYPE(3, (SI, SF, SF))			\
+  N2_FTYPE(2, (SI, SI))				\
+  N2_FTYPE(2, (UI, CVPTR))			\
+  N2_FTYPE(2, (UI, DF))				\
+  N2_FTYPE(2, (UI, SF))				\
+  N2_FTYPE(2, (VOID, DF))			\
+  N2_FTYPE(2, (VOID, SF))			\
+  N2_FTYPE(3, (VOID, SI, SI))			\
+  N2_FTYPE(3, (VOID, VPTR, SI))
+
+#define N2_FTYPE_OP1(R)         N2_FTYPE_ ## R ## _VOID
+#define N2_FTYPE_OP2(R, A1)     N2_FTYPE_ ## R ## _ ## A1
+#define N2_FTYPE_OP3(R, A1, A2) N2_FTYPE_ ## R ## _ ## A1 ## _ ## A2
+
+/* Expand ftcode enumeration.  */
+enum nios2_ftcode {
+#define N2_FTYPE(N,ARGS) N2_FTYPE_OP ## N ARGS,
+N2_FTYPES
+#undef N2_FTYPE
+N2_FTYPE_MAX
+};
+
+/* Return the tree function type, based on the ftcode.  */
+static tree
+nios2_ftype (enum nios2_ftcode ftcode)
+{
+  static tree types[(int) N2_FTYPE_MAX];
+
+  tree N2_TYPE_SF = float_type_node;
+  tree N2_TYPE_DF = double_type_node;
+  tree N2_TYPE_SI = integer_type_node;
+  tree N2_TYPE_UI = unsigned_type_node;
+  tree N2_TYPE_VOID = void_type_node;
+
+  static const_tree N2_TYPE_CVPTR, N2_TYPE_VPTR;
+  if (!N2_TYPE_CVPTR)
+    {
+      /* const volatile void * */
+      N2_TYPE_CVPTR
+	= build_pointer_type (build_qualified_type (void_type_node,
+						    (TYPE_QUAL_CONST
+						     | TYPE_QUAL_VOLATILE)));
+      /* volatile void * */
+      N2_TYPE_VPTR
+	= build_pointer_type (build_qualified_type (void_type_node,
+						    TYPE_QUAL_VOLATILE));
+    }
+  if (types[(int) ftcode] == NULL_TREE)
+    switch (ftcode)
+      {
+#define N2_FTYPE_ARGS1(R) N2_TYPE_ ## R
+#define N2_FTYPE_ARGS2(R,A1) N2_TYPE_ ## R, N2_TYPE_ ## A1
+#define N2_FTYPE_ARGS3(R,A1,A2) N2_TYPE_ ## R, N2_TYPE_ ## A1, N2_TYPE_ ## A2
+#define N2_FTYPE(N,ARGS)						\
+  case N2_FTYPE_OP ## N ARGS:						\
+    types[(int) ftcode]							\
+      = build_function_type_list (N2_FTYPE_ARGS ## N ARGS, NULL_TREE); \
+    break;
+	N2_FTYPES
+#undef N2_FTYPE
+      default: gcc_unreachable ();
+      }
+  return types[(int) ftcode];
+}
+
+
+
+/* Definition of FPU instruction descriptions.  */
+
+struct nios2_fpu_insn_info
+{
+  const char *name;
+  int num_operands, *optvar;
+  int opt, no_opt;
+#define N2F_DF            0x1
+#define N2F_DFREQ         0x2
+#define N2F_UNSAFE        0x4
+#define N2F_FINITE        0x8
+  unsigned int flags;
+  enum insn_code icode;
+  enum nios2_ftcode ftcode;
+};
+
+/* Base macro for defining FPU instructions.  */
+#define N2FPU_INSN_DEF_BASE(insn, nop, flags, icode, args)	\
+  { #insn, nop, &nios2_custom_ ## insn, OPT_mcustom_##insn##_,	\
+    OPT_mno_custom_##insn, flags, CODE_FOR_ ## icode,		\
+    N2_FTYPE_OP ## nop args }
+
+/* Arithmetic and math functions; 2 or 3 operand FP operations.  */
+#define N2FPU_OP2(mode) (mode, mode)
+#define N2FPU_OP3(mode) (mode, mode, mode)
+#define N2FPU_INSN_DEF(code, icode, nop, flags, m, M)			\
+  N2FPU_INSN_DEF_BASE (f ## code ## m, nop, flags,			\
+		       icode ## m ## f ## nop, N2FPU_OP ## nop (M ## F))
+#define N2FPU_INSN_SF(code, nop, flags)		\
+  N2FPU_INSN_DEF (code, code, nop, flags, s, S)
+#define N2FPU_INSN_DF(code, nop, flags)		\
+  N2FPU_INSN_DEF (code, code, nop, flags | N2F_DF, d, D)
+
+/* Compare instructions, 3 operand FP operation with a SI result.  */
+#define N2FPU_CMP_DEF(code, flags, m, M)				\
+  N2FPU_INSN_DEF_BASE (fcmp ## code ## m, 3, flags,			\
+		       nios2_s ## code ## m ## f, (SI, M ## F, M ## F))
+#define N2FPU_CMP_SF(code) N2FPU_CMP_DEF (code, 0, s, S)
+#define N2FPU_CMP_DF(code) N2FPU_CMP_DEF (code, N2F_DF, d, D)
+
+/* The order of definition needs to be maintained consistent with
+   enum n2fpu_code in nios2-opts.h.  */
+struct nios2_fpu_insn_info nios2_fpu_insn[] =
+  {
+    /* Single precision instructions.  */
+    N2FPU_INSN_SF (add, 3, 0),
+    N2FPU_INSN_SF (sub, 3, 0),
+    N2FPU_INSN_SF (mul, 3, 0),
+    N2FPU_INSN_SF (div, 3, 0),
+    /* Due to textual difference between min/max and smin/smax.  */
+    N2FPU_INSN_DEF (min, smin, 3, N2F_FINITE, s, S),
+    N2FPU_INSN_DEF (max, smax, 3, N2F_FINITE, s, S),
+    N2FPU_INSN_SF (neg, 2, 0),
+    N2FPU_INSN_SF (abs, 2, 0),
+    N2FPU_INSN_SF (sqrt, 2, 0),
+    N2FPU_INSN_SF (sin, 2, N2F_UNSAFE),
+    N2FPU_INSN_SF (cos, 2, N2F_UNSAFE),
+    N2FPU_INSN_SF (tan, 2, N2F_UNSAFE),
+    N2FPU_INSN_SF (atan, 2, N2F_UNSAFE),
+    N2FPU_INSN_SF (exp, 2, N2F_UNSAFE),
+    N2FPU_INSN_SF (log, 2, N2F_UNSAFE),
+    /* Single precision compares.  */
+    N2FPU_CMP_SF (eq), N2FPU_CMP_SF (ne),
+    N2FPU_CMP_SF (lt), N2FPU_CMP_SF (le),
+    N2FPU_CMP_SF (gt), N2FPU_CMP_SF (ge),
+
+    /* Double precision instructions.  */
+    N2FPU_INSN_DF (add, 3, 0),
+    N2FPU_INSN_DF (sub, 3, 0),
+    N2FPU_INSN_DF (mul, 3, 0),
+    N2FPU_INSN_DF (div, 3, 0),
+    /* Due to textual difference between min/max and smin/smax.  */
+    N2FPU_INSN_DEF (min, smin, 3, N2F_FINITE, d, D),
+    N2FPU_INSN_DEF (max, smax, 3, N2F_FINITE, d, D),
+    N2FPU_INSN_DF (neg, 2, 0),
+    N2FPU_INSN_DF (abs, 2, 0),
+    N2FPU_INSN_DF (sqrt, 2, 0),
+    N2FPU_INSN_DF (sin, 2, N2F_UNSAFE),
+    N2FPU_INSN_DF (cos, 2, N2F_UNSAFE),
+    N2FPU_INSN_DF (tan, 2, N2F_UNSAFE),
+    N2FPU_INSN_DF (atan, 2, N2F_UNSAFE),
+    N2FPU_INSN_DF (exp, 2, N2F_UNSAFE),
+    N2FPU_INSN_DF (log, 2, N2F_UNSAFE),
+    /* Double precision compares.  */
+    N2FPU_CMP_DF (eq), N2FPU_CMP_DF (ne),
+    N2FPU_CMP_DF (lt), N2FPU_CMP_DF (le),
+    N2FPU_CMP_DF (gt), N2FPU_CMP_DF (ge),
+
+    /* Conversion instructions.  */
+    N2FPU_INSN_DEF_BASE (floatis,  2, 0, floatsisf2,    (SF, SI)),
+    N2FPU_INSN_DEF_BASE (floatus,  2, 0, floatunssisf2, (SF, UI)),
+    N2FPU_INSN_DEF_BASE (floatid,  2, 0, floatsidf2,    (DF, SI)),
+    N2FPU_INSN_DEF_BASE (floatud,  2, 0, floatunssidf2, (DF, UI)),
+    N2FPU_INSN_DEF_BASE (fixsi,    2, 0, fix_truncsfsi2,      (SI, SF)),
+    N2FPU_INSN_DEF_BASE (fixsu,    2, 0, fixuns_truncsfsi2,   (UI, SF)),
+    N2FPU_INSN_DEF_BASE (fixdi,    2, 0, fix_truncdfsi2,      (SI, DF)),
+    N2FPU_INSN_DEF_BASE (fixdu,    2, 0, fixuns_truncdfsi2,   (UI, DF)),
+    N2FPU_INSN_DEF_BASE (fextsd,   2, 0, extendsfdf2,   (DF, SF)),
+    N2FPU_INSN_DEF_BASE (ftruncds, 2, 0, truncdfsf2,    (SF, DF)),
+
+    /* X, Y access instructions.  */
+    N2FPU_INSN_DEF_BASE (fwrx,     2, N2F_DFREQ, nios2_fwrx,   (VOID, DF)),
+    N2FPU_INSN_DEF_BASE (fwry,     2, N2F_DFREQ, nios2_fwry,   (VOID, SF)),
+    N2FPU_INSN_DEF_BASE (frdxlo,   1, N2F_DFREQ, nios2_frdxlo, (SF)),
+    N2FPU_INSN_DEF_BASE (frdxhi,   1, N2F_DFREQ, nios2_frdxhi, (SF)),
+    N2FPU_INSN_DEF_BASE (frdy,     1, N2F_DFREQ, nios2_frdy,   (SF))
+  };
+
+/* Some macros for ease of access.  */
+#define N2FPU(code) nios2_fpu_insn[(int) code]
+#define N2FPU_ENABLED_P(code) (N2FPU_N(code) >= 0)
+#define N2FPU_N(code) (*N2FPU(code).optvar)
+#define N2FPU_NAME(code) (N2FPU(code).name)
+#define N2FPU_ICODE(code) (N2FPU(code).icode)
+#define N2FPU_FTCODE(code) (N2FPU(code).ftcode)
+#define N2FPU_FINITE_P(code) (N2FPU(code).flags & N2F_FINITE)
+#define N2FPU_UNSAFE_P(code) (N2FPU(code).flags & N2F_UNSAFE)
+#define N2FPU_DOUBLE_P(code) (N2FPU(code).flags & N2F_DF)
+#define N2FPU_DOUBLE_REQUIRED_P(code) (N2FPU(code).flags & N2F_DFREQ)
+
+/* Same as above, but for cases where using only the op part is shorter.  */
+#define N2FPU_OP(op) N2FPU(n2fpu_ ## op)
+#define N2FPU_OP_NAME(op) N2FPU_NAME(n2fpu_ ## op)
+#define N2FPU_OP_ENABLED_P(op) N2FPU_ENABLED_P(n2fpu_ ## op)
+
+/* Export the FPU insn enabled predicate to nios2.md.  */
+bool
+nios2_fpu_insn_enabled (enum n2fpu_code code)
+{
+  return N2FPU_ENABLED_P (code);
+}
+
+static bool
+nios2_fpu_compare_enabled (enum rtx_code cond, enum machine_mode mode)
+{
+  if (mode == SFmode)
+    switch (cond) 
+      {
+      case EQ: return N2FPU_OP_ENABLED_P (fcmpeqs);
+      case NE: return N2FPU_OP_ENABLED_P (fcmpnes);
+      case GT: return N2FPU_OP_ENABLED_P (fcmpgts);
+      case GE: return N2FPU_OP_ENABLED_P (fcmpges);
+      case LT: return N2FPU_OP_ENABLED_P (fcmplts);
+      case LE: return N2FPU_OP_ENABLED_P (fcmples);
+      default: break;
+      }
+  else if (mode == DFmode)
+    switch (cond) 
+      {
+      case EQ: return N2FPU_OP_ENABLED_P (fcmpeqd);
+      case NE: return N2FPU_OP_ENABLED_P (fcmpned);
+      case GT: return N2FPU_OP_ENABLED_P (fcmpgtd);
+      case GE: return N2FPU_OP_ENABLED_P (fcmpged);
+      case LT: return N2FPU_OP_ENABLED_P (fcmpltd);
+      case LE: return N2FPU_OP_ENABLED_P (fcmpled);
+      default: break;
+      }
+  return false;
+}
+
+#define IS_UNSPEC_TLS(x) ((x) >= UNSPEC_TLS && (x) <= UNSPEC_ADD_TLS_LDO)
+
+
+/* Stack Layout and Calling Conventions */
+
+#define TOO_BIG_OFFSET(X) ((X) > ((1 << 15) - 1))
+#define TEMP_REG_NUM 8
+
+static void
+save_reg (int regno, unsigned offset)
+{
+  rtx reg = gen_rtx_REG (SImode, regno);
+  rtx addr = gen_rtx_PLUS (Pmode, stack_pointer_rtx,
+			   gen_int_mode (offset, Pmode));
+
+  rtx pattern = gen_rtx_SET (SImode, gen_frame_mem (Pmode, addr), reg);
+  rtx insn = emit_insn (pattern);
+  RTX_FRAME_RELATED_P (insn) = 1;
+}
+
+static void
+restore_reg (int regno, unsigned offset)
+{
+  rtx reg = gen_rtx_REG (SImode, regno);
+  rtx addr = gen_rtx_PLUS (Pmode, stack_pointer_rtx,
+			   gen_int_mode (offset, Pmode));
+
+  rtx pattern = gen_rtx_SET (SImode, reg, gen_frame_mem (Pmode, addr));
+  emit_insn (pattern);
+}
+
+void
+expand_prologue (void)
+{
+  int ix;
+  HOST_WIDE_INT total_frame_size = compute_frame_size ();
+  int sp_offset;	/* offset from base_reg to final stack value.  */
+  int fp_offset;	/* offset from base_reg to final fp value.  */
+  int save_offset;
+  rtx insn;
+  unsigned HOST_WIDE_INT save_mask;
+
+  total_frame_size = compute_frame_size ();
+  if (flag_stack_usage_info)
+    current_function_static_stack_size = total_frame_size;
+
+  /* Decrement the stack pointer */
+  if (TOO_BIG_OFFSET (total_frame_size))
+    {
+      /* We need an intermediary point, this will point at the spill
+	 block.  */
+      insn = emit_insn
+	(gen_add3_insn (stack_pointer_rtx,
+			stack_pointer_rtx,
+			gen_int_mode (cfun->machine->save_regs_offset
+				      - total_frame_size, Pmode)));
+      RTX_FRAME_RELATED_P (insn) = 1;
+
+      fp_offset = 0;
+      sp_offset = -cfun->machine->save_regs_offset;
+    }
+  else if (total_frame_size)
+    {
+      insn = emit_insn (gen_add3_insn (stack_pointer_rtx,
+				       stack_pointer_rtx,
+				       gen_int_mode (-total_frame_size,
+						     Pmode)));
+      RTX_FRAME_RELATED_P (insn) = 1;
+      fp_offset = cfun->machine->save_regs_offset;
+      sp_offset = 0;
+    }
+  else
+    fp_offset = sp_offset = 0;
+
+  if (crtl->limit_stack)
+    emit_insn (gen_stack_overflow_detect_and_trap ());
+
+  save_offset = fp_offset + cfun->machine->save_reg_size;
+  save_mask = cfun->machine->save_mask;
+  
+  for (ix = 32; ix--;)
+    if (save_mask & ((unsigned HOST_WIDE_INT)1 << ix))
+      {
+	save_offset -= 4;
+	save_reg (ix, save_offset);
+      }
+
+  if (frame_pointer_needed)
+    {
+      insn = emit_insn (gen_add3_insn (hard_frame_pointer_rtx,
+				       stack_pointer_rtx,
+				       gen_int_mode (fp_offset, Pmode)));
+      RTX_FRAME_RELATED_P (insn) = 1;
+    }
+
+  if (sp_offset)
+    {
+      rtx sp_adjust
+	= gen_rtx_SET (Pmode, stack_pointer_rtx,
+		       gen_rtx_PLUS (Pmode, stack_pointer_rtx,
+				     gen_int_mode (sp_offset, Pmode)));
+      if (SMALL_INT (sp_offset))
+	insn = emit_insn (sp_adjust);
+      else
+	{
+	  rtx tmp = gen_rtx_REG (Pmode, TEMP_REG_NUM);
+	  emit_insn (gen_rtx_SET (Pmode, tmp, gen_int_mode (sp_offset, Pmode)));
+	  insn = emit_insn (gen_add3_insn (stack_pointer_rtx, stack_pointer_rtx,
+					   tmp));
+	  /* Attach the sp_adjust as a note indicating what happened.  */
+	  REG_NOTES (insn) = alloc_EXPR_LIST (REG_FRAME_RELATED_EXPR,
+					      sp_adjust, REG_NOTES (insn));
+	}
+      RTX_FRAME_RELATED_P (insn) = 1;
+
+      if (crtl->limit_stack)
+	emit_insn (gen_stack_overflow_detect_and_trap ());
+    }
+
+  /* Load the PIC register if needed.  */
+  if (crtl->uses_pic_offset_table)
+    nios2_load_pic_register ();
+
+  /* If we are profiling, make sure no instructions are scheduled before
+     the call to mcount.  */
+  if (crtl->profile)
+    emit_insn (gen_blockage ());
+}
+
+void
+expand_epilogue (bool sibcall_p)
+{
+  int ix;
+  HOST_WIDE_INT total_frame_size = compute_frame_size ();
+  unsigned HOST_WIDE_INT save_mask;
+  int sp_adjust;
+  int save_offset;
+ 
+  if (!sibcall_p && nios2_can_use_return_insn ())
+    {
+      emit_jump_insn (gen_return ());
+      return;
+    }
+
+  emit_insn (gen_blockage ());
+
+  if (frame_pointer_needed)
+    {
+      /* Recover the stack pointer.  */
+      emit_insn (gen_rtx_SET (Pmode, stack_pointer_rtx,
+			      hard_frame_pointer_rtx));
+      save_offset = 0;
+      sp_adjust = total_frame_size - cfun->machine->save_regs_offset;
+    }
+  else if (TOO_BIG_OFFSET (total_frame_size))
+    {
+      rtx tmp = gen_rtx_REG (Pmode, TEMP_REG_NUM);
+
+      emit_insn
+	(gen_rtx_SET (Pmode, tmp,
+		      gen_int_mode (cfun->machine->save_regs_offset,
+				    Pmode)));
+      emit_insn (gen_add3_insn (stack_pointer_rtx, stack_pointer_rtx, tmp));
+      save_offset = 0;
+      sp_adjust = total_frame_size - cfun->machine->save_regs_offset;
+    }
+  else
+    {
+      save_offset = cfun->machine->save_regs_offset;
+      sp_adjust = total_frame_size;
+    }
+  
+  save_mask = cfun->machine->save_mask;
+  save_offset += cfun->machine->save_reg_size;
+  
+  for (ix = 32; ix--;)
+    if (save_mask & ((unsigned HOST_WIDE_INT)1 << ix))
+      {
+	save_offset -= 4;
+	restore_reg (ix, save_offset);
+      }
+
+  if (sp_adjust)
+    emit_insn (gen_add3_insn (stack_pointer_rtx, stack_pointer_rtx,
+			      gen_int_mode (sp_adjust, Pmode)));
+
+  /* Add in the __builtin_eh_return stack adjustment.  */
+  if (crtl->calls_eh_return)
+    emit_insn (gen_add3_insn (stack_pointer_rtx,
+			      stack_pointer_rtx,
+			      EH_RETURN_STACKADJ_RTX));
+
+  if (!sibcall_p)
+    emit_jump_insn (gen_return_from_epilogue (gen_rtx_REG (Pmode, RA_REGNO)));
+}
+
+/* Implement RETURN_ADDR_RTX.  Note, we do not support moving
+   back to a previous frame.  */
+rtx
+nios2_get_return_address (int count)
+{
+  if (count != 0)
+    return const0_rtx;
+
+  return get_hard_reg_initial_val (Pmode, RA_REGNO);
+}
+
+/* Emit code to change the current function's return address to
+   ADDRESS.  SCRATCH is available as a scratch register, if needed.
+   ADDRESS and SCRATCH are both word-mode GPRs.  */
+void
+nios2_set_return_address (rtx address, rtx scratch)
+{
+  compute_frame_size ();
+  if ((cfun->machine->save_mask >> RA_REGNO) & 1)
+    {
+      unsigned offset = cfun->machine->save_reg_size - 4;
+      rtx base;
+      
+      if (frame_pointer_needed)
+	base = hard_frame_pointer_rtx;
+      else
+	{
+	  base = stack_pointer_rtx;
+	  offset += cfun->machine->save_regs_offset;
+	  
+	  if (TOO_BIG_OFFSET (offset))
+	    {
+	      emit_insn (gen_rtx_SET (Pmode, scratch,
+				      gen_int_mode (offset, Pmode)));
+	      emit_insn (gen_add3_insn (scratch, scratch, base));
+	      base = scratch;
+	      offset = 0;
+	    }
+	}
+      if (offset)
+	base = gen_rtx_PLUS (Pmode, base, gen_int_mode (offset, Pmode));
+      emit_insn (gen_rtx_SET (Pmode, gen_rtx_MEM (Pmode, base), address));
+    }
+  else
+    emit_insn (gen_rtx_SET (Pmode, gen_rtx_REG (Pmode, RA_REGNO), address));
+}
+
+
+/* Profiling.  */
+
+void
+nios2_function_profiler (FILE *file, int labelno ATTRIBUTE_UNUSED)
+{
+  fprintf (file, "\tmov\tr8, ra\n");
+  if (flag_pic)
+    {
+      fprintf (file, "\tnextpc\tr2\n");
+      fprintf (file, "\t1: movhi\tr3, %%hiadj(_GLOBAL_OFFSET_TABLE_ - 1b)\n");
+      fprintf (file, "\taddi\tr3, r3, %%lo(_GLOBAL_OFFSET_TABLE_ - 1b)\n");
+      fprintf (file, "\tadd\tr2, r2, r3\n");
+      fprintf (file, "\tldw\tr2, %%call(_mcount)(r2)\n");
+      fprintf (file, "\tcallr\tr2\n");
+    }
+  else
+    fprintf (file, "\tcall\t_mcount\n");
+  fprintf (file, "\tmov\tra, r8\n");
+}
+
+/* Stack Layout.  */
+static void
+dump_frame_size (FILE *file)
+{
+  fprintf (file, "\t%s Current Frame Info\n", ASM_COMMENT_START);
+
+  fprintf (file, "\t%s total_size = %ld\n", ASM_COMMENT_START,
+           cfun->machine->total_size);
+  fprintf (file, "\t%s var_size = %ld\n", ASM_COMMENT_START,
+           cfun->machine->var_size);
+  fprintf (file, "\t%s args_size = %ld\n", ASM_COMMENT_START,
+           cfun->machine->args_size);
+  fprintf (file, "\t%s save_reg_size = %d\n", ASM_COMMENT_START,
+           cfun->machine->save_reg_size);
+  fprintf (file, "\t%s initialized = %d\n", ASM_COMMENT_START,
+           cfun->machine->initialized);
+  fprintf (file, "\t%s save_regs_offset = %ld\n", ASM_COMMENT_START,
+           cfun->machine->save_regs_offset);
+  fprintf (file, "\t%s current_function_is_leaf = %d\n", ASM_COMMENT_START,
+           current_function_is_leaf);
+  fprintf (file, "\t%s frame_pointer_needed = %d\n", ASM_COMMENT_START,
+           frame_pointer_needed);
+  fprintf (file, "\t%s pretend_args_size = %d\n", ASM_COMMENT_START,
+           crtl->args.pretend_args_size);
+
+}
+
+/* Return true if REGNO should be saved in a prologue.  */
+static bool
+save_reg_p (unsigned regno)
+{
+  gcc_assert (GP_REGNO_P (regno));
+  
+  if (df_regs_ever_live_p (regno) && !call_used_regs[regno])
+    return true;
+
+  if (regno == HARD_FRAME_POINTER_REGNUM && frame_pointer_needed)
+    return true;
+
+  if (regno == PIC_OFFSET_TABLE_REGNUM && crtl->uses_pic_offset_table)
+    return true;
+
+  if (regno == RA_REGNO && df_regs_ever_live_p (RA_REGNO))
+    return true;
+
+  return false;
+}
+
+/* Return the bytes needed to compute the frame pointer from the current
+   stack pointer.  */
+static HOST_WIDE_INT
+compute_frame_size (void)
+{
+  unsigned int regno;
+  HOST_WIDE_INT var_size;       /* # of var. bytes allocated.  */
+  HOST_WIDE_INT total_size;     /* # bytes that the entire frame takes up.  */
+  HOST_WIDE_INT save_reg_size;  /* # bytes needed to store callee save regs.  */
+  HOST_WIDE_INT out_args_size;  /* # bytes needed for outgoing args. */
+  unsigned HOST_WIDE_INT save_mask = 0;
+
+  if (cfun->machine->initialized)
+    return cfun->machine->total_size;
+  
+  save_reg_size = 0;
+  var_size = STACK_ALIGN (get_frame_size ());
+  out_args_size = STACK_ALIGN (crtl->outgoing_args_size);
+
+  total_size = var_size + out_args_size;
+
+  /* Calculate space needed for gp registers.  */
+  for (regno = 0; GP_REGNO_P (regno); regno++)
+    if (save_reg_p (regno))
+      {
+	save_mask |= (unsigned HOST_WIDE_INT)1 << regno;
+	save_reg_size += 4;
+      }
+
+  /* If we call eh_return, we need to save the EH data registers.  */
+  if (crtl->calls_eh_return)
+    {
+      unsigned i;
+      unsigned r;
+      
+      for (i = 0; (r = EH_RETURN_DATA_REGNO (i)) != INVALID_REGNUM; i++)
+	if (!(save_mask & (1 << r)))
+	  {
+	    save_mask |= 1 << r;
+	    save_reg_size += 4;
+	  }
+    }
+
+  save_reg_size = STACK_ALIGN (save_reg_size);
+  total_size += save_reg_size;
+
+  total_size += STACK_ALIGN (crtl->args.pretend_args_size);
+
+  /* Save other computed information.  */
+  cfun->machine->save_mask = save_mask;
+  cfun->machine->total_size = total_size;
+  cfun->machine->var_size = var_size;
+  cfun->machine->args_size = out_args_size;
+  cfun->machine->save_reg_size = save_reg_size;
+  cfun->machine->initialized = reload_completed;
+  cfun->machine->save_regs_offset = out_args_size + var_size;
+
+  return total_size;
+}
+
+/* Implement TARGET_CAN_ELIMINATE.  */
+static bool
+nios2_can_eliminate (const int from ATTRIBUTE_UNUSED, const int to)
+{
+  if (to == STACK_POINTER_REGNUM)
+    return !frame_pointer_needed;
+  return true;
+}
+
+int
+nios2_initial_elimination_offset (int from, int to)
+{
+  int offset;
+
+  compute_frame_size ();
+
+  /* Set OFFSET to the offset from the stack pointer.  */
+  switch (from)
+    {
+    case FRAME_POINTER_REGNUM:
+      offset = cfun->machine->args_size;
+      break;
+
+    case ARG_POINTER_REGNUM:
+      offset = cfun->machine->total_size;
+      offset -= crtl->args.pretend_args_size;
+      break;
+
+    default:
+      gcc_unreachable ();
+    }
+
+    /* If we are asked for the frame pointer offset, then adjust OFFSET
+       by the offset from the frame pointer to the stack pointer.  */
+    if (to == HARD_FRAME_POINTER_REGNUM)
+      offset -= cfun->machine->save_regs_offset;
+
+    return offset;
+}
+
+/* Return nonzero if this function is known to have a null epilogue.
+   This allows the optimizer to omit jumps to jumps if no stack
+   was created.  */
+int
+nios2_can_use_return_insn (void)
+{
+  if (!reload_completed)
+    return 0;
+
+  if (df_regs_ever_live_p (RA_REGNO) || crtl->profile)
+    return 0;
+
+  if (cfun->machine->initialized)
+    return cfun->machine->total_size == 0;
+
+  return compute_frame_size () == 0;
+}
+
+
+
+/* Check and signal some warnings/errors on FPU insn options.  */
+static void
+nios2_custom_check_insns (void)
+{
+  unsigned int i, j;
+  bool errors = false;
+
+  for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+    if (N2FPU_ENABLED_P (i) && N2FPU_DOUBLE_P (i))
+      {
+	for (j = 0; j < ARRAY_SIZE (nios2_fpu_insn); j++)
+	  if (N2FPU_DOUBLE_REQUIRED_P (j) && ! N2FPU_ENABLED_P (j))
+	    {
+	      error ("switch `-mcustom-%s' is required for double precision "
+		     "floating point", N2FPU_NAME (j));
+	      errors = true;
+	    }
+	break;
+      }
+
+  /* Warn if the user has certain exotic operations that won't get used
+     without -funsafe-math-optimizations.  See expand_builtin () in
+     builtins.c.  */
+  if (!flag_unsafe_math_optimizations)
+    for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+      if (N2FPU_ENABLED_P (i) && N2FPU_UNSAFE_P (i))
+	warning (0, "switch `-mcustom-%s' has no effect unless "
+		 "-funsafe-math-optimizations is specified", N2FPU_NAME (i));
+
+  /* Warn if the user is trying to use -mcustom-fmins et. al, that won't
+     get used without -ffinite-math-only.  See fold_builtin_fmin_fmax ()
+     in builtins.c.  */
+  if (!flag_finite_math_only)
+    for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+      if (N2FPU_ENABLED_P (i) && N2FPU_FINITE_P (i))
+	warning (0, "switch `-mcustom-%s' has no effect unless "
+		 "-ffinite-math-only is specified", N2FPU_NAME (i));
+
+  if (errors || custom_code_conflict)
+    fatal_error ("conflicting use of -mcustom switches, target attributes, "
+		 "and/or __builtin_custom_ functions");
+}
+
+static void
+nios2_set_fpu_custom_code (enum n2fpu_code code, int N, bool override_p)
+{
+  if (override_p || N2FPU_N (code) == -1)
+    N2FPU_N (code) = N;
+  nios2_register_custom_code (N, CCS_FPU, (int) code);
+}
+
+static void
+nios2_handle_custom_fpu_cfg (const char *cfg, bool override_p)
+{
+  if (!strncasecmp (cfg, "60-1", 4))
+    {
+      nios2_set_fpu_custom_code (n2fpu_fmuls, 252, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fadds, 253, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fsubs, 254, override_p);
+      flag_single_precision_constant = 1;
+    }
+  else if (!strncasecmp (cfg, "60-2", 4))
+    {
+      nios2_set_fpu_custom_code (n2fpu_fmuls, 252, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fadds, 253, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fsubs, 254, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fdivs, 255, override_p);
+      flag_single_precision_constant = 1;
+    }
+  else if (!strncasecmp (cfg, "72-3", 4))
+    {
+      nios2_set_fpu_custom_code (n2fpu_floatus, 243, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fixsi, 244, override_p);
+      nios2_set_fpu_custom_code (n2fpu_floatis, 245, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fcmpgts, 246, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fcmples, 249, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fcmpeqs, 250, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fcmpnes, 251, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fmuls, 252, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fadds, 253, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fsubs, 254, override_p);
+      nios2_set_fpu_custom_code (n2fpu_fdivs, 255, override_p);
+      flag_single_precision_constant = 1;
+    }
+  else
+    warning (0, "ignoring unrecognized switch `-mcustom-fpu-cfg' value `%s'",
+	     cfg);
+
+  /* Guard against errors in the standard configurations.  */
+  nios2_custom_check_insns ();
+}
+
+/* Check individual FPU insn options, and register custom code.  */
+static void
+nios2_handle_custom_fpu_insn_option (int fpu_insn_index)
+{
+  int param = N2FPU_N (fpu_insn_index);
+
+  if (0 <= param && param <= 255)
+    nios2_register_custom_code (param, CCS_FPU, fpu_insn_index);
+
+  /* Valid values are 0-255, but also allow -1 so that the
+     -mno-custom-<opt> switches work.  */
+  else if (param != -1)
+    error ("switch `-mcustom-%s' value %d must be between 0 and 255",
+	   N2FPU_NAME (fpu_insn_index), param);
+}
+
+/* Implement TARGET_OPTION_OVERRIDE.  */
+static void
+nios2_option_override (void)
+{
+  unsigned int i;
+
+#ifdef SUBTARGET_OVERRIDE_OPTIONS
+  SUBTARGET_OVERRIDE_OPTIONS;
+#endif
+
+  /* Check for unsupported options.  */
+  if (flag_pic && !TARGET_LINUX_ABI)
+    error ("position-independent code requires the Linux ABI");
+
+  /* Function to allocate machine-dependent function status.  */
+  init_machine_status = &nios2_init_machine_status;
+
+  nios2_section_threshold
+    = (global_options_set.x_g_switch_value
+       ? g_switch_value : NIOS2_DEFAULT_GVALUE);
+
+  /* If we don't have mul, we don't have mulx either!  */
+  if (!TARGET_HAS_MUL && TARGET_HAS_MULX)
+    target_flags &= ~MASK_HAS_MULX;
+
+  /* Set up default handling for floating point custom instructions.
+
+     Putting things in this order means that the -mcustom-fpu-cfg=
+     switch will always be overridden by individual -mcustom-fadds=
+     switches, regardless of the order in which they were specified
+     on the command line.
+
+     This behavior of prioritization of individual -mcustom-<insn>=
+     options before the -mcustom-fpu-cfg= switch is maintained for
+     compatibility.  */
+  if (nios2_custom_fpu_cfg_string && *nios2_custom_fpu_cfg_string)
+    nios2_handle_custom_fpu_cfg (nios2_custom_fpu_cfg_string, false);
+
+  /* Handle options for individual FPU insns.  */
+  for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+    nios2_handle_custom_fpu_insn_option (i);
+
+  nios2_custom_check_insns ();
+
+  /* Save the initial options in case the user does function specific options */
+  target_option_default_node = target_option_current_node
+    = build_target_option_node ();
+}
+
+/* Allocate a chunk of memory for per-function machine-dependent data.  */
+static struct machine_function *
+nios2_init_machine_status (void)
+{
+  return ggc_alloc_cleared_machine_function ();
+}
+
+
+/* Return true if CST is a constant within range of movi/movui/movhi.  */
+static bool
+nios2_simple_const_p (const_rtx cst)
+{
+  HOST_WIDE_INT val = INTVAL (cst);
+  return (SMALL_INT (val) || SMALL_INT_UNSIGNED (val) || UPPER16_INT (val));
+}
+
+/* Compute a (partial) cost for rtx X.  Return true if the complete
+   cost has been computed, and false if subexpressions should be
+   scanned.  In either case, *TOTAL contains the cost result.  */
+static bool
+nios2_rtx_costs (rtx x, int code, int outer_code ATTRIBUTE_UNUSED,
+		 int opno ATTRIBUTE_UNUSED,
+		 int *total, bool speed ATTRIBUTE_UNUSED)
+{
+  switch (code)
+    {
+      case CONST_INT:
+        if (INTVAL (x) == 0)
+          {
+            *total = COSTS_N_INSNS (0);
+            return true;
+          }
+        else if (nios2_simple_const_p (x))
+          {
+            *total = COSTS_N_INSNS (2);
+            return true;
+          }
+        else
+          {
+            *total = COSTS_N_INSNS (4);
+            return true;
+          }
+
+      case LABEL_REF:
+      case SYMBOL_REF:
+        /* ??? gp relative stuff will fit in here.  */
+        /* fall through */
+      case CONST:
+      case CONST_DOUBLE:
+        {
+          *total = COSTS_N_INSNS (4);
+          return true;
+        }
+
+      case AND:
+	{
+	  /* Recognize 'nor' insn pattern.  */
+	  if (GET_CODE (XEXP (x, 0)) == NOT
+	      && GET_CODE (XEXP (x, 1)) == NOT)
+	    {
+	      *total = COSTS_N_INSNS (1);
+	      return true;
+	    }
+	  return false;
+	}
+
+      case MULT:
+        {
+          *total = COSTS_N_INSNS (1);
+          return false;
+        }
+      case SIGN_EXTEND:
+        {
+          *total = COSTS_N_INSNS (3);
+          return false;
+        }
+      case ZERO_EXTEND:
+        {
+          *total = COSTS_N_INSNS (1);
+          return false;
+        }
+
+      default:
+        return false;
+    }
+}
+
+/* Implement TARGET_PREFERRED_RELOAD_CLASS.  */
+
+static reg_class_t
+nios2_preferred_reload_class (rtx x ATTRIBUTE_UNUSED, reg_class_t regclass)
+{
+  return (regclass == NO_REGS ? GENERAL_REGS : regclass);
+}
+
+/* Instruction support:
+   These functions are used within the machine description to
+   handle common or complicated output and expansions from
+   instructions.  */
+
+/* Return TRUE if X references a SYMBOL_REF.  */
+static int
+symbol_mentioned_p (rtx x)
+{
+  const char * fmt;
+  int i;
+
+  if (GET_CODE (x) == SYMBOL_REF)
+    return 1;
+
+  /* UNSPEC_TLS entries for a symbol include the SYMBOL_REF, but they
+     are constant offsets, not symbols.  */
+  if (GET_CODE (x) == UNSPEC && IS_UNSPEC_TLS (XINT (x, 1)))
+    return 0;
+
+  fmt = GET_RTX_FORMAT (GET_CODE (x));
+
+  for (i = GET_RTX_LENGTH (GET_CODE (x)) - 1; i >= 0; i--)
+    if (fmt[i] == 'E')
+      {
+	int j;
+	
+	for (j = XVECLEN (x, i) - 1; j >= 0; j--)
+	  if (symbol_mentioned_p (XVECEXP (x, i, j)))
+	    return 1;
+      }
+    else if (fmt[i] == 'e' && symbol_mentioned_p (XEXP (x, i)))
+      return 1;
+
+  return 0;
+}
+
+/* Return TRUE if X references a LABEL_REF.  */
+static int
+label_mentioned_p (rtx x)
+{
+  const char * fmt;
+  int i;
+
+  if (GET_CODE (x) == LABEL_REF)
+    return 1;
+
+  /* UNSPEC_TLS entries for a symbol include a LABEL_REF for the referencing
+     instruction, but they are constant offsets, not symbols.  */
+  if (GET_CODE (x) == UNSPEC && IS_UNSPEC_TLS (XINT (x, 1)))
+    return 0;
+
+  fmt = GET_RTX_FORMAT (GET_CODE (x));
+  for (i = GET_RTX_LENGTH (GET_CODE (x)) - 1; i >= 0; i--)
+    if (fmt[i] == 'E')
+      {
+	int j;
+	
+	for (j = XVECLEN (x, i) - 1; j >= 0; j--)
+	  if (label_mentioned_p (XVECEXP (x, i, j)))
+	    return 1;
+      }
+    else if (fmt[i] == 'e' && label_mentioned_p (XEXP (x, i)))
+      return 1;
+
+  return 0;
+}
+
+static int
+tls_mentioned_p (rtx x)
+{
+  switch (GET_CODE (x))
+    {
+    case CONST:
+      return tls_mentioned_p (XEXP (x, 0));
+
+    case UNSPEC:
+      if (IS_UNSPEC_TLS (XINT (x, 1)))
+        return 1;
+
+    default:
+      return 0;
+    }
+}
+
+/* Helper for nios2_tls_referenced_p.  */
+static int
+nios2_tls_operand_p_1 (rtx *x, void *data ATTRIBUTE_UNUSED)
+{
+  if (GET_CODE (*x) == SYMBOL_REF)
+    return SYMBOL_REF_TLS_MODEL (*x) != 0;
+
+  /* Don't recurse into UNSPEC_TLS looking for TLS symbols; these are
+     TLS offsets, not real symbol references.  */
+  if (GET_CODE (*x) == UNSPEC
+      && IS_UNSPEC_TLS (XINT (*x, 1)))
+    return -1;
+
+  return 0;
+}
+
+/* Return TRUE if X contains any TLS symbol references.  */
+static bool
+nios2_tls_referenced_p (rtx x)
+{
+  if (! TARGET_HAVE_TLS)
+    return false;
+
+  return for_each_rtx (&x, nios2_tls_operand_p_1, NULL);
+}
+
+static bool
+nios2_cannot_force_const_mem (enum machine_mode mode ATTRIBUTE_UNUSED, rtx x)
+{
+  return nios2_tls_referenced_p (x);
+}
+
+/* Emit a call to __tls_get_addr.  TI is the argument to this function.  RET is
+   an RTX for the return value location.  The entire insn sequence is
+   returned.  */
+static GTY(()) rtx nios2_tls_symbol;
+
+static rtx
+nios2_call_tls_get_addr (rtx ti)
+{
+  rtx arg = gen_rtx_REG (Pmode, FIRST_ARG_REGNO);
+  rtx ret = gen_rtx_REG (Pmode, FIRST_RETVAL_REGNO);
+  rtx fn, insn;
+  
+  if (!nios2_tls_symbol)
+    nios2_tls_symbol = init_one_libfunc ("__tls_get_addr");
+
+  emit_insn (gen_rtx_SET (Pmode, arg, ti));
+  fn = gen_rtx_MEM (QImode, nios2_tls_symbol);
+  insn = emit_call_insn (gen_call_value (ret, fn, const0_rtx));
+  RTL_CONST_CALL_P (insn) = 1;
+  use_reg (&CALL_INSN_FUNCTION_USAGE (insn), ret);
+  use_reg (&CALL_INSN_FUNCTION_USAGE (insn), arg);
+
+  return ret;
+}
+
+/* Generate the code to access LOC, a thread local SYMBOL_REF.  The
+   return value will be a valid address and move_operand (either a REG
+   or a LO_SUM).  */
+static rtx
+nios2_legitimize_tls_address (rtx loc)
+{
+  rtx dest = gen_reg_rtx (Pmode);
+  rtx ret, tmp1;
+  enum tls_model model = SYMBOL_REF_TLS_MODEL (loc);
+
+  switch (model)
+    {
+    case TLS_MODEL_GLOBAL_DYNAMIC:
+      tmp1 = gen_reg_rtx (Pmode);
+      emit_insn (gen_add_tls_gd (tmp1, pic_offset_table_rtx, loc));
+      crtl->uses_pic_offset_table = 1;
+      ret = nios2_call_tls_get_addr (tmp1);
+      emit_insn (gen_rtx_SET (Pmode, dest, ret));
+      break;
+
+    case TLS_MODEL_LOCAL_DYNAMIC:
+      tmp1 = gen_reg_rtx (Pmode);
+      emit_insn (gen_add_tls_ldm (tmp1, pic_offset_table_rtx, loc));
+      crtl->uses_pic_offset_table = 1;
+      ret = nios2_call_tls_get_addr (tmp1);
+
+      emit_insn (gen_add_tls_ldo (dest, ret, loc));
+
+      break;
+
+    case TLS_MODEL_INITIAL_EXEC:
+      tmp1 = gen_reg_rtx (Pmode);
+      emit_insn (gen_load_tls_ie (tmp1, pic_offset_table_rtx, loc));
+      crtl->uses_pic_offset_table = 1;
+      emit_insn (gen_add3_insn (dest,
+				gen_rtx_REG (Pmode, THREAD_POINTER_REGNUM),
+				tmp1));
+      break;
+
+    case TLS_MODEL_LOCAL_EXEC:
+      emit_insn (gen_add_tls_le (dest,
+				 gen_rtx_REG (Pmode, THREAD_POINTER_REGNUM),
+				 loc));
+      break;
+
+    default:
+      gcc_unreachable ();
+    }
+
+  return dest;
+}
+
+int
+nios2_emit_move_sequence (rtx *operands, enum machine_mode mode)
+{
+  rtx to = operands[0];
+  rtx from = operands[1];
+
+  if (!register_operand (to, mode) && !reg_or_0_operand (from, mode))
+    {
+      gcc_assert (can_create_pseudo_p ());
+      from = copy_to_mode_reg (mode, from);
+    }
+
+  /* Recognize the case where from is a reference to thread-local
+     data and load its address to a register.  */
+  if (nios2_tls_referenced_p (from))
+    {
+      rtx tmp = from;
+      rtx addend = NULL;
+
+      if (GET_CODE (tmp) == CONST && GET_CODE (XEXP (tmp, 0)) == PLUS)
+        {
+          addend = XEXP (XEXP (tmp, 0), 1);
+          tmp = XEXP (XEXP (tmp, 0), 0);
+        }
+
+      gcc_assert (GET_CODE (tmp) == SYMBOL_REF);
+      gcc_assert (SYMBOL_REF_TLS_MODEL (tmp) != 0);
+
+      tmp = nios2_legitimize_tls_address (tmp);
+      if (addend)
+	{
+          tmp = gen_rtx_PLUS (SImode, tmp, addend);
+          tmp = force_operand (tmp, to);
+        }
+      from = tmp;
+    }
+  else if (flag_pic && (CONSTANT_P (from) || symbol_mentioned_p (from) ||
+			label_mentioned_p (from)))
+    from = nios2_legitimize_pic_address (from, SImode,
+					 (can_create_pseudo_p () ? 0 : to));
+
+  operands[0] = to;
+  operands[1] = from;
+  return 0;
+}
+
+/* Divide Support */
+
+/*
+  If -O3 is used, we want to output a table lookup for
+  divides between small numbers (both num and den >= 0
+  and < 0x10).  The overhead of this method in the worse
+  case is 40 bytes in the text section (10 insns) and
+  256 bytes in the data section.  Additional divides do
+  not incur additional penalties in the data section.
+
+  Code speed is improved for small divides by about 5x
+  when using this method in the worse case (~9 cycles
+  vs ~45).  And in the worse case divides not within the
+  table are penalized by about 10% (~5 cycles vs ~45).
+  However in the typical case the penalty is not as bad
+  because doing the long divide in only 45 cycles is
+  quite optimistic.
+
+  ??? It would be nice to have some benchmarks other
+  than Dhrystone to back this up.
+
+  This bit of expansion is to create this instruction
+  sequence as rtl.
+        or      $8, $4, $5
+        slli    $9, $4, 4
+        cmpgeui $3, $8, 16
+        beq     $3, $0, .L3
+        or      $10, $9, $5
+        add     $12, $11, divide_table
+        ldbu    $2, 0($12)
+        br      .L1
+.L3:
+        call    slow_div
+.L1:
+#       continue here with result in $2
+
+  ??? Ideally I would like the emit libcall block to contain
+  all of this code, but I don't know how to do that.  What it
+  means is that if the divide can be eliminated, it may not
+  completely disappear.
+
+  ??? The __divsi3_table label should ideally be moved out
+  of this block and into a global.  If it is placed into the
+  sdata section we can save even more cycles by doing things
+  gp relative.
+*/
+int
+nios2_emit_expensive_div (rtx *operands, enum machine_mode mode)
+{
+  rtx or_result, shift_left_result;
+  rtx lookup_value;
+  rtx lab1, lab3;
+  rtx insns;
+  rtx libfunc;
+  rtx final_result;
+  rtx tmp;
+  rtx table;
+
+  /* It may look a little generic, but only SImode
+     is supported for now.  */
+  gcc_assert (mode == SImode);
+  libfunc = optab_libfunc (sdiv_optab, SImode);
+
+  lab1 = gen_label_rtx ();
+  lab3 = gen_label_rtx ();
+
+  or_result = expand_simple_binop (SImode, IOR,
+                                   operands[1], operands[2],
+                                   0, 0, OPTAB_LIB_WIDEN);
+
+  emit_cmp_and_jump_insns (or_result, GEN_INT (15), GTU, 0,
+                           GET_MODE (or_result), 0, lab3);
+  JUMP_LABEL (get_last_insn ()) = lab3;
+
+  shift_left_result = expand_simple_binop (SImode, ASHIFT,
+                                           operands[1], GEN_INT (4),
+                                           0, 0, OPTAB_LIB_WIDEN);
+
+  lookup_value = expand_simple_binop (SImode, IOR,
+                                      shift_left_result, operands[2],
+                                      0, 0, OPTAB_LIB_WIDEN);
+  table = gen_rtx_PLUS (SImode, lookup_value,
+			gen_rtx_SYMBOL_REF (SImode, "__divsi3_table"));
+  convert_move (operands[0], gen_rtx_MEM (QImode, table), 1);
+
+  tmp = emit_jump_insn (gen_jump (lab1));
+  JUMP_LABEL (tmp) = lab1;
+  emit_barrier ();
+
+  emit_label (lab3);
+  LABEL_NUSES (lab3) = 1;
+
+  start_sequence ();
+  final_result = emit_library_call_value (libfunc, NULL_RTX,
+                                          LCT_CONST, SImode, 2,
+                                          operands[1], SImode,
+                                          operands[2], SImode);
+
+
+  insns = get_insns ();
+  end_sequence ();
+  emit_libcall_block (insns, operands[0], final_result,
+                      gen_rtx_DIV (SImode, operands[1], operands[2]));
+
+  emit_label (lab1);
+  LABEL_NUSES (lab1) = 1;
+  return 1;
+}
+
+/* The function with address *ADDR is being called.  If the address
+   needs to be loaded from the GOT, emit the instruction to do so and
+   update *ADDR to point to the rtx for the loaded value.  */
+void
+nios2_adjust_call_address (rtx *addr)
+{
+  if (flag_pic
+      && (GET_CODE (*addr) == SYMBOL_REF || GET_CODE (*addr) == LABEL_REF))
+    {
+      rtx addr_orig;
+      crtl->uses_pic_offset_table = 1;
+      addr_orig = *addr;
+      *addr = gen_reg_rtx (GET_MODE (addr_orig));
+      emit_insn (gen_pic_load_call_addr (*addr,
+					 pic_offset_table_rtx, addr_orig));
+    }
+}
+
+
+
+/* Branches/Compares.  */
+
+/* Return in *ALT_CODE and *ALT_OP, an alternate equivalent constant
+   comparision, e.g. >= 1 into > 0.  */
+static void
+nios2_alternate_compare_const (enum rtx_code code, rtx op,
+			       enum rtx_code *alt_code, rtx *alt_op,
+			       enum machine_mode mode)
+{
+  HOST_WIDE_INT opval = INTVAL (op);
+  enum rtx_code scode = signed_condition (code);
+  *alt_code = ((code == EQ || code == NE) ? code
+	       /* The required conversion between [>,>=] and [<,<=] is captured
+		  by a reverse + swap of condition codes.  */
+	       : reverse_condition (swap_condition (code)));
+  *alt_op = ((scode == LT || scode == GE) ? gen_int_mode (opval - 1, mode)
+	     : (scode == LE || scode == GT) ? gen_int_mode (opval + 1, mode)
+	     : gen_int_mode (opval, mode));
+}
+
+/* Return true if the constant comparison is supported by nios2.  */
+static bool
+nios2_valid_compare_const_p (enum rtx_code code, rtx op)
+{
+  switch (code)
+    {
+    case EQ: case NE: case GE: case LT:
+      return SMALL_INT (INTVAL (op));
+    case GEU: case LTU:
+      return SMALL_INT_UNSIGNED (INTVAL (op));
+    default:
+      return false;
+    }
+}
+
+/* Return true if compares in MODE is supported, mainly for floating-point
+   modes.  */
+bool
+nios2_supported_compare_p (enum machine_mode mode)
+{
+  switch (mode)
+    {
+    case SFmode:
+      return (N2FPU_OP_ENABLED_P (fcmpeqs) && N2FPU_OP_ENABLED_P (fcmpnes)
+	      && (N2FPU_OP_ENABLED_P (fcmplts) || N2FPU_OP_ENABLED_P (fcmpgts))
+	      && (N2FPU_OP_ENABLED_P (fcmpges) || N2FPU_OP_ENABLED_P (fcmples)));
+
+    case DFmode:
+      return (N2FPU_OP_ENABLED_P (fcmpeqd) && N2FPU_OP_ENABLED_P (fcmpned)
+	      && (N2FPU_OP_ENABLED_P (fcmpltd) || N2FPU_OP_ENABLED_P (fcmpgtd))
+	      && (N2FPU_OP_ENABLED_P (fcmpged) || N2FPU_OP_ENABLED_P (fcmpled)));
+    default:
+      return true;
+    }
+}
+
+/* Checks and modifies the comparison in *CMP, *OP1, and *OP2 into valid
+   nios2 supported form. Returns true if success.  */
+bool
+nios2_validate_compare (enum machine_mode mode, rtx *cmp, rtx *op1, rtx *op2)
+{
+  enum rtx_code code = GET_CODE (*cmp);
+  enum rtx_code alt_code;
+  rtx alt_op2;
+
+  if (GET_MODE_CLASS (mode) == MODE_FLOAT)
+    {
+      if (nios2_fpu_compare_enabled (code, mode))
+	{
+	  *op1 = force_reg (mode, *op1);
+	  *op2 = force_reg (mode, *op2);
+	  goto rebuild_cmp;
+	}
+      else
+	{
+	  enum rtx_code rev_code = swap_condition (code);
+	  if (nios2_fpu_compare_enabled (rev_code, mode))
+	    {
+	      rtx tmp = *op1;
+	      *op1 = force_reg (mode, *op2);
+	      *op2 = force_reg (mode, tmp);
+	      code = rev_code;
+	      goto rebuild_cmp;
+	    }
+	  else
+	    return false;
+	}
+    }
+
+  if (!reg_or_0_operand (*op2, mode))
+    {
+      /* Create alternate constant compare.  */
+      nios2_alternate_compare_const (code, *op2, &alt_code, &alt_op2, mode);
+
+      /* If alterate op2 is zero(0), we can use it directly, possibly
+	 swapping the compare code.  */
+      if (alt_op2 == const0_rtx)
+	{
+	  code = alt_code;
+	  *op2 = alt_op2;
+	  goto check_rebuild_cmp;
+	}
+
+      /* Check if either constant compare can be used.  */
+      if (nios2_valid_compare_const_p (code, *op2))
+	return true;
+      else if (nios2_valid_compare_const_p (alt_code, alt_op2))
+	{
+	  code = alt_code;
+	  *op2 = alt_op2;
+	  goto rebuild_cmp;
+	}
+
+      /* We have to force op2 into a register now. Try to pick one
+	 with a lower cost.  */
+      if (! nios2_simple_const_p (*op2)
+	  && nios2_simple_const_p (alt_op2))
+	{
+	  code = alt_code;
+	  *op2 = alt_op2;
+	}
+      *op2 = force_reg (SImode, *op2);
+    }
+ check_rebuild_cmp:
+  if (code == GT || code == GTU || code == LE || code == LEU)
+    {
+      rtx t = *op1; *op1 = *op2; *op2 = t;
+      code = swap_condition (code);
+    }
+ rebuild_cmp:
+  *cmp = gen_rtx_fmt_ee (code, mode, *op1, *op2);
+  return true;
+}
+
+
+/* Addressing Modes.  */
+
+/* Implement TARGET_LEGITIMATE_CONSTANT_P.  */
+static bool
+nios2_legitimate_constant_p (enum machine_mode mode, rtx x)
+{
+  switch (GET_CODE (x))
+    {
+    case SYMBOL_REF:
+      return !SYMBOL_REF_TLS_MODEL (x);
+    case CONST:
+      {
+	rtx op = XEXP (x, 0);
+	if (GET_CODE (op) != PLUS)
+	  return false;
+	return (nios2_legitimate_constant_p (mode, XEXP (op, 0))
+		&& nios2_legitimate_constant_p (mode, XEXP (op, 1)));
+      }
+    default:
+      return true;
+    }
+}
+
+/* Implement TARGET_LEGITIMATE_ADDRESS_P.  */
+static bool
+nios2_legitimate_address_p (enum machine_mode mode ATTRIBUTE_UNUSED,
+			    rtx operand, bool strict)
+{
+  int ret_val = 0;
+
+  switch (GET_CODE (operand))
+    {
+      /* Direct.  */
+    case SYMBOL_REF:
+      if (SYMBOL_REF_TLS_MODEL (operand))
+	break;
+      
+      if (SYMBOL_REF_IN_NIOS2_SMALL_DATA_P (operand))
+        {
+          ret_val = 1;
+          break;
+        }
+      /* Else, fall through.  */
+    case LABEL_REF:
+    case CONST_INT:
+    case CONST:
+    case CONST_DOUBLE:
+      /* ??? In here I need to add gp addressing.  */
+      ret_val = 0;
+
+      break;
+
+      /* Register indirect.  */
+    case REG:
+      ret_val = REG_OK_FOR_BASE_P2 (operand, strict);
+      break;
+
+      /* Register indirect with displacement.  */
+    case PLUS:
+      {
+        rtx op0 = XEXP (operand, 0);
+        rtx op1 = XEXP (operand, 1);
+
+        if (REG_P (op0) && REG_P (op1))
+          ret_val = 0;
+        else if (REG_P (op0) && GET_CODE (op1) == CONST_INT)
+          ret_val = (REG_OK_FOR_BASE_P2 (op0, strict)
+		     && SMALL_INT (INTVAL (op1)));
+        else if (REG_P (op1) && GET_CODE (op0) == CONST_INT)
+          ret_val = (REG_OK_FOR_BASE_P2 (op1, strict)
+		     && SMALL_INT (INTVAL (op0)));
+        else
+          ret_val = 0;
+      }
+      break;
+
+    default:
+      ret_val = 0;
+      break;
+    }
+
+  return ret_val;
+}
+
+/* Return true if EXP should be placed in the small data section.  */
+static bool
+nios2_in_small_data_p (const_tree exp)
+{
+  /* We want to merge strings, so we never consider them small data.  */
+  if (TREE_CODE (exp) == STRING_CST)
+    return false;
+
+  if (TREE_CODE (exp) == VAR_DECL && DECL_SECTION_NAME (exp))
+    {
+      const char *section = TREE_STRING_POINTER (DECL_SECTION_NAME (exp));
+      /* ??? these string names need moving into
+         an array in some header file */
+      if (nios2_section_threshold > 0
+          && (strcmp (section, ".sbss") == 0
+              || strncmp (section, ".sbss.", 6) == 0
+              || strcmp (section, ".sdata") == 0
+              || strncmp (section, ".sdata.", 7) == 0))
+        return true;
+    }
+  else if (TREE_CODE (exp) == VAR_DECL)
+    {
+      HOST_WIDE_INT size = int_size_in_bytes (TREE_TYPE (exp));
+
+      /* If this is an incomplete type with size 0, then we can't put it
+         in sdata because it might be too big when completed.  */
+      if (size > 0 && (unsigned HOST_WIDE_INT)size <= nios2_section_threshold)
+        return true;
+    }
+
+  return false;
+}
+
+static void
+nios2_encode_section_info (tree decl, rtx rtl, int first)
+{
+  rtx symbol;
+  int flags;
+
+  default_encode_section_info (decl, rtl, first);
+
+  /* Careful not to prod global register variables.  */
+  if (GET_CODE (rtl) != MEM)
+    return;
+  symbol = XEXP (rtl, 0);
+  if (GET_CODE (symbol) != SYMBOL_REF)
+    return;
+
+  flags = SYMBOL_REF_FLAGS (symbol);
+
+  /* We don't want weak variables to be addressed with gp in case they end up 
+     with value 0 which is not within 2^15 of $gp.  */
+  if (DECL_P (decl) && DECL_WEAK (decl))
+    flags |= SYMBOL_FLAG_WEAK_DECL;
+
+  SYMBOL_REF_FLAGS (symbol) = flags;
+}
+
+static unsigned int
+nios2_section_type_flags (tree decl, const char *name, int reloc)
+{
+  unsigned int flags;
+
+  flags = default_section_type_flags (decl, name, reloc);
+
+  if (strcmp (name, ".sbss") == 0
+      || strncmp (name, ".sbss.", 6) == 0
+      || strcmp (name, ".sdata") == 0
+      || strncmp (name, ".sdata.", 7) == 0)
+    flags |= SECTION_SMALL;
+
+  return flags;
+}
+
+
+/* Position Independent Code related.  */
+
+/* Emit code to load the PIC register.  */
+static void
+nios2_load_pic_register (void)
+{
+  rtx tmp = gen_rtx_REG (Pmode, TEMP_REG_NUM);
+
+  emit_insn (gen_load_got_register (pic_offset_table_rtx, tmp));
+  emit_insn (gen_add3_insn (pic_offset_table_rtx, pic_offset_table_rtx, tmp));
+}
+
+/* Nonzero if the constant value X is a legitimate general operand
+   when generating PIC code.  It is given that flag_pic is on and
+   that X satisfies CONSTANT_P or is a CONST_DOUBLE.  */
+bool
+nios2_legitimate_pic_operand_p (rtx x)
+{
+  rtx inner;
+
+  /* UNSPEC_TLS is always PIC.  */
+  if (tls_mentioned_p (x))
+    return true;
+
+  if (GET_CODE (x) == SYMBOL_REF)
+    return false;
+  if (GET_CODE (x) == LABEL_REF)
+    return false;
+  if (GET_CODE (x) == CONST)
+    {
+      inner = XEXP (x, 0);
+      if (GET_CODE (inner) == PLUS
+	  && GET_CODE (XEXP (inner, 0)) == SYMBOL_REF)
+	return false;
+    }
+  return true;
+}
+
+rtx
+nios2_legitimize_pic_address (rtx orig,
+			      enum machine_mode mode ATTRIBUTE_UNUSED, rtx reg)
+{
+  if (GET_CODE (orig) == SYMBOL_REF
+      || GET_CODE (orig) == LABEL_REF)
+    {
+      if (reg == 0)
+	{
+	  gcc_assert (can_create_pseudo_p ());
+	  reg = gen_reg_rtx (Pmode);
+	}
+
+      emit_insn (gen_pic_load_addr (reg, pic_offset_table_rtx, orig));
+
+      crtl->uses_pic_offset_table = 1;
+
+      return reg;
+    }
+  else if (GET_CODE (orig) == CONST)
+    {
+      rtx base, offset;
+
+      if (GET_CODE (XEXP (orig, 0)) == PLUS
+	  && XEXP (XEXP (orig, 0), 0) == pic_offset_table_rtx)
+	return orig;
+
+      if (GET_CODE (XEXP (orig, 0)) == UNSPEC
+	  && IS_UNSPEC_TLS (XINT (XEXP (orig, 0), 1)))
+	return orig;
+
+      if (reg == 0)
+	{
+	  gcc_assert (can_create_pseudo_p ());
+	  reg = gen_reg_rtx (Pmode);
+	}
+
+      gcc_assert (GET_CODE (XEXP (orig, 0)) == PLUS);
+
+      base = nios2_legitimize_pic_address (XEXP (XEXP (orig, 0), 0), Pmode,
+					   reg);
+      offset = nios2_legitimize_pic_address (XEXP (XEXP (orig, 0), 1), Pmode,
+					     base == reg ? 0 : reg);
+
+      if (CONST_INT_P (offset))
+	{
+	  if (SMALL_INT (INTVAL (offset)))
+	    return plus_constant (base, INTVAL (offset));
+	  else
+	    offset = force_reg (Pmode, offset);
+	}
+
+      return gen_rtx_PLUS (Pmode, base, offset);
+    }
+
+  return orig;
+}
+
+/* Test for various thread-local symbols.  */
+
+/* Return TRUE if X is a thread-local symbol.  */
+static bool
+nios2_tls_symbol_p (rtx x)
+{
+  return (TARGET_HAVE_TLS && GET_CODE (x) == SYMBOL_REF
+	  && SYMBOL_REF_TLS_MODEL (x) != 0);
+}
+
+/* Implement TARGET_LEGITIMIZE_ADDRESS.  */
+static rtx
+nios2_legitimize_address (rtx x, rtx orig_x, enum machine_mode mode)
+{
+  if (nios2_tls_symbol_p (x))
+    return nios2_legitimize_tls_address (x);
+
+  if (flag_pic)
+    {
+      /* We need to find and carefully transform any SYMBOL and LABEL
+         references; so go back to the original address expression.  */
+      rtx new_x = nios2_legitimize_pic_address (orig_x, mode, NULL_RTX);
+
+      if (new_x != orig_x)
+        x = new_x;
+    }
+
+  return x;
+}
+
+
+/* Output assembly language related definitions.  */
+
+/* Print the operand OP to file stream
+   FILE modified by LETTER. LETTER
+   can be one of:
+     i: print "i" if OP is an immediate, except 0
+     o: print "io" if OP is volatile
+
+     z: for const0_rtx print $0 instead of 0
+     H: for %hiadj
+     L: for %lo
+     U: for upper half of 32 bit value
+     D: for the upper 32-bits of a 64-bit double value
+     R: prints reverse condition.  */
+static void
+nios2_print_operand (FILE *file, rtx op, int letter)
+{
+
+  switch (letter)
+    {
+    case 'i':
+      if (CONSTANT_P (op) && (op != const0_rtx))
+        fprintf (file, "i");
+      return;
+
+    case 'o':
+      if (GET_CODE (op) == MEM
+	  && ((MEM_VOLATILE_P (op) && TARGET_BYPASS_CACHE_VOLATILE)
+	      || TARGET_BYPASS_CACHE))
+        fprintf (file, "io");
+      return;
+
+    default:
+      break;
+    }
+
+  if (comparison_operator (op, VOIDmode))
+    {
+      enum rtx_code cond = GET_CODE (op);
+      if (letter == 0)
+	{
+	  fprintf (file, "%s", GET_RTX_NAME (cond));
+	  return;
+	}
+      if (letter == 'R')
+	{
+	  fprintf (file, "%s", GET_RTX_NAME (reverse_condition (cond)));
+	  return;
+	}
+    }
+
+  switch (GET_CODE (op))
+    {
+    case REG:
+      if (letter == 0 || letter == 'z')
+        {
+          fprintf (file, "%s", reg_names[REGNO (op)]);
+          return;
+        }
+      else if (letter == 'D')
+        {
+          fprintf (file, "%s", reg_names[REGNO (op)+1]);
+          return;
+        }
+      break;
+
+    case CONST_INT:
+      if (INTVAL (op) == 0 && letter == 'z')
+        {
+          fprintf (file, "zero");
+          return;
+        }
+      else if (letter == 'U')
+        {
+          HOST_WIDE_INT val = INTVAL (op);
+          rtx new_op;
+          val = (val / 65536) & 0xFFFF;
+          new_op = gen_int_mode (val, SImode);
+          output_addr_const (file, new_op);
+          return;
+        }
+      /* Else, fall through.  */
+
+    case CONST:
+    case LABEL_REF:
+    case SYMBOL_REF:
+    case CONST_DOUBLE:
+      if (letter == 0 || letter == 'z')
+        {
+          output_addr_const (file, op);
+          return;
+        }
+      else if (letter == 'H')
+        {
+          fprintf (file, "%%hiadj(");
+          output_addr_const (file, op);
+          fprintf (file, ")");
+          return;
+        }
+      else if (letter == 'L')
+        {
+          fprintf (file, "%%lo(");
+          output_addr_const (file, op);
+          fprintf (file, ")");
+          return;
+        }
+      break;
+
+
+    case SUBREG:
+    case MEM:
+      if (letter == 0)
+        {
+          output_address (op);
+          return;
+        }
+      break;
+
+    case CODE_LABEL:
+      if (letter == 0)
+        {
+          output_addr_const (file, op);
+          return;
+        }
+      break;
+
+    default:
+      break;
+    }
+
+  fprintf (stderr, "Missing way to print (%c) ", letter);
+  debug_rtx (op);
+  gcc_unreachable ();
+}
+
+static int
+gprel_constant (rtx op)
+{
+  if (GET_CODE (op) == SYMBOL_REF
+      && SYMBOL_REF_IN_NIOS2_SMALL_DATA_P (op))
+    return 1;
+  else if (GET_CODE (op) == CONST
+           && GET_CODE (XEXP (op, 0)) == PLUS)
+    return gprel_constant (XEXP (XEXP (op, 0), 0));
+  else
+    return 0;
+}
+
+static void
+nios2_print_operand_address (FILE *file, rtx op)
+{
+  switch (GET_CODE (op))
+    {
+    case CONST:
+    case CONST_INT:
+    case LABEL_REF:
+    case CONST_DOUBLE:
+    case SYMBOL_REF:
+      if (gprel_constant (op))
+        {
+          fprintf (file, "%%gprel(");
+          output_addr_const (file, op);
+          fprintf (file, ")(%s)", reg_names[GP_REGNO]);
+          return;
+        }
+
+      break;
+
+    case PLUS:
+      {
+        rtx op0 = XEXP (op, 0);
+        rtx op1 = XEXP (op, 1);
+
+        if (REG_P (op0) && CONSTANT_P (op1))
+          {
+            output_addr_const (file, op1);
+            fprintf (file, "(%s)", reg_names[REGNO (op0)]);
+            return;
+          }
+        else if (REG_P (op1) && CONSTANT_P (op0))
+          {
+            output_addr_const (file, op0);
+            fprintf (file, "(%s)", reg_names[REGNO (op1)]);
+            return;
+          }
+      }
+      break;
+
+    case REG:
+      fprintf (file, "0(%s)", reg_names[REGNO (op)]);
+      return;
+
+    case MEM:
+      {
+        rtx base = XEXP (op, 0);
+        nios2_print_operand_address (file, base);
+        return;
+      }
+    default:
+      break;
+    }
+
+  fprintf (stderr, "Missing way to print address\n");
+  debug_rtx (op);
+  gcc_unreachable ();
+}
+
+static void
+nios2_output_dwarf_dtprel (FILE *file, int size, rtx x)
+{
+  gcc_assert (size == 4);
+  fprintf (file, "\t.4byte\t%%tls_ldo(");
+  output_addr_const (file, x);
+  fprintf (file, ")");
+}
+
+static void
+nios2_asm_function_prologue (FILE *file, HOST_WIDE_INT size ATTRIBUTE_UNUSED)
+{
+  if (flag_verbose_asm || flag_debug_asm)
+    {
+      compute_frame_size ();
+      dump_frame_size (file);
+    }
+}
+
+/* Emit assembly of custom FPU instructions.  */
+const char*
+nios2_fpu_insn_asm (enum n2fpu_code code)
+{
+  static char buf[256];
+  const char *op1, *op2, *op3;
+  int ln = 256, n = 0;
+  
+  int N = N2FPU_N (code);
+  int num_operands = N2FPU (code).num_operands;
+  const char* insn_name = N2FPU_NAME (code);
+  tree ftype = nios2_ftype (N2FPU_FTCODE (code));
+  enum machine_mode dst_mode = TYPE_MODE (TREE_TYPE (ftype));
+  enum machine_mode src_mode = TYPE_MODE (TREE_VALUE (TYPE_ARG_TYPES (ftype)));
+
+  /* Prepare X register for DF input operands.  */
+  if (GET_MODE_SIZE (src_mode) == 8 && num_operands == 3)
+    n = snprintf (buf, ln, "custom\t%d, zero, %%1, %%D1 # fwrx %%1\n\t",
+		  N2FPU_N (n2fpu_fwrx));
+
+  if (src_mode == SFmode)
+    {
+      if (dst_mode == VOIDmode)
+	{
+	  /* The fwry case.  */
+	  op1 = op3 = "zero";
+	  op2 = "%0";
+	  num_operands -= 1;
+	}
+      else
+	{
+	  op1 = "%0"; op2 = "%1";
+	  op3 = (num_operands == 2 ? "zero" : "%2");
+	}
+    }
+  else if (src_mode == DFmode)
+    {
+      if (dst_mode == VOIDmode)
+	{
+	  /* The fwrx case.  */
+	  op1 = "zero";
+	  op2 = "%0";
+	  op3 = "%D0";
+	  num_operands -= 1;
+	}
+      else
+	{
+	  op1 = (dst_mode == DFmode ? "%D0" : "%0");
+	  op2 = (num_operands == 2 ? "%1" : "%2");
+	  op3 = (num_operands == 2 ? "%D1" : "%D2");
+	}
+    }
+  else if (src_mode == VOIDmode)
+    {
+      /* frdxlo, frdxhi, frdy cases.  */
+      gcc_assert (dst_mode == SFmode);
+      op1 = "%0";
+      op2 = op3 = "zero";
+    }
+  else if (src_mode == SImode)
+    {
+      /* Conversion operators.  */
+      gcc_assert (num_operands == 2);
+      op1 = (dst_mode == DFmode ? "%D0" : "%0");
+      op2 = "%1";
+      op3 = "zero";
+    }
+  else
+    gcc_unreachable ();
+
+  /* Main instruction string.  */
+  n += snprintf (buf + n, ln - n, "custom\t%d, %s, %s, %s # %s %%0%s%s",
+		 N, op1, op2, op3, insn_name,
+		 (num_operands >= 2 ? ", %1" : ""),
+		 (num_operands == 3 ? ", %2" : ""));
+
+  /* Extraction of Y register for DF results.  */
+  if (dst_mode == DFmode)
+    snprintf (buf + n, ln - n, "\n\tcustom\t%d, %%0, zero, zero # frdy %%0",
+	      N2FPU_N (n2fpu_frdy));
+  return buf;
+}
+
+
+
+/* Instruction scheduler related.  */
+
+static int
+nios2_issue_rate (void)
+{
+#ifdef MAX_DFA_ISSUE_RATE
+  return MAX_DFA_ISSUE_RATE;
+#else
+  return 1;
+#endif
+}
+
+
+
+/* Function argument related.  */
+
+void
+nios2_init_cumulative_args (CUMULATIVE_ARGS *cum,
+			    tree fntype ATTRIBUTE_UNUSED,
+			    rtx libname ATTRIBUTE_UNUSED,
+			    tree fndecl ATTRIBUTE_UNUSED,
+			    int n_named_args ATTRIBUTE_UNUSED)
+{
+  cum->regs_used = 0;
+}
+
+/* Define where to put the arguments to a function.  Value is zero to
+   push the argument on the stack, or a hard register in which to
+   store the argument.
+
+   MODE is the argument's machine mode.
+   TYPE is the data type of the argument (as a tree).
+   This is null for libcalls where that information may
+   not be available.
+   CUM is a variable of type CUMULATIVE_ARGS which gives info about
+   the preceding args and about the function being called.
+   NAMED is nonzero if this argument is a named parameter
+   (otherwise it is an extra parameter matching an ellipsis).  */
+
+static rtx
+nios2_function_arg (cumulative_args_t cum_v, enum machine_mode mode,
+		    const_tree type ATTRIBUTE_UNUSED,
+		    bool named ATTRIBUTE_UNUSED)
+{
+  CUMULATIVE_ARGS *cum = get_cumulative_args (cum_v); 
+  rtx return_rtx = NULL_RTX;
+
+  if (cum->regs_used < NUM_ARG_REGS)
+    return_rtx = gen_rtx_REG (mode, FIRST_ARG_REGNO + cum->regs_used);
+
+  return return_rtx;
+}
+
+/* Return number of bytes, at the beginning of the argument, that must be
+   put in registers.  0 is the argument is entirely in registers or entirely
+   in memory.  */
+
+static int
+nios2_arg_partial_bytes (cumulative_args_t cum_v,
+                         enum machine_mode mode, tree type,
+                         bool named ATTRIBUTE_UNUSED)
+{
+  CUMULATIVE_ARGS *cum = get_cumulative_args (cum_v); 
+  HOST_WIDE_INT param_size;
+
+  if (mode == BLKmode)
+    {
+      param_size = int_size_in_bytes (type);
+      if (param_size < 0)
+        internal_error
+          ("Do not know how to handle large structs or variable length types");
+    }
+  else
+    param_size = GET_MODE_SIZE (mode);
+
+  /* Convert to words (round up).  */
+  param_size = (3 + param_size) / 4;
+
+  if (cum->regs_used < NUM_ARG_REGS
+      && cum->regs_used + param_size > NUM_ARG_REGS)
+    return (NUM_ARG_REGS - cum->regs_used) * UNITS_PER_WORD;
+  else
+    return 0;
+}
+
+/* Update the data in CUM to advance over an argument
+   of mode MODE and data type TYPE.
+   (TYPE is null for libcalls where that information may not be available.)  */
+
+static void
+nios2_function_arg_advance (cumulative_args_t cum_v, enum machine_mode mode,
+			    const_tree type ATTRIBUTE_UNUSED,
+			    bool named ATTRIBUTE_UNUSED)
+{
+  CUMULATIVE_ARGS *cum = get_cumulative_args (cum_v); 
+  HOST_WIDE_INT param_size;
+
+  if (mode == BLKmode)
+    {
+      param_size = int_size_in_bytes (type);
+      if (param_size < 0)
+        internal_error
+          ("Do not know how to handle large structs or variable length types");
+    }
+  else
+    param_size = GET_MODE_SIZE (mode);
+
+  /* Convert to words (round up).  */
+  param_size = (3 + param_size) / 4;
+
+  if (cum->regs_used + param_size > NUM_ARG_REGS)
+    cum->regs_used = NUM_ARG_REGS;
+  else
+    cum->regs_used += param_size;
+
+  return;
+}
+
+enum direction
+nios2_function_arg_padding (enum machine_mode mode, const_tree type)
+{
+  /* On little-endian targets, the first byte of every stack argument
+     is passed in the first byte of the stack slot.  */
+  if (!BYTES_BIG_ENDIAN)
+    return upward;
+
+  /* Otherwise, integral types are padded downward: the last byte of a
+     stack argument is passed in the last byte of the stack slot.  */
+  if (type != 0
+      ? INTEGRAL_TYPE_P (type) || POINTER_TYPE_P (type)
+      : GET_MODE_CLASS (mode) == MODE_INT)
+    return downward;
+
+  /* Arguments smaller than a stack slot are padded downward.  */
+  if (mode != BLKmode)
+    return (GET_MODE_BITSIZE (mode) >= PARM_BOUNDARY) ? upward : downward;
+  else
+    return ((int_size_in_bytes (type) >= (PARM_BOUNDARY / BITS_PER_UNIT))
+            ? upward : downward);
+}
+
+enum direction
+nios2_block_reg_padding (enum machine_mode mode, tree type,
+                         int first ATTRIBUTE_UNUSED)
+{
+  /* ??? Do we need to treat floating point specially, ala MIPS?  */
+  return nios2_function_arg_padding (mode, type);
+}
+
+
+/* Emit RTL insns to initialize the variable parts of a trampoline.
+   FNADDR is an RTX for the address of the function's pure code.
+   CXT is an RTX for the static chain value for the function.
+   On Nios II, we handle this by a library call.  */
+static void
+nios2_trampoline_init (rtx m_tramp, tree fndecl, rtx cxt)
+{
+  rtx fnaddr = XEXP (DECL_RTL (fndecl), 0);
+  rtx ctx_reg = force_reg (Pmode, cxt);
+  rtx addr = force_reg (Pmode, XEXP (m_tramp, 0));
+
+  emit_library_call (gen_rtx_SYMBOL_REF (Pmode, "__trampoline_setup"),
+		     LCT_NORMAL, VOIDmode, 3,
+		     addr, Pmode,
+		     fnaddr, Pmode,
+		     ctx_reg, Pmode);
+}
+
+static rtx
+nios2_function_value (const_tree ret_type, const_tree fn ATTRIBUTE_UNUSED,
+		      bool outgoing ATTRIBUTE_UNUSED)
+{
+  return gen_rtx_REG (TYPE_MODE (ret_type), FIRST_RETVAL_REGNO);
+}
+
+static rtx
+nios2_libcall_value (enum machine_mode mode, const_rtx fun ATTRIBUTE_UNUSED)
+{
+  return gen_rtx_REG (mode, FIRST_RETVAL_REGNO);
+}
+
+static bool
+nios2_function_value_regno_p (const unsigned int regno)
+{
+  return (regno == FIRST_RETVAL_REGNO);
+}
+
+static bool
+nios2_return_in_memory (const_tree type, const_tree fntype ATTRIBUTE_UNUSED)
+{
+  return (int_size_in_bytes (type) > (2 * UNITS_PER_WORD)
+	  || int_size_in_bytes (type) == -1);
+}
+
+/* ??? It may be possible to eliminate the copyback and implement
+   my own va_arg type, but that is more work for now.  */
+static void
+nios2_setup_incoming_varargs (cumulative_args_t cum_v,
+                              enum machine_mode mode, tree type,
+                              int *pretend_size, int second_time)
+{
+  CUMULATIVE_ARGS *cum = get_cumulative_args (cum_v); 
+  CUMULATIVE_ARGS local_cum;
+  cumulative_args_t local_cum_v = pack_cumulative_args (&local_cum);
+  int regs_to_push;
+  int pret_size;
+
+  local_cum = *cum;
+  nios2_function_arg_advance (local_cum_v, mode, type, 1);
+
+  regs_to_push = NUM_ARG_REGS - local_cum.regs_used;
+
+  if (!second_time && regs_to_push > 0)
+    {
+      rtx ptr = virtual_incoming_args_rtx;
+      rtx mem = gen_rtx_MEM (BLKmode, ptr);
+      emit_insn (gen_blockage ());
+      move_block_from_reg (local_cum.regs_used + FIRST_ARG_REGNO, mem,
+			   regs_to_push);
+      emit_insn (gen_blockage ());
+    }
+
+  pret_size = regs_to_push * UNITS_PER_WORD;
+
+  if (pret_size)
+    *pretend_size = pret_size;
+}
+
+
+
+/* Init FPU builtins.  */
+static void
+nios2_init_fpu_builtins (int start_code)
+{
+  char builtin_name[64] = "__builtin_custom_";
+  unsigned int i, n = strlen ("__builtin_custom_");
+
+  for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+    {
+      snprintf (builtin_name + n, sizeof (builtin_name) - n,
+		"%s", N2FPU_NAME (i));
+      add_builtin_function (builtin_name, nios2_ftype (N2FPU_FTCODE (i)),
+			    start_code + i, BUILT_IN_MD, NULL, NULL_TREE);
+    }
+}
+
+static rtx
+nios2_expand_fpu_builtin (tree exp, unsigned int code, rtx target)
+{
+  struct expand_operand ops[MAX_RECOG_OPERANDS];
+  enum insn_code icode = N2FPU_ICODE (code);
+  int nargs, argno, opno = 0;
+  int num_operands = N2FPU (code).num_operands;
+  enum machine_mode dst_mode = TYPE_MODE (TREE_TYPE (exp));
+  bool has_target_p = (dst_mode != VOIDmode);
+
+  if (N2FPU_N (code) < 0)
+    fatal_error ("Cannot call `__builtin_custom_%s' without specifying switch"
+		 " `-mcustom-%s'", N2FPU_NAME (code), N2FPU_NAME (code));
+  if (has_target_p)
+    create_output_operand (&ops[opno++], target, dst_mode);
+  else
+    /* Subtract away the count of the VOID return, mainly for fwrx/fwry.   */
+    num_operands -= 1;
+  nargs = call_expr_nargs (exp);
+  for (argno = 0; argno < nargs; argno++)
+    {
+      tree arg = CALL_EXPR_ARG (exp, argno);
+      create_input_operand (&ops[opno++], expand_normal (arg),
+			    TYPE_MODE (TREE_TYPE (arg)));
+    }
+  if (!maybe_expand_insn (icode, num_operands, ops))
+    {
+      error ("invalid argument to built-in function");
+      return has_target_p ? gen_reg_rtx (ops[0].mode) : const0_rtx;
+    }
+  return has_target_p ? ops[0].value : const0_rtx;
+}
+
+
+/* Nios II has custom instruction built-in functions of the forms:
+   __builtin_custom_n
+   __builtin_custom_nX
+   __builtin_custom_nXX
+   __builtin_custom_Xn
+   __builtin_custom_XnX
+   __builtin_custom_XnXX
+
+   where each X could be either 'i' (int), 'f' (float), or 'p' (void*).
+   Therefore with 0-1 return values, and 0-2 arguments, we have a
+   total of (3 + 1) * (1 + 3 + 9) == 52 custom builtin functions.
+*/
+#define NUM_CUSTOM_BUILTINS ((3 + 1) * (1 + 3 + 9))
+static char custom_builtin_name[NUM_CUSTOM_BUILTINS][5];
+
+static void
+nios2_init_custom_builtins (int start_code)
+{
+  tree builtin_ftype, ret_type;
+  char builtin_name[32] = "__builtin_custom_";
+  int n = strlen ("__builtin_custom_");
+  int builtin_code = 0;
+  int lhs, rhs1, rhs2;
+
+  struct { tree type; const char* c; } op[4];
+  /* z */ op[0].c = "";  op[0].type = NULL_TREE;
+  /* f */ op[1].c = "f"; op[1].type = float_type_node;
+  /* i */ op[2].c = "i"; op[2].type = integer_type_node;
+  /* p */ op[3].c = "p"; op[3].type = ptr_type_node;
+
+  /* This way of constructing the function tree types will slightly 
+     overlap with the N2_FTYPES list used by other builtins.  */
+
+  for (lhs = 0; lhs < 4; lhs++)
+    for (rhs1 = 0; rhs1 < 4; rhs1++)
+      for (rhs2 = 0; rhs2 < 4; rhs2++)
+	{
+	  if (rhs1 == 0 && rhs2 != 0)
+	    continue;
+	  ret_type = (op[lhs].type ? op[lhs].type : void_type_node);
+	  builtin_ftype
+	    = build_function_type_list (ret_type, integer_type_node,
+					op[rhs1].type, op[rhs2].type,
+					NULL_TREE);
+	  snprintf (builtin_name + n, 32 - n, "%sn%s%s",
+		    op[lhs].c, op[rhs1].c, op[rhs2].c);
+	  /* Save copy of parameter string into custom_builtin_name[].  */
+	  strncpy (custom_builtin_name[builtin_code], builtin_name + n, 5);
+	  add_builtin_function (builtin_name, builtin_ftype,
+				start_code + builtin_code,
+				BUILT_IN_MD, NULL, NULL_TREE);
+	  builtin_code += 1;
+	}
+}
+
+static rtx
+nios2_expand_custom_builtin (tree exp, unsigned int index, rtx target)
+{
+  bool has_target_p = (TREE_TYPE (exp) != void_type_node);
+  enum machine_mode tmode = VOIDmode;
+  int nargs, argno;
+  rtx value, insn, unspec_args[3];
+  tree arg;
+
+  /* XnXX form.  */
+  if (has_target_p)
+    {
+      tmode = TYPE_MODE (TREE_TYPE (exp));
+      if (!target || GET_MODE (target) != tmode
+	  || !REG_P (target))
+	target = gen_reg_rtx (tmode);
+    }
+
+  nargs = call_expr_nargs (exp);
+  for (argno = 0; argno < nargs; argno++)
+    {
+      arg = CALL_EXPR_ARG (exp, argno);
+      value = expand_normal (arg);
+      unspec_args[argno] = value;
+      if (argno == 0)
+	{
+	  if (!custom_insn_opcode (value, VOIDmode))
+	    error ("Custom instruction opcode must be compile time "
+		   "constant in the range 0-255 for __builtin_custom_%s",
+		   custom_builtin_name[index]);
+	}
+      else
+	/* For other arguments, force into a register.  */
+	unspec_args[argno] = force_reg (TYPE_MODE (TREE_TYPE (arg)),
+					unspec_args[argno]);
+    }
+  /* Fill remaining unspec operands with zero.  */
+  for (; argno < 3; argno++)
+    unspec_args[argno] = const0_rtx;
+
+  insn = (has_target_p
+	  ? gen_rtx_SET (VOIDmode, target,
+			 gen_rtx_UNSPEC_VOLATILE (tmode,
+						  gen_rtvec_v (3, unspec_args),
+						  UNSPECV_CUSTOM_XNXX))
+	  : gen_rtx_UNSPEC_VOLATILE (VOIDmode, gen_rtvec_v (3, unspec_args),
+				     UNSPECV_CUSTOM_NXX));
+  emit_insn (insn);
+  return has_target_p ? target : const0_rtx;
+}
+
+
+
+
+/* Main definition of built-in functions. Nios II has a small number of fixed
+   builtins, plus a large number of FPU insn builtins, and builtins for
+   generating custom instructions.  */
+
+struct nios2_builtin_desc
+{
+  enum insn_code icode;
+  enum nios2_ftcode ftype;
+  const char* name;
+};
+
+#define N2_BUILTINS					\
+  N2_BUILTIN_DEF (sync,   N2_FTYPE_VOID_VOID)		\
+  N2_BUILTIN_DEF (ldbio,  N2_FTYPE_SI_CVPTR)		\
+  N2_BUILTIN_DEF (ldbuio, N2_FTYPE_UI_CVPTR)		\
+  N2_BUILTIN_DEF (ldhio,  N2_FTYPE_SI_CVPTR)		\
+  N2_BUILTIN_DEF (ldhuio, N2_FTYPE_UI_CVPTR)		\
+  N2_BUILTIN_DEF (ldwio,  N2_FTYPE_SI_CVPTR)		\
+  N2_BUILTIN_DEF (stbio,  N2_FTYPE_VOID_VPTR_SI)	\
+  N2_BUILTIN_DEF (sthio,  N2_FTYPE_VOID_VPTR_SI)	\
+  N2_BUILTIN_DEF (stwio,  N2_FTYPE_VOID_VPTR_SI)	\
+  N2_BUILTIN_DEF (rdctl,  N2_FTYPE_SI_SI)		\
+  N2_BUILTIN_DEF (wrctl,  N2_FTYPE_VOID_SI_SI)
+
+enum nios2_builtin_code {
+#define N2_BUILTIN_DEF(name, ftype) NIOS2_BUILTIN_ ## name,
+  N2_BUILTINS
+#undef N2_BUILTIN_DEF
+  NUM_FIXED_NIOS2_BUILTINS
+};
+
+static const struct nios2_builtin_desc nios2_builtins[] = {
+#define N2_BUILTIN_DEF(name, ftype)			\
+  { CODE_FOR_ ## name, ftype, "__builtin_" #name },
+  N2_BUILTINS
+#undef N2_BUILTIN_DEF
+};
+
+/* Start/ends of FPU/custom insn builtin index ranges.  */
+static unsigned int nios2_fpu_builtin_base;
+static unsigned int nios2_custom_builtin_base;
+static unsigned int nios2_custom_builtin_end;
+
+static void
+nios2_init_builtins (void)
+{
+  unsigned int i;
+
+  /* Initialize fixed builtins.  */
+  for (i = 0; i < ARRAY_SIZE (nios2_builtins); i++)
+    {
+      const struct nios2_builtin_desc *d = &nios2_builtins[i];
+      add_builtin_function (d->name, nios2_ftype (d->ftype), i,
+			    BUILT_IN_MD, NULL, NULL);
+    }
+
+  /* Initialize FPU builtins.  */
+  nios2_fpu_builtin_base = ARRAY_SIZE (nios2_builtins);
+  nios2_init_fpu_builtins (nios2_fpu_builtin_base);
+
+  /* Initialize custom insn builtins.  */
+  nios2_custom_builtin_base
+    = nios2_fpu_builtin_base + ARRAY_SIZE (nios2_fpu_insn);
+  nios2_custom_builtin_end
+    = nios2_custom_builtin_base + NUM_CUSTOM_BUILTINS;
+  nios2_init_custom_builtins (nios2_custom_builtin_base);
+}
+
+static rtx
+nios2_expand_builtin_insn (const struct nios2_builtin_desc *d, int n,
+			   struct expand_operand* ops, bool has_target_p)
+{
+  if (maybe_expand_insn (d->icode, n, ops))
+    return has_target_p ? ops[0].value : const0_rtx;
+  else
+    {
+      error ("invalid argument to built-in function %s", d->name);
+      return has_target_p ? gen_reg_rtx (ops[0].mode) : const0_rtx;	  
+    } 
+}
+
+static rtx
+nios2_expand_ldstio_builtin  (tree exp, rtx target,
+			      const struct nios2_builtin_desc *d)
+{
+  bool has_target_p;
+  rtx addr, mem, val;
+  struct expand_operand ops[MAX_RECOG_OPERANDS];
+  enum machine_mode mode = insn_data[d->icode].operand[0].mode;
+
+  addr = expand_normal (CALL_EXPR_ARG (exp, 0));
+  mem = gen_rtx_MEM (mode, addr);
+
+  if (insn_data[d->icode].operand[0].allows_mem)
+    {
+      /* stxio  */
+      val = force_reg (mode, expand_normal (CALL_EXPR_ARG (exp, 1)));
+      val = simplify_gen_subreg (mode, val, GET_MODE (val), 0);
+      create_output_operand (&ops[0], mem, mode);
+      create_input_operand (&ops[1], val, mode);
+      has_target_p = false;
+    }
+  else
+    {
+      /* ldxio */
+      create_output_operand (&ops[0], target, mode);
+      create_input_operand (&ops[1], mem, mode);
+      has_target_p = true;
+    }
+  return nios2_expand_builtin_insn (d, 2, ops, has_target_p);
+}
+
+static rtx
+nios2_expand_rdwrctl_builtin (tree exp, rtx target,
+			     const struct nios2_builtin_desc *d)
+{
+  bool has_target_p = (insn_data[d->icode].operand[0].predicate
+		       == register_operand);
+  rtx ctlcode = expand_normal (CALL_EXPR_ARG (exp, 0));
+  struct expand_operand ops[MAX_RECOG_OPERANDS];
+  if (!rdwrctl_operand (ctlcode, VOIDmode))
+    {
+      error ("Control register number must be in range 0-31 for %s",
+	     d->name);
+      return has_target_p ? gen_reg_rtx (SImode) : const0_rtx;
+    }
+  if (has_target_p)
+    {
+      create_output_operand (&ops[0], target, SImode);
+      create_integer_operand (&ops[1], INTVAL (ctlcode));
+    }
+  else
+    {
+      rtx val = expand_normal (CALL_EXPR_ARG (exp, 1));
+      create_integer_operand (&ops[0], INTVAL (ctlcode));
+      create_input_operand (&ops[1], val, SImode);
+    }
+  return nios2_expand_builtin_insn (d, 2, ops, has_target_p);
+}
+
+/* Expand an expression EXP that calls a built-in function,
+   with result going to TARGET if that's convenient
+   (and in mode MODE if that's convenient).
+   SUBTARGET may be used as the target for computing one of EXP's operands.
+   IGNORE is nonzero if the value is to be ignored.  */
+
+static rtx
+nios2_expand_builtin (tree exp, rtx target, rtx subtarget ATTRIBUTE_UNUSED,
+                      enum machine_mode mode ATTRIBUTE_UNUSED,
+		      int ignore ATTRIBUTE_UNUSED)
+{
+  tree fndecl = TREE_OPERAND (CALL_EXPR_FN (exp), 0);
+  unsigned int fcode = DECL_FUNCTION_CODE (fndecl);
+
+  if (fcode < nios2_fpu_builtin_base)
+    {
+      const struct nios2_builtin_desc *d = &nios2_builtins[fcode];
+
+      switch (fcode)
+	{
+	case NIOS2_BUILTIN_sync:
+	  emit_insn (gen_sync ());
+	  return const0_rtx;
+
+	case NIOS2_BUILTIN_ldbio:
+	case NIOS2_BUILTIN_ldbuio:
+	case NIOS2_BUILTIN_ldhio:
+	case NIOS2_BUILTIN_ldhuio:
+	case NIOS2_BUILTIN_ldwio:
+	case NIOS2_BUILTIN_stbio:
+	case NIOS2_BUILTIN_sthio:
+	case NIOS2_BUILTIN_stwio:
+	  return nios2_expand_ldstio_builtin (exp, target, d);
+
+	case NIOS2_BUILTIN_rdctl:
+	case NIOS2_BUILTIN_wrctl:
+	  return nios2_expand_rdwrctl_builtin (exp, target, d);
+
+	default:
+	  gcc_unreachable ();
+	}
+    }
+  else if (fcode < nios2_custom_builtin_base)
+    /* FPU builtin range.  */
+    return nios2_expand_fpu_builtin (exp, fcode - nios2_fpu_builtin_base,
+				     target);
+  else if (fcode < nios2_custom_builtin_end)
+    /* Custom insn builtin range.  */
+    return nios2_expand_custom_builtin (exp, fcode - nios2_custom_builtin_base,
+					target);
+  else
+    gcc_unreachable ();
+}
+
+static void
+nios2_init_libfuncs (void)
+{
+  /* For Linux, we have access to kernel support for atomic operations.  */
+  if (TARGET_LINUX_ABI)
+    init_sync_libfuncs (UNITS_PER_WORD);
+}
+
+
+
+
+/* Register a custom code use, and signal error if a conflict was found.  */
+static void
+nios2_register_custom_code (unsigned int N, enum nios2_ccs_code status,
+			    int index)
+{
+  gcc_assert (N <= 255);
+
+  if (status == CCS_FPU)
+    {
+      if (custom_code_status[N] == CCS_FPU && index != custom_code_index[N])
+	{
+	  custom_code_conflict = true;
+	  error ("switch `-mcustom-%s' conflicts with switch `-mcustom-%s'",
+		 N2FPU_NAME (custom_code_index[N]), N2FPU_NAME (index));
+	}
+      else if (custom_code_status[N] == CCS_BUILTIN_CALL)
+	{
+	  custom_code_conflict = true;
+	  error ("call to `__builtin_custom_%s' conflicts with switch "
+		 "`-mcustom-%s'", custom_builtin_name[custom_code_index[N]],
+		 N2FPU_NAME (index));
+	}
+    }
+  else if (status == CCS_BUILTIN_CALL)
+    {
+      if (custom_code_status[N] == CCS_FPU)
+	{
+	  custom_code_conflict = true;
+	  error ("call to `__builtin_custom_%s' conflicts with switch "
+		 "`-mcustom-%s'", custom_builtin_name[index],
+		 N2FPU_NAME (custom_code_index[N]));
+	}
+	  /* Code conflicts between different __builtin_custom_xnxx calls
+	     do not seem to be checked. ???  */
+    }
+  else
+    gcc_unreachable ();
+
+  custom_code_status[N] = status;
+  custom_code_index[N] = index;
+}
+
+/* Mark a custom code as not in use.  */
+static void
+nios2_deregister_custom_code (unsigned int N)
+{
+  if (N <= 255)
+    {
+      custom_code_status[N] = CCS_UNUSED;
+      custom_code_index[N] = 0;
+    }
+}
+
+/* Target attributes can affect per-function option state, so we need to
+   save/restore the custom code tracking info using the
+   TARGET_OPTION_SAVE/TARGET_OPTION_RESTORE hooks.  */
+
+static void
+nios2_option_save (struct cl_target_option *ptr)
+{
+  unsigned int i;
+  for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+    ptr->saved_fpu_custom_code[i] = N2FPU_N (i);
+  memcpy (ptr->saved_custom_code_status, custom_code_status,
+	  sizeof (custom_code_status));
+  memcpy (ptr->saved_custom_code_index, custom_code_index,
+	  sizeof (custom_code_index));
+}
+
+static void
+nios2_option_restore (struct cl_target_option *ptr)
+{
+  unsigned int i;
+  for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+    N2FPU_N (i) = ptr->saved_fpu_custom_code[i];
+  memcpy (custom_code_status, ptr->saved_custom_code_status,
+	  sizeof (custom_code_status));
+  memcpy (custom_code_index, ptr->saved_custom_code_index,
+	  sizeof (custom_code_index));
+}
+
+/* Inner function to process the attribute((target(...))), take an argument and
+   set the current options from the argument. If we have a list, recursively go
+   over the list.  */
+
+static bool
+nios2_valid_target_attribute_rec (tree args)
+{
+  if (TREE_CODE (args) == TREE_LIST)
+    {
+      bool ret = true;
+      for (; args; args = TREE_CHAIN (args))
+	if (TREE_VALUE (args)
+	    && !nios2_valid_target_attribute_rec (TREE_VALUE (args)))
+	  ret = false;
+      return ret;
+    }
+  else if (TREE_CODE (args) == STRING_CST)
+    {
+      char *argstr = ASTRDUP (TREE_STRING_POINTER (args));
+      while (argstr && *argstr != '\0')
+	{
+	  bool no_opt = false, end_p = false;
+	  char *eq = NULL, *p;
+	  while (ISSPACE (*argstr))
+	    argstr++;
+	  p = argstr;
+	  while (*p != '\0' && *p != ',')
+	    {
+	      if (!eq && *p == '=')
+		eq = p;
+	      ++p;
+	    }
+	  if (*p == '\0')
+	    end_p = true;
+	  else
+	    *p = '\0';
+	  if (eq) *eq = '\0';
+
+	  if (!strncmp (argstr, "no-", 3))
+	    {
+	      no_opt = true;
+	      argstr += 3;
+	    }
+	  if (!strncmp (argstr, "custom-fpu-cfg", 14))
+	    {
+	      if (no_opt)
+		{
+		  error ("custom-fpu-cfg option does not support `no-'");
+		  return false;
+		}
+	      if (!eq)
+		{
+		  error ("custom-fpu-cfg option requires configuration"
+			 " argument");
+		  return false;
+		}
+	      /* Increment and skip whitespace.  */
+	      while (ISSPACE (*(++eq))) ;
+	      nios2_handle_custom_fpu_cfg (eq, true);
+	    }
+	  else if (!strncmp (argstr, "custom-", 7))
+	    {
+	      int code = -1;
+	      unsigned int i;
+	      for (i = 0; i < ARRAY_SIZE (nios2_fpu_insn); i++)
+		if (!strncmp (argstr + 7, N2FPU_NAME (i),
+			      strlen (N2FPU_NAME (i))))
+		  {
+		    /* Found insn.  */
+		    code = i;
+		    break;
+		  }
+	      if (code >= 0)
+		{
+		  if (no_opt)
+		    {
+		      if (eq)
+			{
+			  error ("`no-custom-%s' does not accept arguments",
+				 N2FPU_NAME (code));
+			  return false;
+			}
+		      /* Disable option by setting to -1.  */
+		      nios2_deregister_custom_code (N2FPU_N (code));
+		      N2FPU_N (code) = -1;
+		    }
+		  else
+		    {
+		      char *t;
+		      if (eq)
+			while (ISSPACE (*(++eq))) ;
+		      if (!eq || eq == p)
+			{
+			  error ("`custom-%s=' requires argument",
+				 N2FPU_NAME (code));
+			  return false;
+			}
+		      for (t = eq; t != p; ++t)
+			{
+			  if (ISSPACE (*t))
+			    continue;
+			  if (!ISDIGIT (*t))
+			    {			 
+			      error ("`custom-%s=' argument requires "
+				     "numeric digits", N2FPU_NAME (code));
+			      return false;
+			    }
+			}
+		      /* Set option to argument.  */
+		      N2FPU_N (code) = atoi (eq);
+		      nios2_handle_custom_fpu_insn_option (code);
+		    }
+		}
+	      else
+		{
+		  error ("`custom-%s=' is not recognised as FPU instruction",
+			 argstr + 7);
+		  return false;
+		}		
+	    }
+	  else
+	    {
+	      error ("`%s' is unknown", argstr);
+	      return false;
+	    }
+
+	  if (end_p)
+	    break;
+	  else
+	    argstr = p + 1;
+	}
+      return true;
+    }
+  else
+    gcc_unreachable ();
+}
+
+/* Return a TARGET_OPTION_NODE tree of the target options listed or NULL.  */
+
+static tree
+nios2_valid_target_attribute_tree (tree args)
+{
+  if (!nios2_valid_target_attribute_rec (args))
+    return NULL_TREE;
+  nios2_custom_check_insns ();
+  return build_target_option_node ();
+}
+
+/* Hook to validate attribute((target("string"))).  */
+
+static bool
+nios2_valid_target_attribute_p (tree fndecl,
+				tree ARG_UNUSED (name),
+				tree args,
+				int ARG_UNUSED (flags))
+{
+  struct cl_target_option cur_target;
+  bool ret = true;
+  tree old_optimize = build_optimization_node ();
+  tree new_target, new_optimize;
+  tree func_optimize = DECL_FUNCTION_SPECIFIC_OPTIMIZATION (fndecl);
+
+  /* If the function changed the optimization levels as well as setting target
+     options, start with the optimizations specified.  */
+  if (func_optimize && func_optimize != old_optimize)
+    cl_optimization_restore (&global_options,
+			     TREE_OPTIMIZATION (func_optimize));
+
+  /* The target attributes may also change some optimization flags, so update
+     the optimization options if necessary.  */
+  cl_target_option_save (&cur_target, &global_options);
+  new_target = nios2_valid_target_attribute_tree (args);
+  new_optimize = build_optimization_node ();
+
+  if (!new_target)
+    ret = false;
+
+  else if (fndecl)
+    {
+      DECL_FUNCTION_SPECIFIC_TARGET (fndecl) = new_target;
+
+      if (old_optimize != new_optimize)
+	DECL_FUNCTION_SPECIFIC_OPTIMIZATION (fndecl) = new_optimize;
+    }
+
+  cl_target_option_restore (&global_options, &cur_target);
+
+  if (old_optimize != new_optimize)
+    cl_optimization_restore (&global_options,
+			     TREE_OPTIMIZATION (old_optimize));
+  return ret;
+}
+
+/* Remember the last target of nios2_set_current_function.  */
+static GTY(()) tree nios2_previous_fndecl;
+
+/* Establish appropriate back-end context for processing the function
+   FNDECL.  The argument might be NULL to indicate processing at top
+   level, outside of any function scope.  */
+static void
+nios2_set_current_function (tree fndecl)
+{
+  tree old_tree = (nios2_previous_fndecl
+		   ? DECL_FUNCTION_SPECIFIC_TARGET (nios2_previous_fndecl)
+		   : NULL_TREE);
+
+  tree new_tree = (fndecl
+		   ? DECL_FUNCTION_SPECIFIC_TARGET (fndecl)
+		   : NULL_TREE);
+
+  if (fndecl && fndecl != nios2_previous_fndecl)
+    {
+      nios2_previous_fndecl = fndecl;
+      if (old_tree == new_tree)
+	;
+
+      else if (new_tree)
+	{
+	  cl_target_option_restore (&global_options,
+				    TREE_TARGET_OPTION (new_tree));
+	  target_reinit ();
+	}
+
+      else if (old_tree)
+	{
+	  struct cl_target_option *def
+	    = TREE_TARGET_OPTION (target_option_current_node);
+
+	  cl_target_option_restore (&global_options, def);
+	  target_reinit ();
+	}
+    }
+}
+
+/* Hook to validate the current #pragma GCC target and set the FPU custom
+   code option state.  If ARGS is NULL, then POP_TARGET is used to reset
+   the options.  */
+
+static bool
+nios2_pragma_target_parse (tree args, tree pop_target)
+{
+  tree cur_tree;
+  if (! args)
+    {
+      cur_tree = ((pop_target)
+		  ? pop_target
+		  : target_option_default_node);
+      cl_target_option_restore (&global_options,
+				TREE_TARGET_OPTION (cur_tree));
+    }
+  else
+    {
+      cur_tree = nios2_valid_target_attribute_tree (args);
+      if (!cur_tree)
+	return false;
+    }
+
+  target_option_current_node = cur_tree;
+  return true;
+}
+
+/* Implement TARGET_MERGE_DECL_ATTRIBUTES.
+   We are just using this hook to add some additional error checking to
+   the default behavior.  GCC does not provide a target hook for merging
+   the target options, and only correctly handles merging empty vs non-empty
+   option data; see merge_decls() in c-decl.c.
+   So here we require either that at least one of the decls has empty
+   target options, or that the target options/data be identical.  */
+static tree
+nios2_merge_decl_attributes (tree olddecl, tree newdecl)
+{
+  tree oldopts = lookup_attribute ("target", DECL_ATTRIBUTES (olddecl));
+  tree newopts = lookup_attribute ("target", DECL_ATTRIBUTES (newdecl));
+  if (newopts && oldopts && newopts != oldopts)
+    {
+      tree oldtree = DECL_FUNCTION_SPECIFIC_TARGET (olddecl);
+      tree newtree = DECL_FUNCTION_SPECIFIC_TARGET (newdecl);
+      if (oldtree && newtree && oldtree != newtree)
+	{
+	  struct cl_target_option *olddata = TREE_TARGET_OPTION (oldtree);
+	  struct cl_target_option *newdata = TREE_TARGET_OPTION (newtree);
+	  if (olddata != newdata
+	      && memcmp (olddata, newdata, sizeof (struct cl_target_option)))
+	    error ("%qE redeclared with conflicting %qs attributes",
+		   DECL_NAME (newdecl), "target");
+	}
+    }
+  return merge_attributes (DECL_ATTRIBUTES (olddecl),
+			   DECL_ATTRIBUTES (newdecl));
+}
+
+#include "gt-nios2.h"
diff --git a/gcc/config/nios2/nios2.h b/gcc/config/nios2/nios2.h
new file mode 100644
index 0000000..730bde9
--- /dev/null
+++ b/gcc/config/nios2/nios2.h
@@ -0,0 +1,705 @@
+/* Definitions of target machine for Altera Nios II.
+   Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Jonah Graham (jgraham@altera.com), 
+   Will Reece (wreece@altera.com), and Jeff DaSilva (jdasilva@altera.com).
+   Contributed by Mentor Graphics, Inc.
+
+   This file is part of GCC.
+
+   GCC is free software; you can redistribute it and/or modify it
+   under the terms of the GNU General Public License as published
+   by the Free Software Foundation; either version 3, or (at your
+   option) any later version.
+
+   GCC is distributed in the hope that it will be useful, but WITHOUT
+   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
+   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
+   License for more details.
+
+   You should have received a copy of the GNU General Public License
+   along with GCC; see the file COPYING3.  If not see
+   <http://www.gnu.org/licenses/>.  */
+
+#ifndef GCC_NIOS2_H
+#define GCC_NIOS2_H
+
+/* FPU insn codes declared here.  */
+#include "config/nios2/nios2-opts.h"
+
+/* Define built-in preprocessor macros.  */
+#define TARGET_CPU_CPP_BUILTINS()                   \
+  do                                                \
+    {                                               \
+      builtin_define_std ("NIOS2");                 \
+      builtin_define_std ("nios2");                 \
+      if (TARGET_BIG_ENDIAN)                        \
+        builtin_define_std ("nios2_big_endian");    \
+      else                                          \
+        builtin_define_std ("nios2_little_endian"); \
+    }                                               \
+  while (0)
+
+/* We're little endian, unless otherwise specified by defining
+   BIG_ENDIAN_FLAG.  */
+#ifndef TARGET_ENDIAN_DEFAULT
+# define TARGET_ENDIAN_DEFAULT 0
+#endif
+
+/* Default target_flags if no switches specified.  */
+#ifndef TARGET_DEFAULT
+# define TARGET_DEFAULT (MASK_HAS_MUL | TARGET_ENDIAN_DEFAULT)
+#endif
+
+#define CC1_SPEC "%{G*}"
+
+#if TARGET_ENDIAN_DEFAULT == 0
+# define ASM_SPEC "%{!meb:-EL} %{meb:-EB}"
+# define LINK_SPEC_ENDIAN "%{!meb:-EL} %{meb:-EB}"
+# define MULTILIB_DEFAULTS { "EL" }
+#else
+# define ASM_SPEC "%{!mel:-EB} %{mel:-EL}"
+# define LINK_SPEC_ENDIAN "%{!mel:-EB} %{mel:-EL}"
+# define MULTILIB_DEFAULTS { "EB" }
+#endif
+
+#define LINK_SPEC LINK_SPEC_ENDIAN \
+  " %{shared:-shared} \
+    %{static:-Bstatic}"
+
+
+/* Storage Layout.  */
+
+#define DEFAULT_SIGNED_CHAR 1
+#define BITS_BIG_ENDIAN 0
+#define BYTES_BIG_ENDIAN (TARGET_BIG_ENDIAN != 0)
+#define WORDS_BIG_ENDIAN (TARGET_BIG_ENDIAN != 0)
+#define BITS_PER_UNIT 8
+#define BITS_PER_WORD 32
+#define UNITS_PER_WORD 4
+#define POINTER_SIZE 32
+#define BIGGEST_ALIGNMENT 32
+#define STRICT_ALIGNMENT 1
+#define FUNCTION_BOUNDARY 32
+#define PARM_BOUNDARY 32
+#define STACK_BOUNDARY 32
+#define PREFERRED_STACK_BOUNDARY 32
+#define MAX_FIXED_MODE_SIZE 64
+
+#define CONSTANT_ALIGNMENT(EXP, ALIGN)                          \
+  ((TREE_CODE (EXP) == STRING_CST)                              \
+   && (ALIGN) < BITS_PER_WORD ? BITS_PER_WORD : (ALIGN))
+
+
+/* Layout of Source Language Data Types.  */
+
+#define INT_TYPE_SIZE 32
+#define SHORT_TYPE_SIZE 16
+#define LONG_TYPE_SIZE 32
+#define LONG_LONG_TYPE_SIZE 64
+#define FLOAT_TYPE_SIZE 32
+#define DOUBLE_TYPE_SIZE 64
+#define LONG_DOUBLE_TYPE_SIZE DOUBLE_TYPE_SIZE
+
+#undef SIZE_TYPE
+#define SIZE_TYPE "unsigned int"
+
+#undef PTRDIFF_TYPE
+#define PTRDIFF_TYPE "int"
+
+
+/* Basic Characteristics of Registers:
+Register Number
+      Register Name
+          Alternate Name
+                Purpose
+0     r0  zero  always zero
+1     r1  at    Assembler Temporary
+2-3   r2-r3     Return Location
+4-7   r4-r7     Register Arguments
+8-15  r8-r15    Caller Saved Registers
+16-22 r16-r22   Callee Saved Registers
+22    r22       Global Offset Table pointer (Linux ABI only)
+23    r23       Thread pointer (Linux ABI only)
+24    r24 et    Exception Temporary
+25    r25 bt    Breakpoint Temporary
+26    r26 gp    Global Pointer
+27    r27 sp    Stack Pointer
+28    r28 fp    Frame Pointer
+29    r29 ea    Exception Return Address
+30    r30 ba    Breakpoint Return Address
+31    r31 ra    Return Address
+
+32    ctl0 status
+33    ctl1 estatus STATUS saved by exception ?
+34    ctl2 bstatus STATUS saved by break ?
+35    ctl3 ipri    Interrupt Priority Mask ?
+36    ctl4 ecause  Exception Cause ?
+
+37    pc       Not an actual register
+
+38    fake_fp  Fake Frame Pointer which will always be eliminated.
+39    fake_ap  Fake Argument Pointer which will always be eliminated.
+
+40             First Pseudo Register
+
+In addition, r12 is used as the static chain register and r13, r14, and r15
+are clobbered by PLT code sequences.  
+
+The definitions for all the hard register numbers
+are located in nios2.md.
+*/
+
+#define ET_REGNO (24)
+#define GP_REGNO (26)
+#define SP_REGNO (27)
+#define FP_REGNO (28)
+#define EA_REGNO (29)
+#define RA_REGNO (31)
+#define FIRST_RETVAL_REGNO (2)
+#define LAST_RETVAL_REGNO (3)
+#define FIRST_ARG_REGNO (4)
+#define LAST_ARG_REGNO (7)
+#define SC_REGNO (12)
+#define PC_REGNO (37)
+#define FAKE_FP_REGNO (38)
+#define FAKE_AP_REGNO (39)
+
+#define FIRST_PSEUDO_REGISTER 40
+#define NUM_ARG_REGS (LAST_ARG_REGNO - FIRST_ARG_REGNO + 1)
+
+
+
+#define FIXED_REGISTERS                      \
+  {					     \
+/*        +0  1  2  3  4  5  6  7  8  9 */   \
+/*   0 */  1, 1, 0, 0, 0, 0, 0, 0, 0, 0,     \
+/*  10 */  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     \
+/*  20 */  0, 0, TARGET_LINUX_ABI, TARGET_LINUX_ABI, 1, 1, 1, 1, 0, 1,     \
+/*  30 */  1, 0, 1, 1, 1, 1, 1, 1, 1, 1,     \
+  }
+
+/* call used is the same as caller saved
+   + fixed regs + args + ret vals */
+#define CALL_USED_REGISTERS                  \
+  {					     \
+/*        +0  1  2  3  4  5  6  7  8  9 */   \
+/*   0 */  1, 1, 1, 1, 1, 1, 1, 1, 1, 1,     \
+/*  10 */  1, 1, 1, 1, 1, 1, 0, 0, 0, 0,     \
+/*  20 */  0, 0, TARGET_LINUX_ABI, TARGET_LINUX_ABI, 1, 1, 1, 1, 0, 1,     \
+/*  30 */  1, 0, 1, 1, 1, 1, 1, 1, 1, 1,     \
+  }
+
+#define THREAD_POINTER_REGNUM 23
+
+#define HARD_REGNO_NREGS(REGNO, MODE)            \
+  ((GET_MODE_SIZE (MODE) + UNITS_PER_WORD - 1)	 \
+   / UNITS_PER_WORD)
+
+#define HARD_REGNO_MODE_OK(REGNO, MODE) 1
+#define MODES_TIEABLE_P(MODE1, MODE2) 1
+
+/* Register Classes.  */
+
+enum reg_class
+{
+  NO_REGS,
+  D00_REG,
+  D01_REG,
+  D02_REG,
+  D03_REG,
+  D04_REG,
+  D05_REG,
+  D06_REG,
+  D07_REG,
+  D08_REG,
+  D09_REG,
+  D10_REG,
+  D11_REG,
+  D12_REG,
+  D13_REG,
+  D14_REG,
+  D15_REG,
+  D16_REG,
+  D17_REG,
+  D18_REG,
+  D19_REG,
+  D20_REG,
+  D21_REG,
+  D22_REG,
+  D23_REG,
+  D24_REG,
+  D25_REG,
+  D26_REG,
+  D27_REG,
+  D28_REG,
+  D29_REG,
+  D30_REG,
+  D31_REG,
+  SIB_REGS,
+  GP_REGS,
+  ALL_REGS,
+  LIM_REG_CLASSES
+};
+
+#define N_REG_CLASSES (int) LIM_REG_CLASSES
+
+#define REG_CLASS_NAMES   \
+  {  "NO_REGS",		  \
+     "D00_REG",	  \
+     "D01_REG",	  \
+     "D02_REG",           \
+     "D03_REG",           \
+     "D04_REG",           \
+     "D05_REG",           \
+     "D06_REG",           \
+     "D07_REG",           \
+     "D08_REG",           \
+     "D09_REG",           \
+     "D10_REG",           \
+     "D11_REG",           \
+     "D12_REG",           \
+     "D13_REG",           \
+     "D14_REG",           \
+     "D15_REG",           \
+     "D16_REG",           \
+     "D17_REG",           \
+     "D18_REG",           \
+     "D19_REG",           \
+     "D20_REG",           \
+     "D21_REG",           \
+     "D22_REG",           \
+     "D23_REG",           \
+     "D24_REG",           \
+     "D25_REG",           \
+     "D26_REG",           \
+     "D27_REG",           \
+     "D28_REG",           \
+     "D29_REG",           \
+     "D30_REG",           \
+     "D31_REG",           \
+     "SIB_REGS",	  \
+     "GP_REGS",           \
+     "ALL_REGS" }
+
+#define GENERAL_REGS ALL_REGS
+
+#define REG_CLASS_CONTENTS   \
+/* NO_REGS  */       {{ 0, 0},     \
+/* D00_REG  */        { 1 << 0, 0},    \
+/* D01_REG  */        { 1 << 1, 0},    \
+/* D02_REG  */        { 1 << 2, 0},    \
+/* D03_REG  */        { 1 << 3, 0},    \
+/* D04_REG  */        { 1 << 4, 0},    \
+/* D05_REG  */        { 1 << 5, 0},    \
+/* D06_REG  */        { 1 << 6, 0},    \
+/* D07_REG  */        { 1 << 7, 0},    \
+/* D08_REG  */        { 1 << 8, 0},    \
+/* D09_REG  */        { 1 << 9, 0},    \
+/* D10_REG  */        { 1 << 10, 0},    \
+/* D11_REG  */        { 1 << 11, 0},    \
+/* D12_REG  */        { 1 << 12, 0},    \
+/* D13_REG  */        { 1 << 13, 0},    \
+/* D14_REG  */        { 1 << 14, 0},    \
+/* D15_REG  */        { 1 << 15, 0},    \
+/* D16_REG  */        { 1 << 16, 0},    \
+/* D17_REG  */        { 1 << 17, 0},    \
+/* D18_REG  */        { 1 << 18, 0},    \
+/* D19_REG  */        { 1 << 19, 0},    \
+/* D20_REG  */        { 1 << 20, 0},    \
+/* D21_REG  */        { 1 << 21, 0},    \
+/* D22_REG  */        { 1 << 22, 0},    \
+/* D23_REG  */        { 1 << 23, 0},    \
+/* D24_REG  */        { 1 << 24, 0},    \
+/* D25_REG  */        { 1 << 25, 0},    \
+/* D26_REG  */        { 1 << 26, 0},    \
+/* D27_REG  */        { 1 << 27, 0},    \
+/* D28_REG  */        { 1 << 28, 0},    \
+/* D29_REG  */        { 1 << 29, 0},    \
+/* D30_REG  */        { 1 << 30, 0},    \
+/* D31_REG  */        { 1 << 31, 0},    \
+/* SIB_REGS */	      { 0xfe0c, 0}, 	\
+/* GP_REGS  */        {~0, 0},    \
+/* ALL_REGS */        {~0,~0}}    \
+
+#define GP_REGNO_P(REGNO) ((REGNO) < 32)
+#define REGNO_REG_CLASS(REGNO) (GP_REGNO_P (REGNO) ? GP_REGS : ALL_REGS)
+
+#define BASE_REG_CLASS ALL_REGS
+#define INDEX_REG_CLASS ALL_REGS
+
+#define REGNO_OK_FOR_BASE_P2(REGNO, STRICT) \
+  ((STRICT)				    \
+   ? (REGNO) < FIRST_PSEUDO_REGISTER	    \
+   : ((REGNO) < FIRST_PSEUDO_REGISTER					\
+      || (reg_renumber && reg_renumber[REGNO] < FIRST_PSEUDO_REGISTER)))
+
+#define REGNO_OK_FOR_INDEX_P2(REGNO, STRICT) \
+  (REGNO_OK_FOR_BASE_P2 (REGNO, STRICT))
+
+#define REGNO_OK_FOR_BASE_P(REGNO) \
+  (REGNO_OK_FOR_BASE_P2 (REGNO, 1))
+
+#define REGNO_OK_FOR_INDEX_P(REGNO) \
+  (REGNO_OK_FOR_INDEX_P2 (REGNO, 1))
+
+#define REG_OK_FOR_BASE_P2(X, STRICT)                                   \
+  (STRICT								\
+   ? REGNO_OK_FOR_BASE_P2 (REGNO (X), 1)				\
+   : (REGNO_OK_FOR_BASE_P2 (REGNO (X), 1)				\
+      || REGNO(X) >= FIRST_PSEUDO_REGISTER))
+
+#define REG_OK_FOR_INDEX_P2(X, STRICT)                                  \
+  (STRICT								\
+   ? REGNO_OK_FOR_INDEX_P2 (REGNO (X), 1)				\
+   : (REGNO_OK_FOR_INDEX_P2 (REGNO (X), 1)				\
+      || REGNO(X) >= FIRST_PSEUDO_REGISTER))
+
+#define CLASS_MAX_NREGS(CLASS, MODE)             \
+  ((GET_MODE_SIZE (MODE) + UNITS_PER_WORD - 1)	 \
+   / UNITS_PER_WORD)
+
+#define SMALL_INT(X) ((X) >= -0x8000 && (X) < 0x8000)
+#define SMALL_INT_UNSIGNED(X) ((X) >= 0 && (X) < 0x10000)
+#define UPPER16_INT(X) (((X) & 0xffff) == 0)
+#define SHIFT_INT(X) ((X) >= 0 && (X) <= 31)
+#define RDWRCTL_INT(X) ((X) >= 0 && (X) <= 31)
+#define CUSTOM_INSN_OPCODE(X) ((X) >= 0 && (X) <= 255)
+
+/* Say that the epilogue uses the return address register.  Note that
+   in the case of sibcalls, the values "used by the epilogue" are
+   considered live at the start of the called function.  */
+#define EPILOGUE_USES(REGNO) ((REGNO) == RA_REGNO)
+
+/* EXIT_IGNORE_STACK should be nonzero if, when returning from a function,
+   the stack pointer does not matter.  The value is tested only in
+   functions that have frame pointers.
+   No definition is equivalent to always zero.  */
+
+#define EXIT_IGNORE_STACK 1
+
+/* Trampolines use a 5-instruction sequence.  */
+#define TRAMPOLINE_SIZE 20
+
+
+/* Stack Layout and Calling Conventions.  */
+
+/* The downward variants are used by the compiler,
+   the upward ones serve as documentation.  */
+#define STACK_GROWS_DOWNWARD
+#define FRAME_GROWS_UPWARD
+#define ARGS_GROW_UPWARD
+
+#define STARTING_FRAME_OFFSET 0
+#define FIRST_PARM_OFFSET(FUNDECL) 0
+
+/* Before the prologue, RA lives in r31.  */
+#define INCOMING_RETURN_ADDR_RTX  gen_rtx_REG (VOIDmode, RA_REGNO)
+#define RETURN_ADDR_RTX(C,F) nios2_get_return_address (C)
+
+/* Registers That Address the Stack Frame.  */
+#define STACK_POINTER_REGNUM SP_REGNO
+#define STATIC_CHAIN_REGNUM SC_REGNO
+#define PC_REGNUM PC_REGNO
+#define DWARF_FRAME_RETURN_COLUMN RA_REGNO
+
+/* Base register for access to local variables of the function.  We
+   pretend that the frame pointer is a non-existent hard register, and
+   then eliminate it to HARD_FRAME_POINTER_REGNUM. */
+#define FRAME_POINTER_REGNUM FAKE_FP_REGNO
+
+#define HARD_FRAME_POINTER_REGNUM FP_REGNO
+
+/* The argument pointer needs to always be eliminated
+   so it is set to a fake hard register.  */
+#define ARG_POINTER_REGNUM FAKE_AP_REGNO
+
+/* The CFA includes the pretend args.  */
+#define ARG_POINTER_CFA_OFFSET(FNDECL) \
+  (gcc_assert ((FNDECL) == current_function_decl), \
+   FIRST_PARM_OFFSET (FNDECL) + crtl->args.pretend_args_size)
+
+/* Frame/arg pointer elimination settings.  */
+#define ELIMINABLE_REGS                                                 \
+{{ ARG_POINTER_REGNUM,   STACK_POINTER_REGNUM},                         \
+ { ARG_POINTER_REGNUM,   HARD_FRAME_POINTER_REGNUM},                    \
+ { FRAME_POINTER_REGNUM, STACK_POINTER_REGNUM},                         \
+ { FRAME_POINTER_REGNUM, HARD_FRAME_POINTER_REGNUM}}
+
+#define INITIAL_ELIMINATION_OFFSET(FROM, TO, OFFSET) \
+  (OFFSET) = nios2_initial_elimination_offset ((FROM), (TO))
+
+/* Treat LOC as a byte offset from the stack pointer and round it up
+   to the next fully-aligned offset.  */
+#define STACK_ALIGN(LOC)                                                \
+  (((LOC) + ((PREFERRED_STACK_BOUNDARY / 8) - 1))			\
+   & ~((PREFERRED_STACK_BOUNDARY / 8) - 1))
+
+/* Calling convention definitions.  */
+typedef struct nios2_args
+{
+  int regs_used;
+} CUMULATIVE_ARGS;
+
+/* This is to initialize the above unused CUM data type.  */
+#define INIT_CUMULATIVE_ARGS(CUM, FNTYPE, LIBNAME, FNDECL, N_NAMED_ARGS) \
+  (nios2_init_cumulative_args (&CUM, FNTYPE, LIBNAME, FNDECL, N_NAMED_ARGS))
+
+#define FUNCTION_ARG_PADDING(MODE, TYPE) \
+  (nios2_function_arg_padding ((MODE), (TYPE)))
+
+#define PAD_VARARGS_DOWN \
+  (FUNCTION_ARG_PADDING (TYPE_MODE (type), type) == downward)
+
+#define BLOCK_REG_PADDING(MODE, TYPE, FIRST) \
+  (nios2_block_reg_padding ((MODE), (TYPE), (FIRST)))
+
+#define FUNCTION_ARG_REGNO_P(REGNO) \
+  ((REGNO) >= FIRST_ARG_REGNO && (REGNO) <= LAST_ARG_REGNO)
+
+/* Passing Function Arguments on the Stack.  */
+#define PUSH_ARGS 0
+#define ACCUMULATE_OUTGOING_ARGS 1
+
+/* We define TARGET_RETURN_IN_MEMORY, so set to zero.  */
+#define DEFAULT_PCC_STRUCT_RETURN 0
+
+/* Profiling.  */
+#define PROFILE_BEFORE_PROLOGUE
+#define NO_PROFILE_COUNTERS 1
+#define FUNCTION_PROFILER(FILE, LABELNO) \
+  nios2_function_profiler ((FILE), (LABELNO))
+
+/* Addressing Modes.  */
+
+#define CONSTANT_ADDRESS_P(X) \
+  (CONSTANT_P (X) && memory_address_p (SImode, X))
+
+#define MAX_REGS_PER_ADDRESS 1
+
+#ifndef REG_OK_STRICT
+#define REG_OK_FOR_BASE_P(X)   REGNO_OK_FOR_BASE_P2 (REGNO (X), 0)
+#define REG_OK_FOR_INDEX_P(X)  REGNO_OK_FOR_INDEX_P2 (REGNO (X), 0)
+#else
+#define REG_OK_FOR_BASE_P(X)   REGNO_OK_FOR_BASE_P2 (REGNO (X), 1)
+#define REG_OK_FOR_INDEX_P(X)  REGNO_OK_FOR_INDEX_P2 (REGNO (X), 1)
+#endif
+
+/* Set if this has a weak declaration.  */
+#define SYMBOL_FLAG_WEAK_DECL   (1 << SYMBOL_FLAG_MACH_DEP_SHIFT)
+#define SYMBOL_REF_WEAK_DECL_P(RTX) \
+  ((SYMBOL_REF_FLAGS (RTX) & SYMBOL_FLAG_WEAK_DECL) != 0)
+
+
+/* True if a symbol is both small and not weak.  In this case, GP-relative
+   access can be used.  GP-relative access cannot be used in
+   position-independent code.  GP-relative access cannot be used for externally
+   defined symbols, because the compilation unit that defines the symbol may
+   place it in a section that cannot be reached from GP.  */
+#define SYMBOL_REF_IN_NIOS2_SMALL_DATA_P(RTX) \
+  (!flag_pic && SYMBOL_REF_SMALL_P (RTX)      \
+   && !SYMBOL_REF_WEAK_DECL_P (RTX)	      \
+   && !SYMBOL_REF_EXTERNAL_P (RTX)	      \
+   && SYMBOL_REF_TLS_MODEL (RTX) == 0)
+
+/* Describing Relative Costs of Operations.  */
+#define MOVE_MAX 4
+#define SLOW_BYTE_ACCESS 1
+
+/* It is as good to call a constant function address as to call an address
+   kept in a register.
+   ??? Not true anymore really. Now that call cannot address full range
+   of memory callr may need to be used */
+
+#define NO_FUNCTION_CSE
+
+/* Position Independent Code.  */
+
+#define PIC_OFFSET_TABLE_REGNUM 22
+#define LEGITIMATE_PIC_OPERAND_P(X) nios2_legitimate_pic_operand_p (X)
+
+/* Define output assembler language.  */
+
+#define ASM_APP_ON "#APP\n"
+#define ASM_APP_OFF "#NO_APP\n"
+
+#define ASM_COMMENT_START "# "
+
+#define GLOBAL_ASM_OP "\t.global\t"
+
+#define REGISTER_NAMES \
+  {		       \
+    "zero", \
+    "at", \
+    "r2", \
+    "r3", \
+    "r4", \
+    "r5", \
+    "r6", \
+    "r7", \
+    "r8", \
+    "r9", \
+    "r10", \
+    "r11", \
+    "r12", \
+    "r13", \
+    "r14", \
+    "r15", \
+    "r16", \
+    "r17", \
+    "r18", \
+    "r19", \
+    "r20", \
+    "r21", \
+    "r22", \
+    "r23", \
+    "et", \
+    "bt", \
+    "gp", \
+    "sp", \
+    "fp", \
+    "ta", \
+    "ba", \
+    "ra", \
+    "status", \
+    "estatus", \
+    "bstatus", \
+    "ipri", \
+    "ecause", \
+    "pc", \
+    "fake_fp", \
+    "fake_ap", \
+}
+
+#define ADDITIONAL_REGISTER_NAMES       \
+{					\
+  {"r0", 0},				\
+  {"r1", 1},				\
+  {"r24", 24},                          \
+  {"r25", 25},                          \
+  {"r26", 26},                          \
+  {"r27", 27},                          \
+  {"r28", 28},                          \
+  {"r29", 29},                          \
+  {"r30", 30},                          \
+  {"r31", 31}                           \
+}
+
+
+#define ASM_OUTPUT_ADDR_VEC_ELT(FILE, VALUE)  \
+  do									\
+    {									\
+      fputs (integer_asm_op (POINTER_SIZE / BITS_PER_UNIT, TRUE), FILE); \
+      fprintf (FILE, ".L%u\n", (unsigned) (VALUE));			\
+    }									\
+  while (0)
+
+#define ASM_OUTPUT_ADDR_DIFF_ELT(STREAM, BODY, VALUE, REL)\
+  do									\
+    {									\
+      fputs (integer_asm_op (POINTER_SIZE / BITS_PER_UNIT, TRUE), STREAM); \
+      fprintf (STREAM, ".L%u-.L%u\n", (unsigned) (VALUE), (unsigned) (REL)); \
+    }									\
+  while (0)
+
+
+/* Section directives.  */
+
+/* Output before read-only data.  */
+#define TEXT_SECTION_ASM_OP "\t.section\t.text"
+
+/* Output before writable data.  */
+#define DATA_SECTION_ASM_OP "\t.section\t.data"
+
+/* Output before uninitialized data.  */
+#define BSS_SECTION_ASM_OP "\t.section\t.bss"
+
+/* Output before 'small' uninitialized data.  */
+#define SBSS_SECTION_ASM_OP "\t.section\t.sbss"
+
+#ifndef IN_LIBGCC2
+/* Default the definition of "small data" to 8 bytes. */
+extern unsigned HOST_WIDE_INT nios2_section_threshold;
+#endif
+
+#define NIOS2_DEFAULT_GVALUE 8
+
+/* This says how to output assembler code to declare an
+   uninitialized external linkage data object.  Under SVR4,
+   the linker seems to want the alignment of data objects
+   to depend on their types.  We do exactly that here.  */
+#undef COMMON_ASM_OP
+#define COMMON_ASM_OP   "\t.comm\t"
+
+#define ASM_OUTPUT_ALIGN(FILE, LOG)		     \
+  do {						     \
+    fprintf ((FILE), "%s%d\n", ALIGN_ASM_OP, (LOG)); \
+  } while (0)
+
+#undef  ASM_OUTPUT_ALIGNED_COMMON
+#define ASM_OUTPUT_ALIGNED_COMMON(FILE, NAME, SIZE, ALIGN)              \
+do                                                                      \
+  {									\
+    fprintf ((FILE), "%s", COMMON_ASM_OP);				\
+    assemble_name ((FILE), (NAME));					\
+    fprintf ((FILE), ","HOST_WIDE_INT_PRINT_UNSIGNED",%u\n", (SIZE),	\
+	     (ALIGN) / BITS_PER_UNIT);					\
+  }									\
+while (0)
+
+
+/* This says how to output assembler code to declare an
+   uninitialized internal linkage data object.  Under SVR4,
+   the linker seems to want the alignment of data objects
+   to depend on their types.  We do exactly that here.  */
+
+#undef  ASM_OUTPUT_ALIGNED_LOCAL
+#define ASM_OUTPUT_ALIGNED_LOCAL(FILE, NAME, SIZE, ALIGN)               \
+do {                                                                    \
+  if ((SIZE) <= nios2_section_threshold)                                \
+    switch_to_section (sbss_section);					\
+  else                                                                  \
+    switch_to_section (bss_section);					\
+  ASM_OUTPUT_TYPE_DIRECTIVE (FILE, NAME, "object");                     \
+  if (!flag_inhibit_size_directive)                                     \
+    ASM_OUTPUT_SIZE_DIRECTIVE (FILE, NAME, SIZE);                       \
+  ASM_OUTPUT_ALIGN ((FILE), exact_log2((ALIGN) / BITS_PER_UNIT));       \
+  ASM_OUTPUT_LABEL(FILE, NAME);                                         \
+  ASM_OUTPUT_SKIP((FILE), (SIZE) ? (SIZE) : 1);                         \
+} while (0)
+
+/* Put the jump tables in .text because when using position-independent code,
+   Nios II elf has no relocation that can represent arbitrary differences
+   between symbols in different sections.  */
+#define JUMP_TABLES_IN_TEXT_SECTION 1
+
+/* Exception Handling */
+
+/* Describe __builtin_eh_return.  */
+#define EH_RETURN_STACKADJ_RTX gen_rtx_REG (Pmode, LAST_RETVAL_REGNO)
+#define EH_RETURN_DATA_REGNO(N) ((N) <= (LAST_ARG_REGNO - FIRST_ARG_REGNO) \
+				 ? (N) + FIRST_ARG_REGNO : INVALID_REGNUM)
+
+/* Nios II has no appropriate relocations for a 32-bit PC-relative or
+   section-relative pointer encoding.  This therefore always chooses an
+   absolute representation for pointers.  An unfortunate consequence of
+   this is that ld complains about the absolute fde encoding when linking
+   with -shared or -fpie, but the warning is harmless and there seems to
+   be no good way to suppress it.  */
+#define ASM_PREFERRED_EH_DATA_FORMAT(CODE, GLOBAL)		\
+  (flag_pic ? DW_EH_PE_aligned : DW_EH_PE_sdata4)
+
+/* Misc. Parameters.  */
+
+#define STORE_FLAG_VALUE 1
+#define Pmode SImode
+#define FUNCTION_MODE QImode
+
+#define CASE_VECTOR_MODE Pmode
+
+#define TRULY_NOOP_TRUNCATION(OUTPREC, INPREC) 1
+
+#define LOAD_EXTEND_OP(MODE) (ZERO_EXTEND)
+
+#define WORD_REGISTER_OPERATIONS
+
+#endif /* GCC_NIOS2_H */
diff --git a/gcc/config/nios2/nios2.md b/gcc/config/nios2/nios2.md
new file mode 100644
index 0000000..b86236d
--- /dev/null
+++ b/gcc/config/nios2/nios2.md
@@ -0,0 +1,1072 @@
+;; Machine Description for Altera Nios II.
+;; Copyright (C) 2012 Free Software Foundation, Inc.
+;; Contributed by Jonah Graham (jgraham@altera.com) and 
+;; Will Reece (wreece@altera.com).
+;; Contributed by Mentor Graphics, Inc.
+;;
+;; This file is part of GCC.
+;;
+;; GCC is free software; you can redistribute it and/or modify
+;; it under the terms of the GNU General Public License as published by
+;; the Free Software Foundation; either version 3, or (at your option)
+;; any later version.
+;;
+;; GCC is distributed in the hope that it will be useful,
+;; but WITHOUT ANY WARRANTY; without even the implied warranty of
+;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+;; GNU General Public License for more details.
+;;
+;; You should have received a copy of the GNU General Public License
+;; along with GCC; see the file COPYING3.  If not see
+;; <http://www.gnu.org/licenses/>.
+
+
+;; Enumeration of UNSPECs
+
+(define_c_enum "unspecv" [
+  UNSPECV_BLOCKAGE
+  UNSPECV_WRCTL
+  UNSPECV_RDCTL
+  UNSPECV_TRAP
+  UNSPECV_STACK_OVERFLOW_DETECT_AND_TRAP
+  UNSPECV_FWRX
+  UNSPECV_FWRY
+  UNSPECV_FRDXLO
+  UNSPECV_FRDXHI
+  UNSPECV_FRDY
+  UNSPECV_CUSTOM_NXX
+  UNSPECV_CUSTOM_XNXX
+  UNSPECV_LDXIO
+  UNSPECV_STXIO
+])
+
+(define_c_enum "unspec" [
+  UNSPEC_FCOS
+  UNSPEC_FSIN
+  UNSPEC_FTAN
+  UNSPEC_FATAN
+  UNSPEC_FEXP
+  UNSPEC_FLOG
+  UNSPEC_LOAD_GOT_REGISTER
+  UNSPEC_PIC_SYM
+  UNSPEC_PIC_CALL_SYM
+  UNSPEC_TLS
+  UNSPEC_TLS_LDM
+  UNSPEC_LOAD_TLS_IE
+  UNSPEC_ADD_TLS_LE
+  UNSPEC_ADD_TLS_GD
+  UNSPEC_ADD_TLS_LDM
+  UNSPEC_ADD_TLS_LDO
+  UNSPEC_EH_RETURN
+  UNSPEC_SYNC
+])
+
+
+;;  Instruction scheduler
+
+; No schedule info is currently available, using an assumption that no
+; instruction can use the results of the previous instruction without
+; incuring a stall.
+
+; length of an instruction (in bytes)
+(define_attr "length" "" (const_int 4))
+(define_attr "type" 
+  "unknown,complex,control,alu,cond_alu,st,ld,shift,mul,div,custom" 
+  (const_string "complex"))
+
+(define_asm_attributes
+ [(set_attr "length" "4")
+  (set_attr "type" "complex")])
+
+(define_automaton "nios2")
+(automata_option "v")
+;(automata_option "no-minimization")
+(automata_option "ndfa")
+
+; The nios2 pipeline is fairly straightforward for the fast model.
+; Every alu operation is pipelined so that an instruction can
+; be issued every cycle. However, there are still potential
+; stalls which this description tries to deal with.
+
+(define_cpu_unit "cpu" "nios2")
+
+(define_insn_reservation "complex" 1
+  (eq_attr "type" "complex")
+  "cpu")
+
+(define_insn_reservation "control" 1
+  (eq_attr "type" "control")
+  "cpu")
+
+(define_insn_reservation "alu" 1
+  (eq_attr "type" "alu")
+  "cpu")
+
+(define_insn_reservation "cond_alu" 1
+  (eq_attr "type" "cond_alu")
+  "cpu")
+
+(define_insn_reservation "st" 1
+  (eq_attr "type" "st")
+  "cpu")
+  
+(define_insn_reservation "custom" 1
+  (eq_attr "type" "custom")
+  "cpu")
+
+; shifts, muls and lds have three cycle latency
+(define_insn_reservation "ld" 3
+  (eq_attr "type" "ld")
+  "cpu")
+
+(define_insn_reservation "shift" 3
+  (eq_attr "type" "shift")
+  "cpu")
+
+(define_insn_reservation "mul" 3
+  (eq_attr "type" "mul")
+  "cpu")
+
+(define_insn_reservation "div" 1
+  (eq_attr "type" "div")
+  "cpu")
+
+(include "predicates.md")
+(include "constraints.md")
+
+
+;; Move instructions
+
+(define_mode_iterator M [QI HI SI])
+
+(define_expand "mov<mode>"
+  [(set (match_operand:M 0 "nonimmediate_operand" "")
+        (match_operand:M 1 "general_operand" ""))]
+  ""
+{
+  if (nios2_emit_move_sequence (operands, <MODE>mode))
+    DONE;
+})
+
+(define_insn "movqi_internal"
+  [(set (match_operand:QI 0 "nonimmediate_operand" "=m, r,r, r")
+        (match_operand:QI 1 "general_operand"       "rM,m,rM,I"))]
+  "(register_operand (operands[0], QImode)
+    || reg_or_0_operand (operands[1], QImode))"
+  "@
+    stb%o0\\t%z1, %0
+    ldbu%o1\\t%0, %1
+    mov\\t%0, %z1
+    movi\\t%0, %1"
+  [(set_attr "type" "st,ld,alu,alu")])
+
+(define_insn "movhi_internal"
+  [(set (match_operand:HI 0 "nonimmediate_operand" "=m, r,r, r,r")
+        (match_operand:HI 1 "general_operand"       "rM,m,rM,I,J"))]
+  "(register_operand (operands[0], HImode)
+    || reg_or_0_operand (operands[1], HImode))"
+  "@
+    sth%o0\\t%z1, %0
+    ldhu%o1\\t%0, %1
+    mov\\t%0, %z1
+    movi\\t%0, %1
+    movui\\t%0, %1"
+  [(set_attr "type" "st,ld,alu,alu,alu")])
+
+(define_insn "movsi_internal"
+  [(set (match_operand:SI 0 "nonimmediate_operand" "=m, r,r, r,r,r,r,r")
+        (match_operand:SI 1 "general_operand"       "rM,m,rM,I,J,K,S,i"))]
+  "(register_operand (operands[0], SImode)
+    || reg_or_0_operand (operands[1], SImode))"
+  "@
+    stw%o0\\t%z1, %0
+    ldw%o1\\t%0, %1
+    mov\\t%0, %z1
+    movi\\t%0, %1
+    movui\\t%0, %1
+    movhi\\t%0, %H1
+    addi\\t%0, gp, %%gprel(%1)
+    movhi\\t%0, %H1\;addi\\t%0, %0, %L1"
+  [(set_attr "type" "st,ld,alu,alu,alu,alu,alu,alu")
+   (set_attr "length" "4,4,4,4,4,4,4,8")])
+
+
+(define_mode_iterator BH [QI HI])
+(define_mode_iterator BHW [QI HI SI])
+(define_mode_attr bh [(QI "b") (HI "h")])
+(define_mode_attr bhw [(QI "b") (HI "h") (SI "w")])
+(define_mode_attr bhw_uns [(QI "bu") (HI "hu") (SI "w")])
+
+(define_insn "ld<bhw_uns>io"
+  [(set (match_operand:BHW 0 "register_operand" "=r")
+        (unspec_volatile:BHW
+          [(match_operand:BHW 1 "memory_operand" "m")] UNSPECV_LDXIO))]
+  ""
+  "ld<bhw_uns>io\\t%0, %1"
+  [(set_attr "type" "ld")])
+
+(define_expand "ld<bh>io"
+  [(set (match_operand:BH 0 "register_operand" "=r")
+        (match_operand:BH 1 "memory_operand" "m"))]
+  ""
+{
+  rtx tmp = gen_reg_rtx (SImode);
+  emit_insn (gen_ld<bh>io_signed (tmp, operands[1]));
+  emit_insn (gen_mov<mode> (operands[0], gen_lowpart (<MODE>mode, tmp)));
+  DONE;
+})
+
+(define_insn "ld<bh>io_signed"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+        (sign_extend:SI
+          (unspec_volatile:BH
+            [(match_operand:BH 1 "memory_operand" "m")] UNSPECV_LDXIO)))]
+  ""
+  "ld<bh>io\\t%0, %1"
+  [(set_attr "type" "ld")])
+
+(define_insn "st<bhw>io"
+  [(set (match_operand:BHW 0 "memory_operand" "=m")
+        (unspec_volatile:BHW
+          [(match_operand:BHW 1 "reg_or_0_operand" "rM")] UNSPECV_STXIO))]
+  ""
+  "st<bhw>io\\t%z1, %0"
+  [(set_attr "type" "st")])
+
+
+;; QI to [HI, SI] extension patterns are collected together
+(define_mode_iterator QX [HI SI])
+
+;; Zero extension patterns
+(define_insn "zero_extendhisi2"
+  [(set (match_operand:SI 0 "register_operand" "=r,r")
+        (zero_extend:SI (match_operand:HI 1 "nonimmediate_operand" "r,m")))]
+  ""
+  "@
+    andi\\t%0, %1, 0xffff
+    ldhu%o1\\t%0, %1"
+  [(set_attr "type"     "alu,ld")])
+
+(define_insn "zero_extendqi<mode>2"
+  [(set (match_operand:QX 0 "register_operand" "=r,r")
+        (zero_extend:QX (match_operand:QI 1 "nonimmediate_operand" "r,m")))]
+  ""
+  "@
+    andi\\t%0, %1, 0xff
+    ldbu%o1\\t%0, %1"
+  [(set_attr "type"     "alu,ld")])
+
+;; Sign extension patterns
+
+(define_insn "extendhisi2"
+  [(set (match_operand:SI 0 "register_operand"                     "=r,r")
+        (sign_extend:SI (match_operand:HI 1 "nonimmediate_operand"  "r,m")))]
+  ""
+  "@
+   #
+   ldh%o1\\t%0, %1"
+  [(set_attr "type" "alu,ld")])
+
+(define_insn "extendqi<mode>2"
+  [(set (match_operand:QX 0 "register_operand"                     "=r,r")
+        (sign_extend:QX (match_operand:QI 1 "nonimmediate_operand"  "r,m")))]
+  ""
+  "@
+   #
+   ldb%o1\\t%0, %1"
+  [(set_attr "type" "alu,ld")])
+
+;; Split patterns for register alternative cases.
+(define_split
+  [(set (match_operand:SI 0 "register_operand" "")
+        (sign_extend:SI (match_operand:HI 1 "register_operand" "")))]
+  "reload_completed"
+  [(set (match_dup 0)
+        (and:SI (match_dup 1) (const_int 65535)))
+   (set (match_dup 0)
+        (xor:SI (match_dup 0) (const_int 32768)))
+   (set (match_dup 0)
+        (plus:SI (match_dup 0) (const_int -32768)))]
+  "operands[1] = gen_lowpart (SImode, operands[1]);")
+
+(define_split
+  [(set (match_operand:QX 0 "register_operand" "")
+        (sign_extend:QX (match_operand:QI 1 "register_operand" "")))]
+  "reload_completed"
+  [(set (match_dup 0)
+        (and:SI (match_dup 1) (const_int 255)))
+   (set (match_dup 0)
+        (xor:SI (match_dup 0) (const_int 128)))
+   (set (match_dup 0)
+        (plus:SI (match_dup 0) (const_int -128)))]
+  "operands[0] = gen_lowpart (SImode, operands[0]);
+   operands[1] = gen_lowpart (SImode, operands[1]);")
+
+
+;; Arithmetic Operations
+
+(define_insn "addsi3"
+  [(set (match_operand:SI 0 "register_operand"          "=r")
+        (plus:SI (match_operand:SI 1 "register_operand" "%r")
+                 (match_operand:SI 2 "arith_operand"    "rI")))]
+  ""
+  "add%i2\\t%0, %1, %z2"
+  [(set_attr "type" "alu")])
+
+(define_insn "subsi3"
+  [(set (match_operand:SI 0 "register_operand"           "=r")
+        (minus:SI (match_operand:SI 1 "reg_or_0_operand" "rM")
+                  (match_operand:SI 2 "register_operand" "r")))]
+  ""
+  "sub\\t%0, %z1, %2"
+  [(set_attr "type" "alu")])
+
+(define_insn "mulsi3"
+  [(set (match_operand:SI 0 "register_operand"          "=r")
+        (mult:SI (match_operand:SI 1 "register_operand" "%r")
+                 (match_operand:SI 2 "arith_operand"    "rI")))]
+  "TARGET_HAS_MUL"
+  "mul%i2\\t%0, %1, %z2"
+  [(set_attr "type" "mul")])
+
+(define_expand "divsi3"
+  [(set (match_operand:SI 0 "register_operand"          "=r")
+        (div:SI (match_operand:SI 1 "register_operand"   "r")
+                (match_operand:SI 2 "register_operand"   "r")))]
+  ""
+{
+  if (!TARGET_HAS_DIV)
+    {
+      if (!TARGET_FAST_SW_DIV)
+        FAIL;
+      else
+        {
+          if (nios2_emit_expensive_div (operands, SImode))
+            DONE;
+        }
+    }
+})
+
+(define_insn "divsi3_insn"
+  [(set (match_operand:SI 0 "register_operand"            "=r")
+        (div:SI (match_operand:SI 1 "register_operand"     "r")
+                (match_operand:SI 2 "register_operand"     "r")))]
+  "TARGET_HAS_DIV"
+  "div\\t%0, %1, %2"
+  [(set_attr "type" "div")])
+
+(define_insn "udivsi3"
+  [(set (match_operand:SI 0 "register_operand"            "=r")
+        (udiv:SI (match_operand:SI 1 "register_operand"    "r")
+                 (match_operand:SI 2 "register_operand"    "r")))]
+  "TARGET_HAS_DIV"
+  "divu\\t%0, %1, %2"
+  [(set_attr "type" "div")])
+
+(define_code_iterator EXTEND [sign_extend zero_extend])
+(define_code_attr us [(sign_extend "s") (zero_extend "u")])
+(define_code_attr mul [(sign_extend "mul") (zero_extend "umul")])
+
+(define_insn "<us>mulsi3_highpart"
+  [(set (match_operand:SI 0 "register_operand"                       "=r")
+        (truncate:SI
+         (lshiftrt:DI
+          (mult:DI (EXTEND:DI (match_operand:SI 1 "register_operand"  "r"))
+                   (EXTEND:DI (match_operand:SI 2 "register_operand"  "r")))
+          (const_int 32))))]
+  "TARGET_HAS_MULX"
+  "mulx<us><us>\\t%0, %1, %2"
+  [(set_attr "type" "mul")])
+
+(define_expand "<mul>sidi3"
+  [(set (match_operand:DI 0 "register_operand" "")
+	(mult:DI (EXTEND:DI (match_operand:SI 1 "register_operand" ""))
+		 (EXTEND:DI (match_operand:SI 2 "register_operand" ""))))]
+  "TARGET_HAS_MULX"
+{
+  rtx hi = gen_reg_rtx (SImode);
+  rtx lo = gen_reg_rtx (SImode);
+
+  emit_insn (gen_<us>mulsi3_highpart (hi, operands[1], operands[2]));
+  emit_insn (gen_mulsi3 (lo, operands[1], operands[2]));
+  emit_move_insn (gen_lowpart (SImode, operands[0]), lo);
+  emit_move_insn (gen_highpart (SImode, operands[0]), hi);
+  DONE;
+})
+
+
+;;  Negate and ones complement
+
+(define_insn "negsi2"
+  [(set (match_operand:SI 0 "register_operand"        "=r")
+        (neg:SI (match_operand:SI 1 "register_operand" "r")))]
+  ""
+  "sub\\t%0, zero, %1"
+  [(set_attr "type" "alu")])
+
+(define_insn "one_cmplsi2"
+  [(set (match_operand:SI 0 "register_operand"        "=r")
+        (not:SI (match_operand:SI 1 "register_operand" "r")))]
+  ""
+  "nor\\t%0, zero, %1"
+  [(set_attr "type" "alu")])
+
+
+;;  Integer logical Operations
+
+(define_code_iterator LOGICAL [and ior xor])
+(define_code_attr logical_asm [(and "and") (ior "or") (xor "xor")])
+
+(define_insn "<code>si3"
+  [(set (match_operand:SI 0 "register_operand"             "=r,r,r")
+        (LOGICAL:SI (match_operand:SI 1 "register_operand" "%r,r,r")
+                    (match_operand:SI 2 "logical_operand"  "rM,J,K")))]
+  ""
+  "@
+    <logical_asm>\\t%0, %1, %z2
+    <logical_asm>%i2\\t%0, %1, %2
+    <logical_asm>h%i2\\t%0, %1, %U2"
+  [(set_attr "type" "alu")])
+
+(define_insn "*norsi3"
+  [(set (match_operand:SI 0 "register_operand"                  "=r")
+        (and:SI (not:SI (match_operand:SI 1 "register_operand"  "%r"))
+                (not:SI (match_operand:SI 2 "reg_or_0_operand"  "rM"))))]
+  ""
+  "nor\\t%0, %1, %z2"
+  [(set_attr "type" "alu")])
+
+
+;;  Shift instructions
+
+(define_code_iterator SHIFT  [ashift ashiftrt lshiftrt rotate])
+(define_code_attr shift_op   [(ashift "ashl") (ashiftrt "ashr")
+                              (lshiftrt "lshr") (rotate "rotl")])
+(define_code_attr shift_asm  [(ashift "sll") (ashiftrt "sra")
+                              (lshiftrt "srl") (rotate "rol")])
+
+(define_insn "<shift_op>si3"
+  [(set (match_operand:SI 0 "register_operand"          "=r")
+        (SHIFT:SI (match_operand:SI 1 "register_operand" "r")
+                  (match_operand:SI 2 "shift_operand"    "rL")))]
+  ""
+  "<shift_asm>%i2\\t%0, %1, %z2"
+  [(set_attr "type" "shift")])
+
+(define_insn "rotrsi3"
+  [(set (match_operand:SI 0 "register_operand"             "=r")
+        (rotatert:SI (match_operand:SI 1 "register_operand" "r")
+                     (match_operand:SI 2 "register_operand" "r")))]
+  ""
+  "ror\\t%0, %1, %2"
+  [(set_attr "type" "shift")])
+
+
+
+;; Floating point instructions
+
+;; Mode iterator for single/double float
+(define_mode_iterator F [SF DF])
+(define_mode_attr f [(SF "s") (DF "d")])
+
+;; Basic arithmetic instructions
+(define_code_iterator FOP3 [plus minus mult div])
+(define_code_attr fop3 [(plus "add") (minus "sub") (mult "mul") (div "div")])
+
+(define_insn "<fop3><mode>3"
+  [(set (match_operand:F 0 "register_operand"        "=r")
+        (FOP3:F (match_operand:F 1 "register_operand" "r")
+                (match_operand:F 2 "register_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_f<fop3><f>)"
+  "* return nios2_fpu_insn_asm (n2fpu_f<fop3><f>);"
+  [(set_attr "type" "custom")])
+
+;; Floating point min/max operations
+(define_code_iterator SMINMAX [smin smax])
+(define_code_attr minmax [(smin "min") (smax "max")])
+(define_insn "<code><mode>3"
+  [(set (match_operand:F 0 "register_operand" "=r")
+        (SMINMAX:F (match_operand:F 1 "register_operand" "r")
+                   (match_operand:F 2 "register_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_f<minmax><f>)"
+  "* return nios2_fpu_insn_asm (n2fpu_f<minmax><f>);"
+  [(set_attr "type" "custom")])
+
+;; These 2-operand FP operations can be collected together
+(define_code_iterator FOP2 [abs neg sqrt])
+(define_insn "<code><mode>2"
+  [(set (match_operand:F 0 "register_operand" "=r")
+        (FOP2:F (match_operand:F 1 "register_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_f<code><f>)"
+  "* return nios2_fpu_insn_asm (n2fpu_f<code><f>);"
+  [(set_attr "type" "custom")])
+
+;; X, Y register access instructions
+(define_insn "nios2_fwrx"
+  [(unspec_volatile [(match_operand:DF 0 "register_operand" "r")] UNSPECV_FWRX)]
+  "nios2_fpu_insn_enabled (n2fpu_fwrx)"
+  "* return nios2_fpu_insn_asm (n2fpu_fwrx);"
+  [(set_attr "type" "custom")])
+
+(define_insn "nios2_fwry"
+  [(unspec_volatile [(match_operand:SF 0 "register_operand" "r")] UNSPECV_FWRY)]
+  "nios2_fpu_insn_enabled (n2fpu_fwry)"
+  "* return nios2_fpu_insn_asm (n2fpu_fwry);"
+  [(set_attr "type" "custom")])
+
+;; The X, Y read insns uses an int iterator
+(define_int_iterator UNSPEC_READ_XY [UNSPECV_FRDXLO UNSPECV_FRDXHI
+                                     UNSPECV_FRDY])
+(define_int_attr read_xy [(UNSPECV_FRDXLO "frdxlo") (UNSPECV_FRDXHI "frdxhi")
+                          (UNSPECV_FRDY "frdy")])
+(define_insn "nios2_<read_xy>"
+  [(set (match_operand:SF 0 "register_operand" "=r")
+        (unspec_volatile:SF [(const_int 0)] UNSPEC_READ_XY))]
+  "nios2_fpu_insn_enabled (n2fpu_<read_xy>)"
+  "* return nios2_fpu_insn_asm (n2fpu_<read_xy>);"
+  [(set_attr "type" "custom")])
+
+;; Various math functions
+(define_int_iterator MATHFUNC
+  [UNSPEC_FCOS UNSPEC_FSIN UNSPEC_FTAN UNSPEC_FATAN UNSPEC_FEXP UNSPEC_FLOG])
+(define_int_attr mathfunc [(UNSPEC_FCOS "cos") (UNSPEC_FSIN "sin")
+                           (UNSPEC_FTAN "tan") (UNSPEC_FATAN "atan")
+                           (UNSPEC_FEXP "exp") (UNSPEC_FLOG "log")])
+
+(define_insn "<mathfunc><mode>2"
+  [(set (match_operand:F 0 "register_operand" "=r")
+        (unspec:F [(match_operand:F 1 "register_operand" "r")] MATHFUNC))]
+  "nios2_fpu_insn_enabled (n2fpu_f<mathfunc><f>)"
+  "* return nios2_fpu_insn_asm (n2fpu_f<mathfunc><f>);"
+  [(set_attr "type" "custom")])
+
+;; Converting between floating point and fixed point
+
+(define_code_iterator FLOAT [float unsigned_float])
+(define_code_iterator FIX [fix unsigned_fix])
+
+(define_code_attr conv_op [(float "float") (unsigned_float "floatuns")
+                           (fix "fix") (unsigned_fix "fixuns")])
+(define_code_attr i [(float "i") (unsigned_float "u")
+                     (fix "i") (unsigned_fix "u")])
+
+;; Integer to float conversions
+(define_insn "<conv_op>si<mode>2"
+  [(set (match_operand:F 0 "register_operand" "=r")
+        (FLOAT:F (match_operand:SI 1 "register_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_float<i><f>)"
+  "* return nios2_fpu_insn_asm (n2fpu_float<i><f>);"
+  [(set_attr "type" "custom")])
+
+;; Float to integer conversions
+(define_insn "<conv_op>_trunc<mode>si2"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+        (FIX:SI (match_operand:F 1 "general_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_fix<f><i>)"
+  "* return nios2_fpu_insn_asm (n2fpu_fix<f><i>);"
+  [(set_attr "type" "custom")])
+
+(define_insn "extendsfdf2"
+  [(set (match_operand:DF 0 "register_operand" "=r")
+        (float_extend:DF (match_operand:SF 1 "general_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_fextsd)"
+  "* return nios2_fpu_insn_asm (n2fpu_fextsd);"
+  [(set_attr "type" "custom")])
+
+(define_insn "truncdfsf2"
+  [(set (match_operand:SF 0 "register_operand" "=r")
+        (float_truncate:SF (match_operand:DF 1 "general_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_ftruncds)"
+  "* return nios2_fpu_insn_asm (n2fpu_ftruncds);"
+  [(set_attr "type" "custom")])
+
+
+
+;; Prologue, Epilogue and Return
+
+(define_expand "prologue"
+  [(const_int 1)]
+  ""
+{
+  expand_prologue ();
+  DONE;
+})
+
+(define_expand "epilogue"
+  [(return)]
+  ""
+{
+  expand_epilogue (false);
+  DONE;
+})
+
+(define_expand "sibcall_epilogue"
+  [(return)]
+  ""
+{
+  expand_epilogue (true);
+  DONE;
+})
+
+(define_insn "return"
+  [(return)]
+  "nios2_can_use_return_insn ()"
+  "ret"
+)
+
+(define_insn "return_from_epilogue"
+  [(use (match_operand 0 "pmode_register_operand" ""))
+   (return)]
+  "reload_completed"
+  "ret"
+)
+
+;; Block any insns from being moved before this point, since the
+;; profiling call to mcount can use various registers that aren't
+;; saved or used to pass arguments.
+
+(define_insn "blockage"
+  [(unspec_volatile [(const_int 0)] UNSPECV_BLOCKAGE)]
+  ""
+  ""
+  [(set_attr "type" "unknown")
+   (set_attr "length" "0")])
+
+;; This is used in compiling the unwind routines.
+(define_expand "eh_return"
+  [(use (match_operand 0 "general_operand"))]
+  ""
+{
+  if (GET_MODE (operands[0]) != Pmode)
+    operands[0] = convert_to_mode (Pmode, operands[0], 0);
+  emit_insn (gen_eh_set_ra (operands[0]));
+
+  DONE;
+})
+
+;; Clobber the return address on the stack.  We can't expand this
+;; until we know where it will be put in the stack frame.
+
+(define_insn "eh_set_ra"
+  [(unspec [(match_operand:SI 0 "register_operand" "r")] UNSPEC_EH_RETURN)
+   (clobber (match_scratch:SI 1 "=&r"))]
+ ""
+  "#")
+
+(define_split
+  [(unspec [(match_operand 0 "register_operand")] UNSPEC_EH_RETURN)
+   (clobber (match_scratch 1))]
+  "reload_completed"
+  [(const_int 0)]
+{
+  nios2_set_return_address (operands[0], operands[1]);
+  DONE;
+})
+
+
+;;  Jumps and calls
+
+; Note that the assembler fixes up any out-of-range branch instructions not
+; caught by the compiler branch shortening code.  The sequence emitted by
+; the assembler can be very inefficient, but it is correct for PIC code.
+; For non-PIC we are better off converting to an absolute JMPI.
+;
+; Direct calls and sibcalls use the CALL and JMPI instructions, respectively.
+; These instructions have an immediate operand that specifies the low 28 bits
+; of the PC, effectively allowing direct calls within a 256MB memory segment.
+; Per the Nios II Processor Reference Handbook, the linker is not required to
+; check or adjust for overflow.
+
+(define_insn "indirect_jump"
+  [(set (pc) (match_operand:SI 0 "register_operand" "r"))]
+  ""
+  "jmp\\t%0"
+  [(set_attr "type" "control")])
+
+(define_insn "jump"
+  [(set (pc)
+        (label_ref (match_operand 0 "" "")))]
+  ""
+  {
+    if (flag_pic || get_attr_length (insn) == 4)
+      return "br\\t%0";
+    else
+      return "jmpi\\t%0";
+  }
+  [(set_attr "type" "control")
+   (set (attr "length") 
+        (if_then_else
+	    (and (ge (minus (match_dup 0) (pc)) (const_int -32768))
+	         (le (minus (match_dup 0) (pc)) (const_int 32764)))
+	    (const_int 4)
+	    (const_int 8)))])
+
+
+(define_expand "call"
+  [(parallel [(call (match_operand 0 "" "")
+                    (match_operand 1 "" ""))
+              (clobber (reg:SI 31))])]
+  ""
+  "nios2_adjust_call_address (&XEXP (operands[0], 0));"
+)
+
+(define_expand "call_value"
+  [(parallel [(set (match_operand 0 "" "")
+                   (call (match_operand 1 "" "")
+                         (match_operand 2 "" "")))
+              (clobber (reg:SI 31))])]
+  ""
+  "nios2_adjust_call_address (&XEXP (operands[1], 0));"
+)
+
+(define_insn "*call"
+  [(call (mem:QI (match_operand:SI 0 "call_operand" "i,r"))
+         (match_operand 1 "" ""))
+   (clobber (reg:SI 31))]
+  ""
+  "@
+   call\\t%0
+   callr\\t%0"
+  [(set_attr "type" "control,control")])
+
+(define_insn "*call_value"
+  [(set (match_operand 0 "" "")
+        (call (mem:QI (match_operand:SI 1 "call_operand" "i,r"))
+              (match_operand 2 "" "")))
+   (clobber (reg:SI 31))]
+  ""
+  "@
+   call\\t%1
+   callr\\t%1"
+  [(set_attr "type" "control,control")])
+
+(define_expand "sibcall"
+  [(parallel [(call (match_operand 0 "" "")
+                    (match_operand 1 "" ""))
+              (return)])]
+  ""
+  "nios2_adjust_call_address (&XEXP (operands[0], 0));"
+)
+
+(define_expand "sibcall_value"
+  [(parallel [(set (match_operand 0 "" "")
+                   (call (match_operand 1 "" "")
+                         (match_operand 2 "" "")))
+              (return)])]
+  ""
+  "nios2_adjust_call_address (&XEXP (operands[1], 0));"
+)
+
+(define_insn "*sibcall"
+ [(call (mem:QI (match_operand:SI 0 "call_operand" "i,j"))
+        (match_operand 1 "" ""))
+  (return)]
+  ""
+  "@
+   jmpi\\t%0
+   jmp\\t%0"
+)
+
+(define_insn "*sibcall_value"
+ [(set (match_operand 0 "register_operand" "")
+       (call (mem:QI (match_operand:SI 1 "call_operand" "i,j"))
+             (match_operand 2 "" "")))
+  (return)]
+  ""
+  "@
+   jmpi\\t%1
+   jmp\\t%1"
+)
+
+(define_expand "tablejump"
+  [(parallel [(set (pc) (match_operand 0 "register_operand" "r"))
+              (use (label_ref (match_operand 1 "" "")))])]
+  ""
+  {
+    if (flag_pic)
+      {
+        /* Hopefully, CSE will eliminate this copy.  */
+        rtx reg1 = copy_addr_to_reg (gen_rtx_LABEL_REF (Pmode, operands[1]));
+        rtx reg2 = gen_reg_rtx (SImode);
+
+        emit_insn (gen_addsi3 (reg2, operands[0], reg1));
+        operands[0] = reg2;
+      }
+  }
+)
+
+(define_insn "*tablejump"
+  [(set (pc)
+        (match_operand:SI 0 "register_operand" "r"))
+   (use (label_ref (match_operand 1 "" "")))]
+  ""
+  "jmp\\t%0"
+  [(set_attr "type" "control")])
+
+
+
+;; cstore, cbranch patterns
+
+(define_mode_iterator CM [SI SF DF])
+
+(define_expand "cstore<mode>4"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+        (match_operator:SI 1 "ordered_comparison_operator"
+	  [(match_operand:CM 2 "register_operand")
+	   (match_operand:CM 3 "nonmemory_operand")]))]
+  "nios2_supported_compare_p (<MODE>mode)"
+  {
+    if (!nios2_validate_compare (<MODE>mode, &operands[1], &operands[2],
+                                 &operands[3]))
+      FAIL;
+  })
+
+(define_expand "cbranch<mode>4"
+  [(set (pc)
+     (if_then_else
+       (match_operator 0 "ordered_comparison_operator"
+         [(match_operand:CM 1 "register_operand")
+          (match_operand:CM 2 "nonmemory_operand")])
+       (label_ref (match_operand 3 ""))
+       (pc)))]
+  "nios2_supported_compare_p (<MODE>mode)"
+  {
+    if (!nios2_validate_compare (<MODE>mode, &operands[0], &operands[1],
+                                 &operands[2]))
+      FAIL;
+    if (GET_MODE_CLASS (<MODE>mode) == MODE_FLOAT
+        || !reg_or_0_operand (operands[2], <MODE>mode))
+      {
+        rtx condreg = gen_reg_rtx (SImode);
+        emit_insn (gen_cstore<mode>4
+                    (condreg, operands[0], operands[1], operands[2]));
+        operands[1] = condreg;
+        operands[2] = const0_rtx;
+        operands[0] = gen_rtx_fmt_ee (NE, VOIDmode, condreg, const0_rtx);
+      }
+  })
+
+(define_insn "nios2_cbranch"
+  [(set (pc)
+     (if_then_else
+       (match_operator 0 "ordered_comparison_operator"
+         [(match_operand:SI 1 "reg_or_0_operand" "rM")
+          (match_operand:SI 2 "reg_or_0_operand" "rM")])
+       (label_ref (match_operand 3 "" ""))
+       (pc)))]
+  ""
+  {
+    if (flag_pic || get_attr_length (insn) == 4)
+      return "b%0\t%z1, %z2, %l3";
+    else
+      return "b%R0\t%z1, %z2, .+8;jmpi\t%l3";
+  }
+  [(set_attr "type" "control")
+   (set (attr "length") 
+        (if_then_else
+	    (and (ge (minus (match_dup 1) (pc)) (const_int -32768))
+	         (le (minus (match_dup 1) (pc)) (const_int 32764)))
+	    (const_int 4) (const_int 8)))])
+
+;; Floating point comparisons
+(define_code_iterator FCMP [eq ne gt ge le lt])
+(define_insn "nios2_s<code><mode>"
+  [(set (match_operand:SI 0 "register_operand"        "=r")
+        (FCMP:SI (match_operand:F 1 "register_operand" "r")
+                 (match_operand:F 2 "register_operand" "r")))]
+  "nios2_fpu_insn_enabled (n2fpu_fcmp<code><f>)"
+  "* return nios2_fpu_insn_asm (n2fpu_fcmp<code><f>);"
+  [(set_attr "type" "custom")])
+
+;; Integer comparisons
+
+(define_code_iterator EQNE [eq ne])
+(define_insn "nios2_cmp<code>"
+  [(set (match_operand:SI 0 "register_operand"           "=r")
+        (EQNE:SI (match_operand:SI 1 "reg_or_0_operand" "%rM")
+                 (match_operand:SI 2 "arith_operand"     "rI")))]
+  ""
+  "cmp<code>%i2\\t%0, %z1, %z2"
+  [(set_attr "type" "alu")])
+
+(define_code_iterator SCMP [ge lt])
+(define_insn "nios2_cmp<code>"
+  [(set (match_operand:SI 0 "register_operand"           "=r")
+        (SCMP:SI (match_operand:SI 1 "reg_or_0_operand"  "rM")
+                 (match_operand:SI 2 "arith_operand"     "rI")))]
+  ""
+  "cmp<code>%i2\\t%0, %z1, %z2"
+  [(set_attr "type" "alu")])
+
+(define_code_iterator UCMP [geu ltu])
+(define_insn "nios2_cmp<code>"
+  [(set (match_operand:SI 0 "register_operand"           "=r")
+        (UCMP:SI (match_operand:SI 1 "reg_or_0_operand"  "rM")
+                 (match_operand:SI 2 "uns_arith_operand" "rJ")))]
+  ""
+  "cmp<code>%i2\\t%0, %z1, %z2"
+  [(set_attr "type" "alu")])
+
+
+
+;; Custom instruction patterns. The operands are intentionally
+;; mode-less, to serve as generic carriers of all Altera defined
+;; built-in instruction/function types.
+
+(define_insn "custom_nxx"
+  [(unspec_volatile [(match_operand 0 "custom_insn_opcode" "N")
+                     (match_operand 1 "reg_or_0_operand"  "rM")
+                     (match_operand 2 "reg_or_0_operand"  "rM")]
+    UNSPECV_CUSTOM_NXX)]
+  ""
+  "custom\\t%0, zero, %z1, %z2"
+  [(set_attr "type" "custom")])
+
+(define_insn "custom_xnxx"
+  [(set (match_operand 0 "register_operand"   "=r")
+        (unspec_volatile [(match_operand 1 "custom_insn_opcode" "N")
+                          (match_operand 2 "reg_or_0_operand"  "rM")
+                          (match_operand 3 "reg_or_0_operand"  "rM")] 
+	 UNSPECV_CUSTOM_XNXX))]
+  ""
+  "custom\\t%1, %0, %z2, %z3"
+  [(set_attr "type" "custom")])
+
+
+;;  Misc. patterns
+
+(define_insn "nop"
+  [(const_int 0)]
+  ""
+  "nop"
+  [(set_attr "type" "alu")])
+
+;; Connect 'sync' to 'memory_barrier' standard expand name
+(define_expand "memory_barrier"
+  [(const_int 0)]
+  ""
+{
+  emit_insn (gen_sync ());
+  DONE;
+})
+
+;; For the nios2 __builtin_sync built-in function
+(define_expand "sync"
+  [(set (match_dup 0)
+	(unspec:BLK [(match_dup 0)] UNSPEC_SYNC))]
+  ""
+{
+  operands[0] = gen_rtx_MEM (BLKmode, gen_rtx_SCRATCH (Pmode));
+  MEM_VOLATILE_P (operands[0]) = 1;
+})
+
+(define_insn "*sync_insn"
+  [(set (match_operand:BLK 0 "" "")
+	(unspec:BLK [(match_dup 0)] UNSPEC_SYNC))]
+  ""
+  "sync"
+  [(set_attr "type" "control")])
+
+(define_insn "rdctl"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+        (unspec_volatile:SI [(match_operand:SI 1 "rdwrctl_operand" "O")] 
+	 UNSPECV_RDCTL))]
+  ""
+  "rdctl\\t%0, ctl%1"
+  [(set_attr "type" "control")])
+
+(define_insn "wrctl"
+  [(unspec_volatile:SI [(match_operand:SI 0 "rdwrctl_operand"  "O")
+                        (match_operand:SI 1 "reg_or_0_operand" "rM")] 
+    UNSPECV_WRCTL)]
+  ""
+  "wrctl\\tctl%0, %z1"
+  [(set_attr "type" "control")])
+
+;; Used to signal a stack overflow 
+(define_insn "trap"
+  [(unspec_volatile [(const_int 0)] UNSPECV_TRAP)]
+  ""
+  "break\\t3"
+  [(set_attr "type" "control")])
+  
+(define_insn "stack_overflow_detect_and_trap"
+  [(unspec_volatile [(const_int 0)] UNSPECV_STACK_OVERFLOW_DETECT_AND_TRAP)]
+  ""
+  "bgeu\\tsp, et, 1f\;break\\t3\;1:"
+  [(set_attr "type" "control")
+   (set_attr "length" "8")])
+
+;; Load the GOT register.
+(define_insn "load_got_register"
+  [(set (match_operand:SI 0 "register_operand" "=&r")
+	 (unspec:SI [(const_int 0)] UNSPEC_LOAD_GOT_REGISTER))
+   (set (match_operand:SI 1 "register_operand" "=r")
+	 (unspec:SI [(const_int 0)] UNSPEC_LOAD_GOT_REGISTER))]
+  ""
+  "nextpc\\t%0
+\\t1:
+\\tmovhi\\t%1, %%hiadj(_GLOBAL_OFFSET_TABLE_ - 1b)
+\\taddi\\t%1, %1, %%lo(_GLOBAL_OFFSET_TABLE_ - 1b)"
+  [(set_attr "length" "12")])
+
+;; When generating pic, we need to load the symbol offset into a register.
+;; So that the optimizer does not confuse this with a normal symbol load
+;; we use an unspec.  The offset will be loaded from a constant pool entry,
+;; since that is the only type of relocation we can use.
+
+;; The rather odd constraints on the following are to force reload to leave
+;; the insn alone, and to force the minipool generation pass to then move
+;; the GOT symbol to memory.
+
+(define_insn "pic_load_addr"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+                    (match_operand:SI 2 "" "mX")] UNSPEC_PIC_SYM))]
+  "flag_pic && TARGET_LINUX_ABI"
+  "ldw\\t%0, %%got(%2)(%1)")
+
+(define_insn "pic_load_call_addr"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+                    (match_operand:SI 2 "" "mX")] UNSPEC_PIC_CALL_SYM))]
+  "flag_pic && TARGET_LINUX_ABI"
+  "ldw\\t%0, %%call(%2)(%1)")
+
+;; TLS support
+
+(define_insn "add_tls_gd"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+		   (match_operand:SI 2 "" "mX")] UNSPEC_ADD_TLS_GD))]
+  "TARGET_LINUX_ABI"
+  "addi\t%0, %1, %%tls_gd(%2)")
+
+(define_insn "load_tls_ie"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+		    (match_operand:SI 2 "" "mX")] UNSPEC_LOAD_TLS_IE))]
+  "TARGET_LINUX_ABI"
+  "ldw\t%0, %%tls_ie(%2)(%1)")
+
+(define_insn "add_tls_ldm"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+		    (match_operand:SI 2 "" "mX")] UNSPEC_ADD_TLS_LDM))]
+  "TARGET_LINUX_ABI"
+  "addi\t%0, %1, %%tls_ldm(%2)")
+
+(define_insn "add_tls_ldo"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+		    (match_operand:SI 2 "" "mX")] UNSPEC_ADD_TLS_LDO))]
+  "TARGET_LINUX_ABI"
+  "addi\t%0, %1, %%tls_ldo(%2)")
+
+(define_insn "add_tls_le"
+  [(set (match_operand:SI 0 "register_operand" "=r")
+	(unspec:SI [(match_operand:SI 1 "register_operand" "r")
+		    (match_operand:SI 2 "" "mX")] UNSPEC_ADD_TLS_LE))]
+  "TARGET_LINUX_ABI"
+  "addi\t%0, %1, %%tls_le(%2)")
+
diff --git a/gcc/config/nios2/nios2.opt b/gcc/config/nios2/nios2.opt
new file mode 100644
index 0000000..52b8fcd
--- /dev/null
+++ b/gcc/config/nios2/nios2.opt
@@ -0,0 +1,527 @@
+; Options for the Altera Nios II port of the compiler.
+; Copyright (C) 2012 Free Software Foundation, Inc.
+; Contributed by Altera and Mentor Graphics, Inc.
+;
+; This file is part of GCC.
+;
+; GCC is free software; you can redistribute it and/or modify
+; it under the terms of the GNU General Public License as published by
+; the Free Software Foundation; either version 3, or (at your option)
+; any later version.
+;
+; GCC is distributed in the hope that it will be useful,
+; but WITHOUT ANY WARRANTY; without even the implied warranty of
+; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+; GNU General Public License for more details.
+;
+; You should have received a copy of the GNU General Public License
+; along with GCC; see the file COPYING3.  If not see
+; <http://www.gnu.org/licenses/>.
+
+HeaderInclude
+config/nios2/nios2-opts.h
+
+TargetSave
+int saved_fpu_custom_code[n2fpu_code_num]
+
+TargetSave
+enum nios2_ccs_code saved_custom_code_status[256]
+
+TargetSave
+int saved_custom_code_index[256]
+
+mhw-div
+Target Report Mask(HAS_DIV)
+Enable DIV, DIVU
+
+mhw-mul
+Target Report Mask(HAS_MUL)
+Enable MUL instructions
+
+mhw-mulx
+Target Report Mask(HAS_MULX)
+Enable MULX instructions, assume fast shifter
+
+mfast-sw-div
+Target Report Mask(FAST_SW_DIV)
+Use table based fast divide (default at -O3)
+
+mbypass-cache
+Target Report Mask(BYPASS_CACHE)
+All memory accesses use I/O load/store instructions
+
+mno-cache-volatile
+Target Report RejectNegative Mask(BYPASS_CACHE_VOLATILE)
+Volatile memory accesses use I/O load/store instructions
+
+mcache-volatile
+Target Report RejectNegative Undocumented InverseMask(BYPASS_CACHE_VOLATILE)
+Volatile memory accesses do not use I/O load/store instructions
+
+meb
+Target Report RejectNegative Mask(BIG_ENDIAN)
+Use big-endian byte order
+
+mel
+Target Report RejectNegative InverseMask(BIG_ENDIAN)
+Use little-endian byte order
+
+mcustom-fpu-cfg=
+Target RejectNegative Joined Var(nios2_custom_fpu_cfg_string)
+Floating point custom instruction configuration name
+
+mno-custom-ftruncds
+Target Report RejectNegative Var(nios2_custom_ftruncds, -1)
+Do not use the ftruncds custom instruction
+
+mcustom-ftruncds=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_ftruncds) Init(-1)
+Integer id (N) of ftruncds custom instruction
+
+mno-custom-fextsd
+Target Report RejectNegative Var(nios2_custom_fextsd, -1)
+Do not use the fextsd custom instruction
+
+mcustom-fextsd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fextsd) Init(-1)
+Integer id (N) of fextsd custom instruction
+
+mno-custom-fixdu
+Target Report RejectNegative Var(nios2_custom_fixdu, -1)
+Do not use the fixdu custom instruction
+
+mcustom-fixdu=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fixdu) Init(-1)
+Integer id (N) of fixdu custom instruction
+
+mno-custom-fixdi
+Target Report RejectNegative Var(nios2_custom_fixdi, -1)
+Do not use the fixdi custom instruction
+
+mcustom-fixdi=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fixdi) Init(-1)
+Integer id (N) of fixdi custom instruction
+
+mno-custom-fixsu
+Target Report RejectNegative Var(nios2_custom_fixsu, -1)
+Do not use the fixsu custom instruction
+
+mcustom-fixsu=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fixsu) Init(-1)
+Integer id (N) of fixsu custom instruction
+
+mno-custom-fixsi
+Target Report RejectNegative Var(nios2_custom_fixsi, -1)
+Do not use the fixsi custom instruction
+
+mcustom-fixsi=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fixsi) Init(-1)
+Integer id (N) of fixsi custom instruction
+
+mno-custom-floatud
+Target Report RejectNegative Var(nios2_custom_floatud, -1)
+Do not use the floatud custom instruction
+
+mcustom-floatud=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_floatud) Init(-1)
+Integer id (N) of floatud custom instruction
+
+mno-custom-floatid
+Target Report RejectNegative Var(nios2_custom_floatid, -1)
+Do not use the floatid custom instruction
+
+mcustom-floatid=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_floatid) Init(-1)
+Integer id (N) of floatid custom instruction
+
+mno-custom-floatus
+Target Report RejectNegative Var(nios2_custom_floatus, -1)
+Do not use the floatus custom instruction
+
+mcustom-floatus=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_floatus) Init(-1)
+Integer id (N) of floatus custom instruction
+
+mno-custom-floatis
+Target Report RejectNegative Var(nios2_custom_floatis, -1)
+Do not use the floatis custom instruction
+
+mcustom-floatis=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_floatis) Init(-1)
+Integer id (N) of floatis custom instruction
+
+mno-custom-fcmpned
+Target Report RejectNegative Var(nios2_custom_fcmpned, -1)
+Do not use the fcmpned custom instruction
+
+mcustom-fcmpned=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpned) Init(-1)
+Integer id (N) of fcmpned custom instruction
+
+mno-custom-fcmpeqd
+Target Report RejectNegative Var(nios2_custom_fcmpeqd, -1)
+Do not use the fcmpeqd custom instruction
+
+mcustom-fcmpeqd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpeqd) Init(-1)
+Integer id (N) of fcmpeqd custom instruction
+
+mno-custom-fcmpged
+Target Report RejectNegative Var(nios2_custom_fcmpged, -1)
+Do not use the fcmpged custom instruction
+
+mcustom-fcmpged=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpged) Init(-1)
+Integer id (N) of fcmpged custom instruction
+
+mno-custom-fcmpgtd
+Target Report RejectNegative Var(nios2_custom_fcmpgtd, -1)
+Do not use the fcmpgtd custom instruction
+
+mcustom-fcmpgtd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpgtd) Init(-1)
+Integer id (N) of fcmpgtd custom instruction
+
+mno-custom-fcmpled
+Target Report RejectNegative Var(nios2_custom_fcmpled, -1)
+Do not use the fcmpled custom instruction
+
+mcustom-fcmpled=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpled) Init(-1)
+Integer id (N) of fcmpled custom instruction
+
+mno-custom-fcmpltd
+Target Report RejectNegative Var(nios2_custom_fcmpltd, -1)
+Do not use the fcmpltd custom instruction
+
+mcustom-fcmpltd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpltd) Init(-1)
+Integer id (N) of fcmpltd custom instruction
+
+mno-custom-flogd
+Target Report RejectNegative Var(nios2_custom_flogd, -1)
+Do not use the flogd custom instruction
+
+mcustom-flogd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_flogd) Init(-1)
+Integer id (N) of flogd custom instruction
+
+mno-custom-fexpd
+Target Report RejectNegative Var(nios2_custom_fexpd, -1)
+Do not use the fexpd custom instruction
+
+mcustom-fexpd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fexpd) Init(-1)
+Integer id (N) of fexpd custom instruction
+
+mno-custom-fatand
+Target Report RejectNegative Var(nios2_custom_fatand, -1)
+Do not use the fatand custom instruction
+
+mcustom-fatand=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fatand) Init(-1)
+Integer id (N) of fatand custom instruction
+
+mno-custom-ftand
+Target Report RejectNegative Var(nios2_custom_ftand, -1)
+Do not use the ftand custom instruction
+
+mcustom-ftand=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_ftand) Init(-1)
+Integer id (N) of ftand custom instruction
+
+mno-custom-fsind
+Target Report RejectNegative Var(nios2_custom_fsind, -1)
+Do not use the fsind custom instruction
+
+mcustom-fsind=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fsind) Init(-1)
+Integer id (N) of fsind custom instruction
+
+mno-custom-fcosd
+Target Report RejectNegative Var(nios2_custom_fcosd, -1)
+Do not use the fcosd custom instruction
+
+mcustom-fcosd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcosd) Init(-1)
+Integer id (N) of fcosd custom instruction
+
+mno-custom-fsqrtd
+Target Report RejectNegative Var(nios2_custom_fsqrtd, -1)
+Do not use the fsqrtd custom instruction
+
+mcustom-fsqrtd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fsqrtd) Init(-1)
+Integer id (N) of fsqrtd custom instruction
+
+mno-custom-fabsd
+Target Report RejectNegative Var(nios2_custom_fabsd, -1)
+Do not use the fabsd custom instruction
+
+mcustom-fabsd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fabsd) Init(-1)
+Integer id (N) of fabsd custom instruction
+
+mno-custom-fnegd
+Target Report RejectNegative Var(nios2_custom_fnegd, -1)
+Do not use the fnegd custom instruction
+
+mcustom-fnegd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fnegd) Init(-1)
+Integer id (N) of fnegd custom instruction
+
+mno-custom-fmaxd
+Target Report RejectNegative Var(nios2_custom_fmaxd, -1)
+Do not use the fmaxd custom instruction
+
+mcustom-fmaxd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fmaxd) Init(-1)
+Integer id (N) of fmaxd custom instruction
+
+mno-custom-fmind
+Target Report RejectNegative Var(nios2_custom_fmind, -1)
+Do not use the fmind custom instruction
+
+mcustom-fmind=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fmind) Init(-1)
+Integer id (N) of fmind custom instruction
+
+mno-custom-fdivd
+Target Report RejectNegative Var(nios2_custom_fdivd, -1)
+Do not use the fdivd custom instruction
+
+mcustom-fdivd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fdivd) Init(-1)
+Integer id (N) of fdivd custom instruction
+
+mno-custom-fmuld
+Target Report RejectNegative Var(nios2_custom_fmuld, -1)
+Do not use the fmuld custom instruction
+
+mcustom-fmuld=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fmuld) Init(-1)
+Integer id (N) of fmuld custom instruction
+
+mno-custom-fsubd
+Target Report RejectNegative Var(nios2_custom_fsubd, -1)
+Do not use the fsubd custom instruction
+
+mcustom-fsubd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fsubd) Init(-1)
+Integer id (N) of fsubd custom instruction
+
+mno-custom-faddd
+Target Report RejectNegative Var(nios2_custom_faddd, -1)
+Do not use the faddd custom instruction
+
+mcustom-faddd=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_faddd) Init(-1)
+Integer id (N) of faddd custom instruction
+
+mno-custom-fcmpnes
+Target Report RejectNegative Var(nios2_custom_fcmpnes, -1)
+Do not use the fcmpnes custom instruction
+
+mcustom-fcmpnes=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpnes) Init(-1)
+Integer id (N) of fcmpnes custom instruction
+
+mno-custom-fcmpeqs
+Target Report RejectNegative Var(nios2_custom_fcmpeqs, -1)
+Do not use the fcmpeqs custom instruction
+
+mcustom-fcmpeqs=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpeqs) Init(-1)
+Integer id (N) of fcmpeqs custom instruction
+
+mno-custom-fcmpges
+Target Report RejectNegative Var(nios2_custom_fcmpges, -1)
+Do not use the fcmpges custom instruction
+
+mcustom-fcmpges=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpges) Init(-1)
+Integer id (N) of fcmpges custom instruction
+
+mno-custom-fcmpgts
+Target Report RejectNegative Var(nios2_custom_fcmpgts, -1)
+Do not use the fcmpgts custom instruction
+
+mcustom-fcmpgts=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmpgts) Init(-1)
+Integer id (N) of fcmpgts custom instruction
+
+mno-custom-fcmples
+Target Report RejectNegative Var(nios2_custom_fcmples, -1)
+Do not use the fcmples custom instruction
+
+mcustom-fcmples=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmples) Init(-1)
+Integer id (N) of fcmples custom instruction
+
+mno-custom-fcmplts
+Target Report RejectNegative Var(nios2_custom_fcmplts, -1)
+Do not use the fcmplts custom instruction
+
+mcustom-fcmplts=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcmplts) Init(-1)
+Integer id (N) of fcmplts custom instruction
+
+mno-custom-flogs
+Target Report RejectNegative Var(nios2_custom_flogs, -1)
+Do not use the flogs custom instruction
+
+mcustom-flogs=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_flogs) Init(-1)
+Integer id (N) of flogs custom instruction
+
+mno-custom-fexps
+Target Report RejectNegative Var(nios2_custom_fexps, -1)
+Do not use the fexps custom instruction
+
+mcustom-fexps=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fexps) Init(-1)
+Integer id (N) of fexps custom instruction
+
+mno-custom-fatans
+Target Report RejectNegative Var(nios2_custom_fatans, -1)
+Do not use the fatans custom instruction
+
+mcustom-fatans=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fatans) Init(-1)
+Integer id (N) of fatans custom instruction
+
+mno-custom-ftans
+Target Report RejectNegative Var(nios2_custom_ftans, -1)
+Do not use the ftans custom instruction
+
+mcustom-ftans=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_ftans) Init(-1)
+Integer id (N) of ftans custom instruction
+
+mno-custom-fsins
+Target Report RejectNegative Var(nios2_custom_fsins, -1)
+Do not use the fsins custom instruction
+
+mcustom-fsins=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fsins) Init(-1)
+Integer id (N) of fsins custom instruction
+
+mno-custom-fcoss
+Target Report RejectNegative Var(nios2_custom_fcoss, -1)
+Do not use the fcoss custom instruction
+
+mcustom-fcoss=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fcoss) Init(-1)
+Integer id (N) of fcoss custom instruction
+
+mno-custom-fsqrts
+Target Report RejectNegative Var(nios2_custom_fsqrts, -1)
+Do not use the fsqrts custom instruction
+
+mcustom-fsqrts=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fsqrts) Init(-1)
+Integer id (N) of fsqrts custom instruction
+
+mno-custom-fabss
+Target Report RejectNegative Var(nios2_custom_fabss, -1)
+Do not use the fabss custom instr
+
+mcustom-fabss=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fabss) Init(-1)
+Integer id (N) of fabss custom instruction
+
+mno-custom-fnegs
+Target Report RejectNegative Var(nios2_custom_fnegs, -1)
+Do not use the fnegs custom instruction
+
+mcustom-fnegs=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fnegs) Init(-1)
+Integer id (N) of fnegs custom instruction
+
+mno-custom-fmaxs
+Target Report RejectNegative Var(nios2_custom_fmaxs, -1)
+Do not use the fmaxs custom instruction
+
+mcustom-fmaxs=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fmaxs) Init(-1)
+Integer id (N) of fmaxs custom instruction
+
+mno-custom-fmins
+Target Report RejectNegative Var(nios2_custom_fmins, -1)
+Do not use the fmins custom instruction
+
+mcustom-fmins=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fmins) Init(-1)
+Integer id (N) of fmins custom instruction
+
+mno-custom-fdivs
+Target Report RejectNegative Var(nios2_custom_fdivs, -1)
+Do not use the fdivs custom instruction
+
+mcustom-fdivs=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fdivs) Init(-1)
+Integer id (N) of fdivs custom instruction
+
+mno-custom-fmuls
+Target Report RejectNegative Var(nios2_custom_fmuls, -1)
+Do not use the fmuls custom instruction
+
+mcustom-fmuls=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fmuls) Init(-1)
+Integer id (N) of fmuls custom instruction
+
+mno-custom-fsubs
+Target Report RejectNegative Var(nios2_custom_fsubs, -1)
+Do not use the fsubs custom instruction
+
+mcustom-fsubs=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fsubs) Init(-1)
+Integer id (N) of fsubs custom instruction
+
+mno-custom-fadds
+Target Report RejectNegative Var(nios2_custom_fadds, -1)
+Do not use the fadds custom instruction
+
+mcustom-fadds=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fadds) Init(-1)
+Integer id (N) of fadds custom instruction
+
+mno-custom-frdy
+Target Report RejectNegative Var(nios2_custom_frdy, -1)
+Do not use the frdy custom instruction
+
+mcustom-frdy=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_frdy) Init(-1)
+Integer id (N) of frdy custom instruction
+
+mno-custom-frdxhi
+Target Report RejectNegative Var(nios2_custom_frdxhi, -1)
+Do not use the frdxhi custom instruction
+
+mcustom-frdxhi=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_frdxhi) Init(-1)
+Integer id (N) of frdxhi custom instruction
+
+mno-custom-frdxlo
+Target Report RejectNegative Var(nios2_custom_frdxlo, -1)
+Do not use the frdxlo custom instruction
+
+mcustom-frdxlo=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_frdxlo) Init(-1)
+Integer id (N) of frdxlo custom instruction
+
+mno-custom-fwry
+Target Report RejectNegative Var(nios2_custom_fwry, -1)
+Do not use the fwry custom instruction
+
+mcustom-fwry=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fwry) Init(-1)
+Integer id (N) of fwry custom instruction
+
+mno-custom-fwrx
+Target Report RejectNegative Var(nios2_custom_fwrx, -1)
+Do not use the fwrx custom instruction
+
+mcustom-fwrx=
+Target Report RejectNegative Joined UInteger Var(nios2_custom_fwrx) Init(-1)
+Integer id (N) of fwrx custom instruction
diff --git a/gcc/config/nios2/predicates.md b/gcc/config/nios2/predicates.md
new file mode 100644
index 0000000..ac20c5e
--- /dev/null
+++ b/gcc/config/nios2/predicates.md
@@ -0,0 +1,72 @@
+;; Predicate definitions for Altera Nios II.
+;; Copyright (C) 2012 Free Software Foundation, Inc.
+;; Contributed by Chung-Lin Tang <cltang@codesourcery.com>
+;;
+;; This file is part of GCC.
+;;
+;; GCC is free software; you can redistribute it and/or modify
+;; it under the terms of the GNU General Public License as published by
+;; the Free Software Foundation; either version 3, or (at your option)
+;; any later version.
+;;
+;; GCC is distributed in the hope that it will be useful,
+;; but WITHOUT ANY WARRANTY; without even the implied warranty of
+;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+;; GNU General Public License for more details.
+;;
+;; You should have received a copy of the GNU General Public License
+;; along with GCC; see the file COPYING3.  If not see
+;; <http://www.gnu.org/licenses/>.
+
+(define_predicate "const_0_operand"
+  (and (match_code "const_int,const_double,const_vector")
+       (match_test "op == CONST0_RTX (GET_MODE (op))")))
+
+(define_predicate "reg_or_0_operand"
+  (ior (match_operand 0 "const_0_operand")
+       (match_operand 0 "register_operand")))
+
+(define_predicate "const_uns_arith_operand"
+  (and (match_code "const_int")
+       (match_test "SMALL_INT_UNSIGNED (INTVAL (op))")))
+
+(define_predicate "uns_arith_operand"
+  (ior (match_operand 0 "const_uns_arith_operand")
+       (match_operand 0 "register_operand")))
+
+(define_predicate "const_arith_operand"
+  (and (match_code "const_int")
+       (match_test "SMALL_INT (INTVAL (op))")))
+
+(define_predicate "arith_operand"
+  (ior (match_operand 0 "const_arith_operand")
+       (match_operand 0 "register_operand")))
+
+(define_predicate "const_logical_operand"
+  (and (match_code "const_int")
+       (match_test "(INTVAL (op) & 0xffff) == 0
+                    || (INTVAL (op) & 0xffff0000) == 0")))
+
+(define_predicate "logical_operand"
+  (ior (match_operand 0 "const_logical_operand")
+       (match_operand 0 "register_operand")))
+
+(define_predicate "const_shift_operand"
+  (and (match_code "const_int")
+       (match_test "SHIFT_INT (INTVAL (op))")))
+
+(define_predicate "shift_operand"
+  (ior (match_operand 0 "const_shift_operand")
+       (match_operand 0 "register_operand")))
+
+(define_predicate "call_operand"
+  (ior (match_operand 0 "immediate_operand")
+       (match_operand 0 "register_operand")))
+
+(define_predicate "rdwrctl_operand"
+  (and (match_code "const_int")
+       (match_test "RDWRCTL_INT (INTVAL (op))")))
+
+(define_predicate "custom_insn_opcode"
+  (and (match_code "const_int")
+       (match_test "CUSTOM_INSN_OPCODE (INTVAL (op))")))
diff --git a/gcc/config/nios2/t-nios2 b/gcc/config/nios2/t-nios2
new file mode 100644
index 0000000..aa95b00
--- /dev/null
+++ b/gcc/config/nios2/t-nios2
@@ -0,0 +1,131 @@
+# Target Makefile Fragment for Altera Nios II.
+# Copyright (C) 2012 Free Software Foundation, Inc.
+# Contributed by Altera and Mentor Graphics, Inc.
+#
+# This file is part of GCC.
+#
+# GCC is free software; you can redistribute it and/or modify it
+# under the terms of the GNU General Public License as published
+# by the Free Software Foundation; either version 3, or (at your
+# option) any later version.
+#
+# GCC is distributed in the hope that it will be useful, but WITHOUT
+# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
+# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
+# License for more details.
+#
+# You should have received a copy of the GNU General Public License
+# along with GCC; see the file COPYING3.  If not see
+# <http://www.gnu.org/licenses/>.
+
+
+## MULTILIB_OPTIONS
+## For some targets, invoking GCC in different ways produces objects that
+## can not be linked together.  For example, for some targets GCC produces
+## both big and little endian code.  For these targets, you must arrange
+## for multiple versions of libgcc.a to be compiled, one for each set of
+## incompatible options.  When GCC invokes the linker, it arranges to link
+## in the right version of libgcc.a, based on the command line options
+## used.
+## The MULTILIB_OPTIONS macro lists the set of options for which special
+## versions of libgcc.a must be built.  Write options that are mutually
+## incompatible side by side, separated by a slash.  Write options that may
+## be used together separated by a space.  The build procedure will build
+## all combinations of compatible options.
+##
+## For example, if you set MULTILIB_OPTIONS to m68000/m68020 msoft-float,
+## Makefile will build special versions of libgcc.a using the following
+## sets of options: -m68000, -m68020, -msoft-float, -m68000 -msoft-float,
+## and -m68020 -msoft-float.
+
+
+## The BUILD_BE_MULTILIB and BUILD_PG_MULTILIB variables allow the
+## makefile user to enable/disable the generation of the precompiled
+## big endian and profiling libraries. By default, the big endian 
+## libraries are not created on a windows build and the profiling
+## libraries are not created on a Solaris build. All other library 
+## combinations are created by default.
+
+# Uncomment to temporarily avoid building big endian and profiling libraries during a Windows build.
+#ifeq ($(DEV_HOST_OS), win32)
+#BUILD_BE_MULTILIB ?= 0
+#BUILD_PG_MULTILIB ?= 0
+#endif
+
+#By default, avoid building the profiling libraries during a Solaris build.
+ifeq ($(DEV_HOST_OS), solaris)
+BUILD_PG_MULTILIB ?= 0
+endif
+
+BUILD_BE_MULTILIB ?= 0
+BUILD_PG_MULTILIB ?= 1
+BUILD_MULTILIB ?= 0
+
+ifeq ($(BUILD_MULTILIB), 1)
+
+MULTILIB_OPTIONS = mno-hw-mul mhw-mulx mstack-check mcustom-fpu-cfg=60-1 mcustom-fpu-cfg=60-2
+
+#Add the profiling flag to the multilib variable if required
+ifeq ($(BUILD_PG_MULTILIB), 1)
+MULTILIB_OPTIONS += pg
+endif
+
+#Add the big endian flag to the multilib variable if required
+ifeq ($(BUILD_BE_MULTILIB), 1)
+MULTILIB_OPTIONS += EB/EL
+endif
+
+endif
+
+## MULTILIB_DIRNAMES
+## If MULTILIB_OPTIONS is used, this variable specifies the directory names
+## that should be used to hold the various libraries.  Write one element in
+## MULTILIB_DIRNAMES for each element in MULTILIB_OPTIONS. If
+## MULTILIB_DIRNAMES is not used, the default value will be
+## MULTILIB_OPTIONS, with all slashes treated as spaces.
+## For example, if MULTILIB_OPTIONS is set to m68000/m68020 msoft-float,
+## then the default value of MULTILIB_DIRNAMES is m68000 m68020
+## msoft-float.  You may specify a different value if you desire a
+## different set of directory names.
+
+# MULTILIB_DIRNAMES =
+
+## MULTILIB_MATCHES
+## Sometimes the same option may be written in two different ways.  If an
+## option is listed in MULTILIB_OPTIONS, GCC needs to know about any
+## synonyms.  In that case, set MULTILIB_MATCHES to a list of items of the
+## form option=option to describe all relevant synonyms.  For example,
+## m68000=mc68000 m68020=mc68020.
+
+ifeq ($(BUILD_MULTILIB), 1)
+ifeq ($(BUILD_BE_MULTILIB), 1)
+MULTILIB_MATCHES = EL=mel EB=meb
+endif
+endif
+
+##
+## MULTILIB_EXCEPTIONS
+## Sometimes when there are multiple sets of MULTILIB_OPTIONS being
+## specified, there are combinations that should not be built.  In that
+## case, set MULTILIB_EXCEPTIONS to be all of the switch exceptions in
+## shell case syntax that should not be built.
+## For example, in the PowerPC embedded ABI support, it is not desirable to
+## build libraries compiled with the -mcall-aix option and either of the
+## -fleading-underscore or -mlittle options at the same time.  Therefore
+## MULTILIB_EXCEPTIONS is set to
+##
+## *mcall-aix/*fleading-underscore* *mlittle/*mcall-aix*
+##
+
+ifeq ($(BUILD_MULTILIB), 1)
+MULTILIB_EXCEPTIONS = *mno-hw-mul/*mhw-mulx* *mcustom-fpu-cfg=60-1/*mcustom-fpu-cfg=60-2*
+endif
+
+##
+## MULTILIB_EXTRA_OPTS Sometimes it is desirable that when building
+## multiple versions of libgcc.a certain options should always be passed on
+## to the compiler.  In that case, set MULTILIB_EXTRA_OPTS to be the list
+## of options to be used for all builds.
+##
+
+
diff --git a/libgcc/config.host b/libgcc/config.host
index d8e7255..6cb1651 100644
--- a/libgcc/config.host
+++ b/libgcc/config.host
@@ -135,6 +135,9 @@ mips*-*-*)
 	cpu_type=mips
 	tmake_file=mips/t-mips
 	;;
+nios2*-*-*)
+        cpu_type=nios2
+        ;;
 powerpc*-*-*)
 	cpu_type=rs6000
 	;;
@@ -829,6 +832,15 @@ moxie-*-rtems*)
 	# Don't use default.
 	extra_parts=
 	;;
+nios2-*-linux*)
+        tmake_file="$tmake_file nios2/t-nios2 nios2/t-linux t-libgcc-pic t-slibgcc-libgcc"
+        extra_parts="$extra_parts crti.o crtn.o"
+        md_unwind_header=nios2/linux-unwind.h
+        ;;
+nios2-*-*)
+        tmake_file="$tmake_file nios2/t-nios2 t-fdpbit"
+        extra_parts="$extra_parts crti.o crtn.o"
+        ;;
 pdp11-*-*)
 	tmake_file="pdp11/t-pdp11 t-fdpbit"
 	;;
diff --git a/libgcc/config/nios2/crti.S b/libgcc/config/nios2/crti.S
new file mode 100644
index 0000000..4f17f19
--- /dev/null
+++ b/libgcc/config/nios2/crti.S
@@ -0,0 +1,88 @@
+/* Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Jonah Graham (jgraham@altera.com).
+   Contributed by Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+
+/* This file just make a stack frame for the contents of the .fini and
+.init sections.  Users may put any desired instructions in those
+sections.
+
+While technically any code can be put in the init and fini sections
+most stuff will not work other than stuff which obeys the call frame
+and ABI. All the call-preserved registers are saved, the call clobbered
+registers should have been saved by the code calling init and fini.
+
+See crtstuff.c for an example of code that inserts itself in the 
+init and fini sections. 
+
+See crt0.s for the code that calls init and fini.
+*/
+
+	.file	"crti.asm"
+
+	.section	".init"
+	.align 2
+	.global	_init
+_init:
+	addi	sp, sp, -48
+	stw	ra, 44(sp)
+	stw	r23, 40(sp)
+	stw	r22, 36(sp)
+	stw	r21, 32(sp)
+	stw	r20, 28(sp)
+	stw	r19, 24(sp)
+	stw	r18, 20(sp)
+	stw	r17, 16(sp)
+	stw	r16, 12(sp)
+	stw	fp, 8(sp)
+	addi	fp, sp, 8
+#ifdef linux
+	nextpc	r22
+1:	movhi	r2, %hiadj(_GLOBAL_OFFSET_TABLE_ - 1b)
+	addi	r2, r2, %lo(_GLOBAL_OFFSET_TABLE_ - 1b)
+	add	r22, r22, r2
+#endif
+	
+	
+	.section	".fini"
+	.align	2
+	.global	_fini
+_fini:
+	addi	sp, sp, -48
+	stw	ra, 44(sp)
+	stw	r23, 40(sp)
+	stw	r22, 36(sp)
+	stw	r21, 32(sp)
+	stw	r20, 28(sp)
+	stw	r19, 24(sp)
+	stw	r18, 20(sp)
+	stw	r17, 16(sp)
+	stw	r16, 12(sp)
+	stw	fp, 8(sp)
+	addi	fp, sp, 8
+#ifdef linux
+	nextpc	r22
+1:	movhi	r2, %hiadj(_GLOBAL_OFFSET_TABLE_ - 1b)
+	addi	r2, r2, %lo(_GLOBAL_OFFSET_TABLE_ - 1b)
+	add	r22, r22, r2
+#endif
+
diff --git a/libgcc/config/nios2/crtn.S b/libgcc/config/nios2/crtn.S
new file mode 100644
index 0000000..71ef2a0
--- /dev/null
+++ b/libgcc/config/nios2/crtn.S
@@ -0,0 +1,60 @@
+/* Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Jonah Graham (jgraham@altera.com).
+   Contributed by Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+
+/* This file just makes sure that the .fini and .init sections do in
+fact return.  Users may put any desired instructions in those sections.
+This file is the last thing linked into any executable.
+*/	
+	.file	"crtn.asm"
+
+
+
+	.section	".init"
+	ldw	ra, 44(sp)
+	ldw	r23, 40(sp)
+	ldw	r22, 36(sp)
+	ldw	r21, 32(sp)
+	ldw	r20, 28(sp)
+	ldw	r19, 24(sp)
+	ldw	r18, 20(sp)
+	ldw	r17, 16(sp)
+	ldw	r16, 12(sp)
+	ldw	fp, 8(sp)
+	addi	sp, sp, 48
+	ret
+	
+	.section	".fini"
+	ldw	ra, 44(sp)
+	ldw	r23, 40(sp)
+	ldw	r22, 36(sp)
+	ldw	r21, 32(sp)
+	ldw	r20, 28(sp)
+	ldw	r19, 24(sp)
+	ldw	r18, 20(sp)
+	ldw	r17, 16(sp)
+	ldw	r16, 12(sp)
+	ldw	fp, 8(sp)
+	addi	sp, sp, 48
+	ret
+
diff --git a/libgcc/config/nios2/lib2-divmod-hi.c b/libgcc/config/nios2/lib2-divmod-hi.c
new file mode 100644
index 0000000..6efe9eb
--- /dev/null
+++ b/libgcc/config/nios2/lib2-divmod-hi.c
@@ -0,0 +1,116 @@
+/* Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Altera and Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+#include "lib2-nios2.h"
+
+/* 16-bit HI divide and modulo as used in Nios II.  */
+
+static UHItype
+udivmodhi4 (UHItype num, UHItype den, word_type modwanted)
+{
+  UHItype bit = 1;
+  UHItype res = 0;
+
+  while (den < num && bit && !(den & (1L<<15)))
+    {
+      den <<=1;
+      bit <<=1;
+    }
+  while (bit)
+    {
+      if (num >= den)
+	{
+	  num -= den;
+	  res |= bit;
+	}
+      bit >>=1;
+      den >>=1;
+    }
+  if (modwanted) return num;
+  return res;
+}
+
+
+HItype
+__divhi3 (HItype a, HItype b)
+{
+  word_type neg = 0;
+  HItype res;
+
+  if (a < 0)
+    {
+      a = -a;
+      neg = !neg;
+    }
+
+  if (b < 0)
+    {
+      b = -b;
+      neg = !neg;
+    }
+
+  res = udivmodhi4 (a, b, 0);
+
+  if (neg)
+    res = -res;
+
+  return res;
+}
+
+
+HItype
+__modhi3 (HItype a, HItype b)
+{
+  word_type neg = 0;
+  HItype res;
+
+  if (a < 0)
+    {
+      a = -a;
+      neg = 1;
+    }
+
+  if (b < 0)
+    b = -b;
+
+  res = udivmodhi4 (a, b, 1);
+
+  if (neg)
+    res = -res;
+
+  return res;
+}
+
+
+UHItype
+__udivhi3 (UHItype a, UHItype b)
+{
+  return udivmodhi4 (a, b, 0);
+}
+
+
+UHItype
+__umodhi3 (UHItype a, UHItype b)
+{
+  return udivmodhi4 (a, b, 1);
+}
+
diff --git a/libgcc/config/nios2/lib2-divmod.c b/libgcc/config/nios2/lib2-divmod.c
new file mode 100644
index 0000000..cd1a674
--- /dev/null
+++ b/libgcc/config/nios2/lib2-divmod.c
@@ -0,0 +1,116 @@
+/* Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Altera and Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+#include "lib2-nios2.h"
+
+/* 32-bit SI divide and modulo as used in Nios II.  */
+
+static USItype
+udivmodsi4 (USItype num, USItype den, word_type modwanted)
+{
+  USItype bit = 1;
+  USItype res = 0;
+
+  while (den < num && bit && !(den & (1L<<31)))
+    {
+      den <<=1;
+      bit <<=1;
+    }
+  while (bit)
+    {
+      if (num >= den)
+	{
+	  num -= den;
+	  res |= bit;
+	}
+      bit >>=1;
+      den >>=1;
+    }
+  if (modwanted) return num;
+  return res;
+}
+
+
+SItype
+__divsi3 (SItype a, SItype b)
+{
+  word_type neg = 0;
+  SItype res;
+
+  if (a < 0)
+    {
+      a = -a;
+      neg = !neg;
+    }
+
+  if (b < 0)
+    {
+      b = -b;
+      neg = !neg;
+    }
+
+  res = udivmodsi4 (a, b, 0);
+
+  if (neg)
+    res = -res;
+
+  return res;
+}
+
+
+SItype
+__modsi3 (SItype a, SItype b)
+{
+  word_type neg = 0;
+  SItype res;
+
+  if (a < 0)
+    {
+      a = -a;
+      neg = 1;
+    }
+
+  if (b < 0)
+    b = -b;
+
+  res = udivmodsi4 (a, b, 1);
+
+  if (neg)
+    res = -res;
+
+  return res;
+}
+
+
+SItype
+__udivsi3 (SItype a, SItype b)
+{
+  return udivmodsi4 (a, b, 0);
+}
+
+
+SItype
+__umodsi3 (SItype a, SItype b)
+{
+  return udivmodsi4 (a, b, 1);
+}
+
diff --git a/libgcc/config/nios2/lib2-divtable.c b/libgcc/config/nios2/lib2-divtable.c
new file mode 100644
index 0000000..8c003f9
--- /dev/null
+++ b/libgcc/config/nios2/lib2-divtable.c
@@ -0,0 +1,60 @@
+/* Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Altera and Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+#include "lib2-nios2.h"
+
+UQItype __divsi3_table[] =
+{
+  0, 0/1, 0/2, 0/3, 0/4, 0/5, 0/6, 0/7,
+    0/8, 0/9, 0/10, 0/11, 0/12, 0/13, 0/14, 0/15,
+  0, 1/1, 1/2, 1/3, 1/4, 1/5, 1/6, 1/7,
+    1/8, 1/9, 1/10, 1/11, 1/12, 1/13, 1/14, 1/15,
+  0, 2/1, 2/2, 2/3, 2/4, 2/5, 2/6, 2/7,
+    2/8, 2/9, 2/10, 2/11, 2/12, 2/13, 2/14, 2/15,
+  0, 3/1, 3/2, 3/3, 3/4, 3/5, 3/6, 3/7,
+    3/8, 3/9, 3/10, 3/11, 3/12, 3/13, 3/14, 3/15,
+  0, 4/1, 4/2, 4/3, 4/4, 4/5, 4/6, 4/7,
+    4/8, 4/9, 4/10, 4/11, 4/12, 4/13, 4/14, 4/15,
+  0, 5/1, 5/2, 5/3, 5/4, 5/5, 5/6, 5/7,
+    5/8, 5/9, 5/10, 5/11, 5/12, 5/13, 5/14, 5/15,
+  0, 6/1, 6/2, 6/3, 6/4, 6/5, 6/6, 6/7,
+    6/8, 6/9, 6/10, 6/11, 6/12, 6/13, 6/14, 6/15,
+  0, 7/1, 7/2, 7/3, 7/4, 7/5, 7/6, 7/7,
+    7/8, 7/9, 7/10, 7/11, 7/12, 7/13, 7/14, 7/15,
+  0, 8/1, 8/2, 8/3, 8/4, 8/5, 8/6, 8/7,
+    8/8, 8/9, 8/10, 8/11, 8/12, 8/13, 8/14, 8/15,
+  0, 9/1, 9/2, 9/3, 9/4, 9/5, 9/6, 9/7,
+    9/8, 9/9, 9/10, 9/11, 9/12, 9/13, 9/14, 9/15,
+  0, 10/1, 10/2, 10/3, 10/4, 10/5, 10/6, 10/7,
+    10/8, 10/9, 10/10, 10/11, 10/12, 10/13, 10/14, 10/15,
+  0, 11/1, 11/2, 11/3, 11/4, 11/5, 11/6, 11/7,
+    11/8, 11/9, 11/10, 11/11, 11/12, 11/13, 11/14, 11/15,
+  0, 12/1, 12/2, 12/3, 12/4, 12/5, 12/6, 12/7,
+    12/8, 12/9, 12/10, 12/11, 12/12, 12/13, 12/14, 12/15,
+  0, 13/1, 13/2, 13/3, 13/4, 13/5, 13/6, 13/7,
+    13/8, 13/9, 13/10, 13/11, 13/12, 13/13, 13/14, 13/15,
+  0, 14/1, 14/2, 14/3, 14/4, 14/5, 14/6, 14/7,
+    14/8, 14/9, 14/10, 14/11, 14/12, 14/13, 14/14, 14/15,
+  0, 15/1, 15/2, 15/3, 15/4, 15/5, 15/6, 15/7,
+    15/8, 15/9, 15/10, 15/11, 15/12, 15/13, 15/14, 15/15,
+};
+
diff --git a/libgcc/config/nios2/lib2-mul.c b/libgcc/config/nios2/lib2-mul.c
new file mode 100644
index 0000000..6fc4581
--- /dev/null
+++ b/libgcc/config/nios2/lib2-mul.c
@@ -0,0 +1,42 @@
+/* Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Altera and Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+#include "lib2-nios2.h"
+
+/* 32-bit SI multiply for Nios II.  */
+
+SItype
+__mulsi3 (SItype a, SItype b)
+{
+  SItype res = 0;
+  USItype cnt = a;
+  
+  while (cnt)
+    {
+      if (cnt & 1)
+	res += b;	  
+      b <<= 1;
+      cnt >>= 1;
+    }
+    
+  return res;
+}
diff --git a/libgcc/config/nios2/lib2-nios2.h b/libgcc/config/nios2/lib2-nios2.h
new file mode 100644
index 0000000..81bf37e
--- /dev/null
+++ b/libgcc/config/nios2/lib2-nios2.h
@@ -0,0 +1,49 @@
+/* Integer arithmetic support for Altera Nios II.
+   
+   Copyright (C) 2012 Free Software Foundation, Inc.
+   Contributed by Altera and Mentor Graphics, Inc.
+
+   This file is free software; you can redistribute it and/or modify it
+   under the terms of the GNU General Public License as published by the
+   Free Software Foundation; either version 3, or (at your option) any
+   later version.
+   
+   This file is distributed in the hope that it will be useful, but
+   WITHOUT ANY WARRANTY; without even the implied warranty of
+   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+   General Public License for more details.
+   
+   Under Section 7 of GPL version 3, you are granted additional
+   permissions described in the GCC Runtime Library Exception, version
+   3.1, as published by the Free Software Foundation.
+   
+   You should have received a copy of the GNU General Public License and
+   a copy of the GCC Runtime Library Exception along with this program;
+   see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+   <http://www.gnu.org/licenses/>. */
+
+#ifndef LIB2_NIOS2_H
+#define LIB2_NIOS2_H
+
+/* Types.  */
+
+typedef char QItype __attribute__ ((mode (QI)));
+typedef unsigned char UQItype __attribute__ ((mode (QI)));
+typedef short HItype __attribute__ ((mode (HI)));
+typedef unsigned short UHItype __attribute__ ((mode (HI)));
+typedef int SItype __attribute__ ((mode (SI)));
+typedef unsigned int USItype __attribute__ ((mode (SI)));
+typedef int word_type __attribute__ ((mode (__word__)));
+
+/* Exported functions.  */
+extern SItype __divsi3 (SItype, SItype);
+extern SItype __modsi3 (SItype, SItype);
+extern SItype __udivsi3 (SItype, SItype);
+extern SItype __umodsi3 (SItype, SItype);
+extern HItype __divhi3 (HItype, HItype);
+extern HItype __modhi3 (HItype, HItype);
+extern UHItype __udivhi3 (UHItype, UHItype);
+extern UHItype __umodhi3 (UHItype, UHItype);
+extern SItype __mulsi3 (SItype, SItype);
+
+#endif /* LIB2_NIOS2_H */
diff --git a/libgcc/config/nios2/linux-atomic.c b/libgcc/config/nios2/linux-atomic.c
new file mode 100644
index 0000000..c51c3f1
--- /dev/null
+++ b/libgcc/config/nios2/linux-atomic.c
@@ -0,0 +1,302 @@
+/* Linux-specific atomic operations for Nios II Linux.
+   Copyright (C) 2008, 2012 Free Software Foundation, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+#include <asm/unistd.h>
+#define EFAULT  14
+#define EBUSY   16
+#define ENOSYS  38
+
+/* We implement byte, short and int versions of each atomic operation
+   using the kernel helper defined below.  There is no support for
+   64-bit operations yet.  */
+
+/* Crash a userspace program with SIGSEV.  */
+#define ABORT_INSTRUCTION asm ("stw zero, 0(zero)")
+
+/* Kernel helper for compare-and-exchange a 32-bit value.  */
+static inline long
+__kernel_cmpxchg (int oldval, int newval, int *mem)
+{
+  register int r2 asm ("r2") = __NR_nios2cmpxchg;
+  register unsigned long lws_mem asm("r4") = (unsigned long) (mem);
+  register int lws_old asm("r5") = oldval;
+  register int lws_new asm("r6") = newval;
+  register int err asm ("r7");
+  asm volatile ("trap"
+		: "=r" (r2), "=r" (err)
+		: "r" (r2), "r" (lws_mem), "r" (lws_old), "r" (lws_new)
+		: "r1", "r3", "r8", "r9", "r10", "r11", "r12", "r13", "r14",
+		  "r15", "r29", "memory");
+
+  /* If the kernel LWS call succeeded (err == 0), r2 contains the old value
+     from memory.  If this value is equal to OLDVAL, the new value was written
+     to memory.  If not, return EBUSY.  */
+  if (__builtin_expect (err, 0))
+    {
+      if(__builtin_expect (r2 == EFAULT || r2 == ENOSYS,0))
+	ABORT_INSTRUCTION;
+    }
+  else
+    {
+      if (__builtin_expect (r2 != oldval, 0))
+	r2 = EBUSY;
+      else
+	r2 = 0;
+    }
+
+  return r2;
+}
+
+#define HIDDEN __attribute__ ((visibility ("hidden")))
+
+#ifdef nios2_little_endian
+#define INVERT_MASK_1 0
+#define INVERT_MASK_2 0
+#else
+#define INVERT_MASK_1 24
+#define INVERT_MASK_2 16
+#endif
+
+#define MASK_1 0xffu
+#define MASK_2 0xffffu
+
+#define FETCH_AND_OP_WORD(OP, PFX_OP, INF_OP)				\
+  int HIDDEN								\
+  __sync_fetch_and_##OP##_4 (int *ptr, int val)				\
+  {									\
+    int failure, tmp;							\
+									\
+    do {								\
+      tmp = *ptr;							\
+      failure = __kernel_cmpxchg (tmp, PFX_OP (tmp INF_OP val), ptr);	\
+    } while (failure != 0);						\
+									\
+    return tmp;								\
+  }
+
+FETCH_AND_OP_WORD (add,   , +)
+FETCH_AND_OP_WORD (sub,   , -)
+FETCH_AND_OP_WORD (or,    , |)
+FETCH_AND_OP_WORD (and,   , &)
+FETCH_AND_OP_WORD (xor,   , ^)
+FETCH_AND_OP_WORD (nand, ~, &)
+
+#define NAME_oldval(OP, WIDTH) __sync_fetch_and_##OP##_##WIDTH
+#define NAME_newval(OP, WIDTH) __sync_##OP##_and_fetch_##WIDTH
+
+/* Implement both __sync_<op>_and_fetch and __sync_fetch_and_<op> for
+   subword-sized quantities.  */
+
+#define SUBWORD_SYNC_OP(OP, PFX_OP, INF_OP, TYPE, WIDTH, RETURN)	\
+  TYPE HIDDEN								\
+  NAME##_##RETURN (OP, WIDTH) (TYPE *ptr, TYPE val)			\
+  {									\
+    int *wordptr = (int *) ((unsigned long) ptr & ~3);			\
+    unsigned int mask, shift, oldval, newval;				\
+    int failure;							\
+									\
+    shift = (((unsigned long) ptr & 3) << 3) ^ INVERT_MASK_##WIDTH;	\
+    mask = MASK_##WIDTH << shift;					\
+									\
+    do {								\
+      oldval = *wordptr;						\
+      newval = ((PFX_OP (((oldval & mask) >> shift)			\
+			 INF_OP (unsigned int) val)) << shift) & mask;	\
+      newval |= oldval & ~mask;						\
+      failure = __kernel_cmpxchg (oldval, newval, wordptr);		\
+    } while (failure != 0);						\
+									\
+    return (RETURN & mask) >> shift;					\
+  }
+
+SUBWORD_SYNC_OP (add,   , +, unsigned short, 2, oldval)
+SUBWORD_SYNC_OP (sub,   , -, unsigned short, 2, oldval)
+SUBWORD_SYNC_OP (or,    , |, unsigned short, 2, oldval)
+SUBWORD_SYNC_OP (and,   , &, unsigned short, 2, oldval)
+SUBWORD_SYNC_OP (xor,   , ^, unsigned short, 2, oldval)
+SUBWORD_SYNC_OP (nand, ~, &, unsigned short, 2, oldval)
+
+SUBWORD_SYNC_OP (add,   , +, unsigned char, 1, oldval)
+SUBWORD_SYNC_OP (sub,   , -, unsigned char, 1, oldval)
+SUBWORD_SYNC_OP (or,    , |, unsigned char, 1, oldval)
+SUBWORD_SYNC_OP (and,   , &, unsigned char, 1, oldval)
+SUBWORD_SYNC_OP (xor,   , ^, unsigned char, 1, oldval)
+SUBWORD_SYNC_OP (nand, ~, &, unsigned char, 1, oldval)
+
+#define OP_AND_FETCH_WORD(OP, PFX_OP, INF_OP)				\
+  int HIDDEN								\
+  __sync_##OP##_and_fetch_4 (int *ptr, int val)				\
+  {									\
+    int tmp, failure;							\
+									\
+    do {								\
+      tmp = *ptr;							\
+      failure = __kernel_cmpxchg (tmp, PFX_OP (tmp INF_OP val), ptr);	\
+    } while (failure != 0);						\
+									\
+    return PFX_OP (tmp INF_OP val);					\
+  }
+
+OP_AND_FETCH_WORD (add,   , +)
+OP_AND_FETCH_WORD (sub,   , -)
+OP_AND_FETCH_WORD (or,    , |)
+OP_AND_FETCH_WORD (and,   , &)
+OP_AND_FETCH_WORD (xor,   , ^)
+OP_AND_FETCH_WORD (nand, ~, &)
+
+SUBWORD_SYNC_OP (add,   , +, unsigned short, 2, newval)
+SUBWORD_SYNC_OP (sub,   , -, unsigned short, 2, newval)
+SUBWORD_SYNC_OP (or,    , |, unsigned short, 2, newval)
+SUBWORD_SYNC_OP (and,   , &, unsigned short, 2, newval)
+SUBWORD_SYNC_OP (xor,   , ^, unsigned short, 2, newval)
+SUBWORD_SYNC_OP (nand, ~, &, unsigned short, 2, newval)
+
+SUBWORD_SYNC_OP (add,   , +, unsigned char, 1, newval)
+SUBWORD_SYNC_OP (sub,   , -, unsigned char, 1, newval)
+SUBWORD_SYNC_OP (or,    , |, unsigned char, 1, newval)
+SUBWORD_SYNC_OP (and,   , &, unsigned char, 1, newval)
+SUBWORD_SYNC_OP (xor,   , ^, unsigned char, 1, newval)
+SUBWORD_SYNC_OP (nand, ~, &, unsigned char, 1, newval)
+
+int HIDDEN
+__sync_val_compare_and_swap_4 (int *ptr, int oldval, int newval)
+{
+  int actual_oldval, fail;
+    
+  while (1)
+    {
+      actual_oldval = *ptr;
+
+      if (oldval != actual_oldval)
+	return actual_oldval;
+
+      fail = __kernel_cmpxchg (actual_oldval, newval, ptr);
+  
+      if (!fail)
+	return oldval;
+    }
+}
+
+#define SUBWORD_VAL_CAS(TYPE, WIDTH)					\
+  TYPE HIDDEN								\
+  __sync_val_compare_and_swap_##WIDTH (TYPE *ptr, TYPE oldval,		\
+				       TYPE newval)			\
+  {									\
+    int *wordptr = (int *)((unsigned long) ptr & ~3), fail;		\
+    unsigned int mask, shift, actual_oldval, actual_newval;		\
+									\
+    shift = (((unsigned long) ptr & 3) << 3) ^ INVERT_MASK_##WIDTH;	\
+    mask = MASK_##WIDTH << shift;					\
+									\
+    while (1)								\
+      {									\
+	actual_oldval = *wordptr;					\
+									\
+	if (((actual_oldval & mask) >> shift) != (unsigned int) oldval)	\
+          return (actual_oldval & mask) >> shift;			\
+									\
+	actual_newval = (actual_oldval & ~mask)				\
+			| (((unsigned int) newval << shift) & mask);	\
+									\
+	fail = __kernel_cmpxchg (actual_oldval, actual_newval,		\
+				 wordptr);				\
+									\
+	if (!fail)							\
+	  return oldval;						\
+      }									\
+  }
+
+SUBWORD_VAL_CAS (unsigned short, 2)
+SUBWORD_VAL_CAS (unsigned char,  1)
+
+typedef unsigned char bool;
+
+bool HIDDEN
+__sync_bool_compare_and_swap_4 (int *ptr, int oldval, int newval)
+{
+  int failure = __kernel_cmpxchg (oldval, newval, ptr);
+  return (failure == 0);
+}
+
+#define SUBWORD_BOOL_CAS(TYPE, WIDTH)					\
+  bool HIDDEN								\
+  __sync_bool_compare_and_swap_##WIDTH (TYPE *ptr, TYPE oldval,		\
+					TYPE newval)			\
+  {									\
+    TYPE actual_oldval							\
+      = __sync_val_compare_and_swap_##WIDTH (ptr, oldval, newval);	\
+    return (oldval == actual_oldval);					\
+  }
+
+SUBWORD_BOOL_CAS (unsigned short, 2)
+SUBWORD_BOOL_CAS (unsigned char,  1)
+
+int HIDDEN
+__sync_lock_test_and_set_4 (int *ptr, int val)
+{
+  int failure, oldval;
+
+  do {
+    oldval = *ptr;
+    failure = __kernel_cmpxchg (oldval, val, ptr);
+  } while (failure != 0);
+
+  return oldval;
+}
+
+#define SUBWORD_TEST_AND_SET(TYPE, WIDTH)				\
+  TYPE HIDDEN								\
+  __sync_lock_test_and_set_##WIDTH (TYPE *ptr, TYPE val)		\
+  {									\
+    int failure;							\
+    unsigned int oldval, newval, shift, mask;				\
+    int *wordptr = (int *) ((unsigned long) ptr & ~3);			\
+									\
+    shift = (((unsigned long) ptr & 3) << 3) ^ INVERT_MASK_##WIDTH;	\
+    mask = MASK_##WIDTH << shift;					\
+									\
+    do {								\
+      oldval = *wordptr;						\
+      newval = (oldval & ~mask)						\
+	       | (((unsigned int) val << shift) & mask);		\
+      failure = __kernel_cmpxchg (oldval, newval, wordptr);		\
+    } while (failure != 0);						\
+									\
+    return (oldval & mask) >> shift;					\
+  }
+
+SUBWORD_TEST_AND_SET (unsigned short, 2)
+SUBWORD_TEST_AND_SET (unsigned char,  1)
+
+#define SYNC_LOCK_RELEASE(TYPE, WIDTH)					\
+  void HIDDEN								\
+  __sync_lock_release_##WIDTH (TYPE *ptr)				\
+  {									\
+    /* All writes before this point must be seen before we release	\
+       the lock itself.  */						\
+    __builtin_sync ();							\
+    *ptr = 0;								\
+  }
+
+SYNC_LOCK_RELEASE (int,   4)
+SYNC_LOCK_RELEASE (short, 2)
+SYNC_LOCK_RELEASE (char,  1)
diff --git a/libgcc/config/nios2/linux-unwind.h b/libgcc/config/nios2/linux-unwind.h
new file mode 100644
index 0000000..552854d
--- /dev/null
+++ b/libgcc/config/nios2/linux-unwind.h
@@ -0,0 +1,179 @@
+/* DWARF2 EH unwinding support for Nios II Linux.
+   Copyright (C) 2008, 2012 Free Software Foundation, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+#ifndef inhibit_libc
+
+/* Do code reading to identify a signal frame, and set the frame
+   state data appropriately.  See unwind-dw2.c for the structs.
+   The corresponding bits in the Linux kernel are in
+   arch/nios2/kernel/signal.c.  */
+
+#include <signal.h>
+#include <asm/unistd.h>
+
+/* Exactly the same layout as the kernel structures, unique names.  */
+struct nios2_mcontext {
+  int version;
+#ifdef __uClinux__
+  int status_extension;
+#endif
+  int gregs[32];
+};
+
+struct nios2_ucontext {
+  unsigned long uc_flags;
+  struct ucontext *uc_link;
+  stack_t uc_stack;
+  struct nios2_mcontext uc_mcontext;
+  sigset_t uc_sigmask;	/* mask last for extensibility */
+};
+
+#define MD_FALLBACK_FRAME_STATE_FOR nios2_fallback_frame_state
+
+static _Unwind_Reason_Code
+nios2_fallback_frame_state (struct _Unwind_Context *context,
+			    _Unwind_FrameState *fs)
+{
+  u_int32_t *pc = (u_int32_t *) context->ra;
+  _Unwind_Ptr new_cfa;
+
+  /* The expected sequence of instructions for regular Linux is:
+       movi r2,(sigreturn/rt_sigreturn)
+       trap
+     On uClinux, we expect:
+       movi r3,(sigreturn/rt_sigreturn)
+       mov r2, r0
+       trap
+     Check for the trap first.  */
+  if (1
+#ifndef __uClinux__
+      && pc[1] != 0x003b683a
+#else
+      && pc[2] != 0x003b683a
+#endif
+      )
+    return _URC_END_OF_STACK;
+
+#define NIOS2_REG(NUM,NAME)						\
+  (fs->regs.reg[NUM].how = REG_SAVED_OFFSET,				\
+   fs->regs.reg[NUM].loc.offset = (_Unwind_Ptr)&(regs->NAME) - new_cfa)
+  
+  if (1
+#ifndef __uClinux__
+      && pc[0] == (0x00800004 | (__NR_sigreturn << 6))
+#else
+      && pc[0] == (0x00c00004 | (__NR_sigreturn << 6))
+      && pc[1] == 0x0005883a
+#endif
+      )
+    {
+      struct sigframe {
+	char retcode[12];
+	unsigned long extramask[1];
+	struct sigcontext sc;
+      } *rt_ = context->ra;
+      struct pt_regs *regs = &rt_->sc.regs;
+
+      /* The CFA is the user's incoming stack pointer value.  */
+      new_cfa = (_Unwind_Ptr)(regs->sp);
+      fs->regs.cfa_how = CFA_REG_OFFSET;
+      fs->regs.cfa_reg = STACK_POINTER_REGNUM;
+      fs->regs.cfa_offset = new_cfa - (_Unwind_Ptr) context->cfa;
+
+      /* Regs 1..15.  */
+      NIOS2_REG (1, r1);
+      NIOS2_REG (2, r2);
+      NIOS2_REG (3, r3);
+      NIOS2_REG (4, r4);
+      NIOS2_REG (5, r5);
+      NIOS2_REG (6, r6);
+      NIOS2_REG (7, r7);
+      NIOS2_REG (8, r8);
+      NIOS2_REG (9, r9);
+      NIOS2_REG (10, r10);
+      NIOS2_REG (11, r11);
+      NIOS2_REG (12, r12);
+      NIOS2_REG (13, r13);
+      NIOS2_REG (14, r14);
+      NIOS2_REG (15, r15);
+
+      /* Regs 16..23 are not saved here.  They are callee saved or
+	 special.  */
+      
+      /* The random registers.  */
+      NIOS2_REG (RA_REGNO, ra);
+      NIOS2_REG (FP_REGNO, fp);
+      NIOS2_REG (GP_REGNO, gp);
+      NIOS2_REG (EA_REGNO, ea);
+      
+      fs->retaddr_column = EA_REGNO;
+      fs->signal_frame = 1;
+      
+      return _URC_NO_REASON;
+    }
+  else if (1
+#ifndef __uClinux__
+	   && pc[0] == (0x00800004 | (__NR_rt_sigreturn << 6))
+#else
+	   && pc[0] == (0x00c00004 | (__NR_rt_sigreturn << 6))
+	   && pc[1] == 0x0005883a
+#endif
+	   )
+    {
+      struct rt_sigframe {
+	char retcode[12];
+	siginfo_t info;
+	struct nios2_ucontext uc;
+      } *rt_ = context->ra;
+      struct nios2_mcontext *regs = &rt_->uc.uc_mcontext;
+      int i;
+
+      /* MCONTEXT_VERSION is defined to 2 in the kernel.  */
+      if (regs->version != 2)
+	return _URC_END_OF_STACK;
+
+      /* The CFA is the user's incoming stack pointer value.  */
+      new_cfa = (_Unwind_Ptr)regs->gregs[28];
+      fs->regs.cfa_how = CFA_REG_OFFSET;
+      fs->regs.cfa_reg = STACK_POINTER_REGNUM;
+      fs->regs.cfa_offset = new_cfa - (_Unwind_Ptr) context->cfa;
+
+      /* The sequential registers.  */
+      for (i = 1; i < 24; i++)
+	NIOS2_REG (i, gregs[i-1]);
+      
+      /* The random registers.  The kernel stores these in a funny order
+	 in the gregs array.  */
+      NIOS2_REG (RA_REGNO, gregs[23]);
+      NIOS2_REG (FP_REGNO, gregs[24]);
+      NIOS2_REG (GP_REGNO, gregs[25]);
+      NIOS2_REG (EA_REGNO, gregs[27]);
+      
+      fs->retaddr_column = EA_REGNO;
+      fs->signal_frame = 1;
+      
+      return _URC_NO_REASON;
+    }
+#undef NIOS2_REG
+  return _URC_END_OF_STACK;
+}
+#endif
diff --git a/libgcc/config/nios2/t-linux b/libgcc/config/nios2/t-linux
new file mode 100644
index 0000000..1fa581e
--- /dev/null
+++ b/libgcc/config/nios2/t-linux
@@ -0,0 +1,7 @@
+# Soft-float functions go in glibc only, to facilitate the possible
+# future addition of exception and rounding mode support integrated
+# with <fenv.h>.
+
+LIB2FUNCS_EXCLUDE = _floatdidf _floatdisf _fixunsdfsi _fixunssfsi \
+  _fixunsdfdi _fixdfdi _fixunssfdi _fixsfdi _floatundidf _floatundisf
+LIB2ADD += $(srcdir)/config/nios2/linux-atomic.c
diff --git a/libgcc/config/nios2/t-nios2 b/libgcc/config/nios2/t-nios2
new file mode 100644
index 0000000..1dd2116
--- /dev/null
+++ b/libgcc/config/nios2/t-nios2
@@ -0,0 +1,18 @@
+LIB2ADD += $(srcdir)/config/nios2/lib2-divmod.c \
+	   $(srcdir)/config/nios2/lib2-divmod-hi.c \
+	   $(srcdir)/config/nios2/lib2-divtable.c \
+	   $(srcdir)/config/nios2/lib2-mul.c \
+	   $(srcdir)/config/nios2/tramp.c
+
+# We have some non *.S named assembly files
+CUSTOM_CRTIN = yes
+
+# Assemble startup files. 
+$(T)crti.o: $(srcdir)/config/nios2/crti.asm $(GCC_PASSES) 
+	$(GCC_FOR_TARGET) $(GCC_CFLAGS) $(MULTILIB_CFLAGS) $(INCLUDES) \
+	-c -o $(T)crti.o -x assembler-with-cpp $(srcdir)/config/nios2/crti.asm 
+
+$(T)crtn.o: $(srcdir)/config/nios2/crtn.asm $(GCC_PASSES) 
+	$(GCC_FOR_TARGET) $(GCC_CFLAGS) $(MULTILIB_CFLAGS) $(INCLUDES) \
+	-c -o $(T)crtn.o -x assembler-with-cpp $(srcdir)/config/nios2/crtn.asm 
+
diff --git a/libgcc/config/nios2/tramp.c b/libgcc/config/nios2/tramp.c
new file mode 100644
index 0000000..0c2b590
--- /dev/null
+++ b/libgcc/config/nios2/tramp.c
@@ -0,0 +1,62 @@
+/* Copyright (C) 2013 Free Software Foundation, Inc.
+   Contributed by Altera and Mentor Graphics, Inc.
+
+This file is free software; you can redistribute it and/or modify it
+under the terms of the GNU General Public License as published by the
+Free Software Foundation; either version 3, or (at your option) any
+later version.
+
+This file is distributed in the hope that it will be useful, but
+WITHOUT ANY WARRANTY; without even the implied warranty of
+MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+General Public License for more details.
+
+Under Section 7 of GPL version 3, you are granted additional
+permissions described in the GCC Runtime Library Exception, version
+3.1, as published by the Free Software Foundation.
+
+You should have received a copy of the GNU General Public License and
+a copy of the GCC Runtime Library Exception along with this program;
+see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
+<http://www.gnu.org/licenses/>.  */
+
+/* Set up trampolines.
+   R12 is the static chain register.
+   R2 is AT, the assembler temporary.
+   The trampoline code looks like:
+	movhi	r12,%hi(chain)
+	ori	r12,%lo(chain)
+	movhi	r2,%hi(fn)
+	ori	r2,%lo(fn)
+	jmp	r2
+*/
+
+#define SC_REGNO 12
+
+#define MOVHI(reg,imm16) \
+  (((reg) << 22) | ((imm16) << 6) | 0x34)
+#define ORI(reg,imm16) \
+  (((reg) << 27) | ((reg) << 22) | ((imm16) << 6) | 0x14)
+#define JMP(reg) \
+  (((reg) << 27) | (0x0d << 11) | 0x3a)
+	
+void __trampoline_setup (unsigned int *addr,
+			 void *fnptr,
+			 void *chainptr)
+{
+  unsigned int fn = (unsigned int)fnptr;
+  unsigned int chain = (unsigned int)chainptr;
+  int i;
+
+  addr[0] = MOVHI (SC_REGNO, ((chain >> 16) & 0xffff));
+  addr[1] = ORI (SC_REGNO, (chain & 0xffff));
+  addr[2] = MOVHI (2, ((fn >> 16) & 0xffff));
+  addr[3] = ORI (2, (fn & 0xffff));
+  addr[4] = JMP (2);
+
+  /* Flush the caches.
+     See Example 9-4 in the Nios II Software Developer's Handbook.  */
+  for (i = 0; i < 5; i++)
+    asm volatile ("flushd 0(%0); flushi %0" :: "r"(addr + i) : "memory");
+  asm volatile ("flushp" ::: "memory");
+}

