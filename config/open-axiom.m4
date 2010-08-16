AC_DEFUN([OPENAXIOM_MAKEFILE],
[AC_CONFIG_FILES([$1:config/var-def.mk:$1.in:config/setup-dep.mk])])

dnl --------------------------------------
dnl -- OPENAXIOM_STANDARD_INTEGER_TYPES --
dnl --------------------------------------
dnl Check for availability of standard sized integer types.
AC_DEFUN([OPENAXIOM_STANDARD_INTEGER_TYPES], [
AC_TYPE_INT8_T
AC_TYPE_UINT8_T
AC_TYPE_INT16_T
AC_TYPE_UINT16_T
AC_TYPE_INT32_T
AC_TYPE_UINT32_T
AC_TYPE_INT64_T
AC_TYPE_UINT64_T
AC_TYPE_INTPTR_T
AC_TYPE_UINTPTR_T
])


dnl ----------------------------------
dnl -- OPENAXIOM_REJECT_ROTTED_LISP --
dnl ----------------------------------
dnl Check for Lisp systems we know are just too buggy for use.
AC_DEFUN([OPENAXIOM_REJECT_ROTTED_LISP],[
if test x"$oa_include_gcl" != xyes; then
   case $AXIOM_LISP in
      *gcl*)
	 AC_MSG_CHECKING([$AXIOM_LISP version])
	 v=`$AXIOM_LISP -batch -eval "(format t \"~S\" (lisp-implementation-version))"`
	 AC_MSG_RESULT([$v])
	 case $v in
	   *2.6.7*|*2.6.8*) ;;         # OK
	   *)
	     AC_MSG_WARN([$v is not supported by this version of OpenAxiom.  $AXIOM_LISP will be ignored.])
	     AXIOM_LISP=
	     ;;
	 esac
	 ;;
      # SBCL-1.0.29 has a nasty regression that prevents OpenAxiom build
      *sbcl*)
	 AC_MSG_CHECKING([$AXIOM_LISP version])
	 v=`$AXIOM_LISP --version`
	 AC_MSG_RESULT([$v])
	 case $v in
	   *1.0.29)
	      AC_MSG_ERROR([This version of SBCL has a bug that breaks OpenAxiom build.  Consider SBCL-1.0.30 or higher.])
	      ;;
	 esac
	 ;;
   esac
fi
])

dnl -------------------------
dnl -- OPENAXIOM_PROG_LISP --
dnl -------------------------
dnl Find the host Lisp compiler to use
AC_DEFUN([OPENAXIOM_PROG_LISP],[
## Was a host Lisp system specified?
oa_user_lisp=
AC_ARG_WITH([lisp], [ --with-lisp=L         use L as Lisp platform],
              [oa_user_lisp=$withval])

## For all values of L, except gcl, the assumption is that the Lisp
## image L is available in the build environment.  For  gcl,
## we make an exception: if no GCL image is available, or if
## the option --enable-gcl is specified then OpenAxiom builds its 
## own version from the source tree.
## If --enable-gcl is specified, we need to check for coonsistency
AC_SUBST(oa_include_gcl)
oa_include_gcl=
AC_ARG_ENABLE([gcl], [  --enable-gcl            build GCL from OpenAxiom source],
	      [case $enableval in
		   yes|no) oa_include_gcl=$enableval ;;
		   *) AC_MSG_ERROR([erroneous value for --enable-gcl]) ;;
	       esac])

## If nothing was said about preferred Lisp, guess one.
AC_SUBST(AXIOM_LISP)
if test -n $oa_user_lisp; then
    ## Honor use of Lisp image specified on command line
    AXIOM_LISP=$oa_user_lisp
elif test -z $oa_include_gcl; then
    AC_CHECK_PROGS([AXIOM_LISP], [sbcl gcl ecl clisp ccl64 ccl32 ccl])
fi
])

dnl -----------------------------------
dnl -- OPENAXIOM_CHECK_GCL_INCLUSION --
dnl -----------------------------------
dnl Check for consistency of configure options when GCL is requested.
AC_DEFUN([OPENAXIOM_CHECK_GCL_INCLUSION],[
case $oa_include_gcl,$AXIOM_LISP in
    no,)
       ## It doesn't make sense not to include GCL when no Lisp image
       ## is available.  Give up.
       AC_MSG_ERROR([--disable-gcl specified but no Lisp system found])
       ;;

    ,|yes,)
       ## No Lisp image was specified and none was available from
       ## the build environment; build GCL from OpenAxiom source.
       ## User may explicilty specify --enable-gcl, but may be missing
       ## the dependency tarball.
       if test -d ${srcdir}/gcl; then
	  AXIOM_LISP='$(axiom_build_bindir)/gcl'
	  oa_all_prerequisites="$oa_all_prerequisites all-gcl"
	  oa_include_gcl=yes
       elif test -z $oa_include_gcl; then
	  AC_MSG_ERROR([OpenAxiom requires a Lisp system.  Either separately build one (GCL-2.6.7, GCL-2.6.8, SBCL, ECL, CLisp, Clozure CL), or get the dependency tarball from OpenAxiom download website.])
       else
          AC_MSG_ERROR([The OpenAxiom dependency tarball is missing; please get it from our website.])
       fi
       ;;
    yes,*)
       AC_MSG_ERROR([--with-lisp=$AXIOM_LISP conflicts with --enable-gcl])
       ;;
esac
])

dnl ---------------------------
dnl -- OPENAXIOM_LISP_FLAVOR --
dnl ---------------------------
dnl Determine the flavor of the host Lisp system.
AC_DEFUN([OPENAXIOM_LISP_FLAVOR],[
OPENAXIOM_CHECK_GCL_INCLUSION

axiom_lisp_flavor=unknown
AC_SUBST(axiom_lisp_flavor)
 
## Most Lisp systems don't use conventional methods for building programs.
oa_standard_linking=no
AC_SUBST(oa_standard_linking)

## The pipe below is OK, for as of this writting, the free Lisp systems
##  ECL, GCL, SBCL, CLisp, and Clozure CL all exit at end of standard input.
AC_MSG_CHECKING([which flavor of Lisp])
if test x"$oa_include_gcl" = xyes; then
   axiom_lisp_flavor=gcl
else
   case `echo '(lisp-implementation-type)' | $AXIOM_LISP` in
       *GCL*) 
	   axiom_lisp_flavor=gcl
	   ;;
       *"ECL"*) 
	   axiom_lisp_flavor=ecl 
	   oa_standard_linking=yes
	   ;;
       *"SBCL"*) 
	   axiom_lisp_flavor=sbcl 
	   ;;
       *"CLISP"*)
	   ## Not all variants of CLisp have FFI support.  FFI is used
	   ## internally used by OpenAxiom in essential way.
	   if ! $AXIOM_LISP -q -x '*features*' | grep ':FFI' > /dev/null
	   then
	     AC_MSG_ERROR([$AXIOM_LISP does not support Foreign Function Interface.  Please upgrade to a better version of CLisp or install SBCL.])
	   fi
	   axiom_lisp_flavor=clisp
	   ;;
       *"Armed Bear Common Lisp"*) 
	   axiom_lisp_flavor=abcl 
	   ;;
       *"Clozure Common Lisp"*)
	   axiom_lisp_flavor=clozure
	   ;;
   esac
fi
AC_MSG_RESULT([$axiom_lisp_flavor])

AC_DEFINE_UNQUOTED([OPENAXIOM_BASE_RTS],
                   [openaxiom_${axiom_lisp_flavor}_runtime],
                   [The kind of base runtime system for this build.])
])

dnl ------------------------------
dnl -- OPENAXIOM_HOST_COMPILERS --
dnl ------------------------------
dnl Check for the host C, C++, and Lisp compilers
AC_DEFUN([OPENAXIOM_HOST_COMPILERS],[
OPENAXIOM_PROG_LISP
OPENAXIOM_LISP_FLAVOR
OPENAXIOM_REJECT_ROTTED_LISP
OPENAXIOM_HOST_LISP_CPU_PRECISION
AC_PROG_CC
AC_PROG_CXX
## Augment C and C++ compiler flags with ABI directives as appropriate
## before we proceed to infer other host datatype properties.
if test -n "$openaxiom_host_lisp_precision"; then
   case $GCC in
     yes)
       CPPFLAGS="$CPPFLAGS -m$openaxiom_host_lisp_precision"
       LDFLAGS="$LDFLAGS -m$openaxiom_host_lisp_precision"
       ;;
     no)
       # cross fingers and pray.
       ;;
   esac
fi
OPENAXIOM_SATISFY_GCL_NEEDS
AC_PROG_CPP
])

dnl -------------------------
dnl -- OPENAXIOM_GCL_HACKS --
dnl -------------------------
dnl Some auxiliary programs generated by GCL need to be at the
dnl right place when compiling under mingw32.
AC_DEFUN([OPENAXIOM_GCL_HACKS],[
## The following is a horrible hack to arrange for GCL to successfully
## rebuild symbol tables with "rsym" on Windows platform.  It should
## go away as soon as GCL upstream is fixed.
AC_SUBST(axiom_gcl_rsym_hack)
case $axiom_lisp_flavor,$target in
    gcl,*mingw*)
        axiom_gcl_rsym_hack='d=`echo "(format nil \"~a\" si::*system-directory*)" | $(AXIOM_LISP) | grep "/gcl.*/" | sed -e "s,\",,g"`; cp $$d/rsym$(EXEEXT) .'
	;;
    *) 
        ## Breath.
        axiom_gcl_rsym_hack=':'
	;;
esac
])

dnl ---------------------------------
dnl -- OPENAXIOM_SATISFY_GCL_NEEDS --
dnl ---------------------------------
dnl GCL assumes that the C compiler is from GNU.
AC_DEFUN([OPENAXIOM_SATISFY_GCL_NEEDS],[
## If we are using GCL as the base runtime system, then we do really need
# a C compiler from GNU.  Well, at least for the moment.
case $axiom_lisp_flavor,$GCC in
   gcl,yes)
       axiom_cflags="-O2 -Wall -D_GNU_SOURCE"
       ;;
   
   gcl,*)
       AC_MSG_ERROR([We need a GNU C compiler])
       ;;
esac
AC_SUBST(axiom_cflags)
])

dnl --------------------------
dnl -- OPENAXIOM_LISP_FLAGS --
dnl --------------------------
dnl Determine how to invoke the host Lisp systemin batch mode.
dnl We also take the opportunity to determine whether we can use
dnl dynamically loaded modules.
AC_DEFUN([OPENAXIOM_LISP_FLAGS],[
AC_SUBST(axiom_quiet_flags)
AC_SUBST(axiom_eval_flags)

## Can we use dynamically linked libraries?  
## Tentatively answer `yes' -- this is modern time.
oa_use_dynamic_lib=yes
AC_SUBST(oa_use_dynamic_lib)

## How are we supposed to tell the Lisp system to eval an expression
## in batch mode?  What is the extension of a compiled Lisp file?
case $axiom_lisp_flavor in
    gcl) 
       axiom_quiet_flags='-batch'
       axiom_eval_flags='-eval'
       oa_use_dynamic_lib=no  
       ;;
    ecl) 
       axiom_quiet_flags=
       axiom_eval_flags='-norc -eval'
       oa_use_dynamic_lib=no  
       ;;
    sbcl) 
       axiom_quiet_flags='--noinform --noprint'
       axiom_eval_flags='--eval'
       ;;
    clisp) 
       axiom_quiet_flags='--quiet'
       axiom_eval_flags='-norc -x'
       ;;
    clozure)
       axiom_quiet_flags='--quiet --no-init'
       axiom_eval_flags='--eval'
       ;;
    *) AC_MSG_ERROR([We do not know how to build OpenAxiom this $AXIOM_LISP]) ;;
esac
])


dnl -------------------------------
dnl -- OPENAXIOM_FILE_EXTENSIONS --
dnl -------------------------------
dnl Compute various file extensions used by the build system.
AC_DEFUN([OPENAXIOM_FILE_EXTENSIONS],[
AC_SUBST(axiom_fasl_type)
AC_MSG_CHECKING([compiled Lisp file extension])
if test x"$oa_include_gcl" = xyes; then
   axiom_fasl_type=o
else
   ## We set the IFS to <space> as we don't want automatic
   ## replacement of <newline> by <space>.
   openaxiom_save_IFS=$IFS
   IFS=' '
   axiom_fasl_type=`$AXIOM_LISP $axiom_quiet_flags $axiom_eval_flags '(progn (format t "axiom_fasl_type=~a" (pathname-type (compile-file-pathname "foo.lisp"))) (quit))'`

   ## Now pull out the fasl type.  ECL has the habit of spitting noise
   ## about internal loading.  Therefore, we must look only for a line that
   ## begins with axiom_fasl_type.
   axiom_fasl_type=`echo $axiom_fasl_type | grep '^axiom_fasl_type'`
   IFS=$openaxiom_save_IFS
   axiom_fasl_type=`echo $axiom_fasl_type | sed -e 's/axiom_fasl_type=//'`
   if test -z $axiom_fasl_type; then
       AC_MSG_ERROR([Could not determine extension for compiled Lisp files])
   fi
fi
AC_MSG_RESULT([$axiom_fasl_type])

## What is the extension of object and executable files on this platform?
AC_OBJEXT
AC_DEFINE_UNQUOTED([OPENAXIOM_EXEEXT], ["$ac_cv_exeext"], 
                   [Extension of executable file.])
])

dnl ------------------------------
dnl -- OPENAXIOM_FFI_TYPE_TABLE --
dnl ------------------------------
dnl Build FFI type translation table used by
dnl the Boot translator and the Spad compiler
AC_DEFUN([OPENAXIOM_FFI_TYPE_TABLE],[
AC_SUBST(void_type)
AC_SUBST(char_type)
AC_SUBST(int_type)
AC_SUBST(float_type)
AC_SUBST(double_type)
AC_SUBST(string_type)

case $axiom_lisp_flavor in
   gcl)
      void_type='void'
      char_type='char'
      int_type='int'
      float_type='float'
      double_type='double'
      string_type='string'
      ;;
   sbcl)
      void_type='void'
      char_type='char'
      int_type='int'
      float_type='float'
      double_type='double'
      string_type='c-string'
      ;;
   clisp)
      void_type='nil'
      char_type='character'
      int_type='int'
      float_type='single-float'
      double_type='double-float'
      string_type='c-string'
      ;;
   ecl)
      void_type=':void'
      char_type=':char'
      int_type=':int'
      float_type=':float'
      double_type=':double'
      string_type=':cstring'
      ;;
   clozure)
      void_type=':void'
      # FIXME: this is not really what we want, but good enough for now.
      char_type=':unsigned-byte'
      int_type=':signed-fullword'
      float_type=':single-float'
      double_type=':double-float'
      # Clozure CL wants you to deal with your own mess
      string_type=':address'
      ;;
   *)
      AC_MSG_ERROR([We do not know how to translate native types for this Lisp])
      ;;
esac
])


dnl ---------------------------------------
dnl -- OPENAXIOM_HOST_LISP_CPU_PRECISION --
dnl ---------------------------------------
dnl Determine the register precision as seen by the host Lisp system, and
dnl set the global variable openaxiom_host_lisp_precision.
AC_DEFUN([OPENAXIOM_HOST_LISP_CPU_PRECISION], [
if test x"$oa_include_gcl" != xyes; then
   AC_MSG_CHECKING([CPU precision as seen by $AXIOM_LISP])
   case `echo '*features*' | $AXIOM_LISP` in
     *X86-64*|*X86_64*|*WORD-SIZE=64*|*64-BIT-HOST*)
	# PORTME: the pattern above covers only the supported free Lisps, i.e.
	# GCL, SBCL, CLisp, ECL and Clozure CL.
	openaxiom_host_lisp_precision=64
	;;
     *)
	# assume everything else is 32-bit
	# FIXME: this is bold assumption.
	openaxiom_host_lisp_precision=32
	;;
   esac
   AC_MSG_RESULT([$openaxiom_host_lisp_precision])
fi
])


dnl ------------------------------------
dnl -- OPENAXIOM_HOST_DATA_PROPERTIES --
dnl ------------------------------------
AC_DEFUN([OPENAXIOM_HOST_DATA_PROPERTIES],[
## Byte order of the host.
AC_C_BIGENDIAN
AC_CHECK_HEADERS([stdint.h inttypes.h])
OPENAXIOM_STANDARD_INTEGER_TYPES
AC_CHECK_SIZEOF([void*])
if test x"$oa_include_gcl" = xyes; then
   ## PORTME: does GCL really care about system where CHAR_BITS is not 8?
   openaxiom_host_lisp_precision=`expr "$ac_cv_sizeof_voidp * 8"`
fi

## Now that we have full knowledge of the host Lisp to use, tell
## the rest of the runtime about the host natural integer precision.
AC_DEFINE_UNQUOTED([OPENAXIOM_HOST_LISP_PRECISION],
                   [$openaxiom_host_lisp_precision],
                   [The width of the host Lisp and CPU registers.])
])

dnl --------------------------------------
dnl -- OPENAXIOM_DYNAMIC_MODULE_SUPPORT --
dnl --------------------------------------
dnl Infer compiler flags and file extensions associated
dnl with dynamic module support.
dnl We need to link some C object files into in the Lisp images we
dnl use.  Some Lisps (e.g. GCL, ECL) support inclusion of ``ordinary''
dnl object files.  Other Lisps (e.g. SBCL, Clozure CL) support only dynamic
dnl or shared libraries.  However, the exact minutia of  portably
dnl building shared libraries are known to be fraught with all kinds
dnl of traps.  Consequently, we sought to use dedicated tools such
dnl Libtool.  Unfortunately, Libtool has been steadily improved over the years
dnl to become nearly useless when mixed with non-libtool components.
AC_DEFUN([OPENAXIOM_DYNAMIC_MODULE_SUPPORT],[
AC_SUBST(oa_use_libtool_for_shared_lib)
AC_SUBST(oa_shrobj_flags)
AC_SUBST(oa_shrlib_flags)
oa_use_libtool_for_shared_lib=no
oa_shrobj_flags=
oa_shrlib_flags=
## Tell Libtool to assume `dlopen' so that it does not have to
## emulate it.
LT_INIT([pic-only dlopen win32-dll shared])
AC_SUBST([LIBTOOL_DEPS])
# Give me extension of libraries
AC_SUBST(shared_ext)
AC_SUBST(libext)
module=yes
eval shared_ext=\"$shrext_cmds\"
case $host in
    *mingw*|*cygwin*)
       oa_shrobj_flags='-prefer-pic'
       oa_shrlib_flags="-shared --export-all-symbols"
       ;;
    *darwin*)
       oa_shrobj_flags='-dynamic'
       oa_shrlib_flags='-bundle -undefined suppress -flat_namespace'
       ;;
    *)
       oa_shrobj_flags='-prefer-pic'
       oa_shrlib_flags='-shared'
       ;;
esac
])


dnl ---------------------------
dnl -- OPENAXIOM_BUILD_TOOLS --
dnl ---------------------------
dnl Check for utilities we need for building the system.
AC_DEFUN([OPENAXIOM_BUILD_TOOLS],[
AC_CHECK_PROG([TOUCH], [touch],
              [touch], [AC_MSG_ERROR(['touch' program is missing.])])
AC_PROG_INSTALL
AC_CHECK_PROGS([MKTEMP], [mktemp])
AC_PROG_AWK

## Find GNU Make
case $build in
    *linux*)
	# GNU/Linux systems come equipped with GNU Make, called `make'
        AC_CHECK_PROGS([MAKE], [make],
                       [AC_MSG_ERROR([Make utility missing.])])
	;;
    *)
        # Other systems tend to spell it `gmake' and such
        AC_CHECK_PROGS([MAKE], [gmake make],
                       [AC_MSG_ERROR([Make utility missing.])])
	if ! $MAKE --version | grep 'GNU' 2>/dev/null; then
	    AC_MSG_ERROR([OpenAxiom build system needs GNU Make.])
	fi
	;;
esac

## Make sure noweb executable is available
AC_CHECK_PROGS([NOTANGLE], [notangle])
AC_CHECK_PROGS([NOWEAVE], [noweave])
## In case noweb is missing we need to build our own.
if test -z $NOTANGLE -o -z $NOWEAVE ; then
    ## Yes, but do we have the source files to build from?
    if test ! -d ${srcdir}/noweb; then
       AC_MSG_NOTICE([OpenAxiom requires noweb utilties])
       AC_MSG_ERROR([Please get the tarball of dependencies and reconfigure])
    fi
    NOTANGLE='$(axiom_build_bindir)/notangle'
    NOWEAVE='$(axiom_build_bindir)/noweave'
    oa_all_prerequisites="$oa_all_prerequisites all-noweb"
fi
])

dnl ---------------------------
dnl -- OPENAXIOM_HOST_EDITOR --
dnl ---------------------------
dnl Check for a text editor for use when
dnl the system is up and running.
AC_DEFUN([OPENAXIOM_HOST_EDITOR],[
AC_SUBST(oa_editor)
## On Windows system, we prefer the default installation
## location to be 'C:/Program Files/OpenAxiom', following Windows 
## convention.  We cannot use AC_PREFIX_DEFAULT directly as it seems 
## to operate unconditionally.  Therefore, we resort to this dirty
## trick stepping over Autoconf's internals.
case $host in
    *mingw*)
        ac_default_prefix="C:/Program Files/OpenAxiom"
        AC_PATH_PROGS([oa_editor],[notepad.exe])
	;;
    *)  
        AC_PATH_PROGS([oa_editor],[vi])
        ;;
esac
])

dnl --------------------------
dnl -- OPENAXIOM_HOST_PROGS --
dnl --------------------------
dnl Check for programs we need in the host environment.
AC_DEFUN([OPENAXIOM_HOST_PROGS],[
OPENAXIOM_HOST_EDITOR
AC_PATH_PROGS([HOST_AWK],[awk nawk gawk mawk])

AC_PATH_PROG([PDFLATEX], [pdflatex])
if test -z "$PDFLATEX"; then
   AC_PATH_PROG([LATEX], [latex],
                [AC_MSG_NOTICE([Documentation is disabled.])])
fi
AC_CHECK_PROGS([MAKEINDEX], [makeindex])
])


dnl -----------------------------
dnl -- OPENAXIOM_BUILD_OPTIONS --
dnl -----------------------------
dnl Process build options specified on the command line.
AC_DEFUN([OPENAXIOM_BUILD_OPTIONS],[
## Does it make sense to pretend that we support multithreading?
oa_enable_threads=no
AC_ARG_ENABLE([threads], [  --enable-threads   turn on threads support],
              [case $enableval in
                  yes|no) oa_enable_threads=$enableval ;;
                  *) AC_MSG_ERROR([erroneous value for --enable-threads]) ;;
               esac])
# GNU compilers want hints about multithreading.
case $GCC,$oa_enable_threads in
   yes,yes)
     axiom_cflags="$axiom_cflags -pthread"
esac
AC_SUBST(oa_enable_threads)

## Occaionally, we may want to keep intermediary files.
oa_keep_files=
AC_ARG_ENABLE([int-file-retention], 
              [  --enable-int-file-retention   keep intermediary files],
              [case $enableval in
                  yes|no) oa_keep_files=$enableval ;;
                  *) AC_MSG_ERROR([erroneous value for --enable-int-file-retention]) ;;
               esac])
AC_SUBST(oa_keep_files)

## Parse args for profiling-enabled build.
oa_enable_profiling=no
AC_ARG_ENABLE([profiling], [  --enable-profiling  turn profiling on],
              [case $enableval in
                  yes|no) oa_enable_profiling=$enableval ;;
                  *) AC_MSG_ERROR([erroneous value for --enable-profiling]) ;;
               esac])
AC_SUBST(oa_enable_profiling)

## Lisp optimization settings
oa_optimize_options=speed
## Shall we proclaim safety?
oa_enable_checking=no          # don't turn on checking by default.
AC_ARG_ENABLE([checking], [  --enable-checking  turn runtime checking on],
              [case $enableval in
                  yes|no) oa_enable_checking=$enableval ;;
                  *) AC_MSG_ERROR([erroneous value for --enable-checking]) ;;
               esac])
if test x"$oa_enable_checking" = xyes; then
   case $axiom_lisp_flavor in
     gcl) # GCL-2.6.x does not understand debug.
        oa_optimize_options="$oa_optimize_options safety" 
        ;;
     *) oa_optimize_options="$oa_optimize_options safety debug" 
        ;;
   esac
   AC_MSG_NOTICE([runtime checking may increase compilation time])
fi
AC_SUBST(oa_enable_checking)
AC_SUBST(oa_optimize_options)
])
