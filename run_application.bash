#!/bin/bash 
#

# rt 19624
# Allow the user to choose a locale ...
#LANG=C; export LANG
#LC_ALL=C; export LC_ALL
# ... but insist on C for LC_NUMERIC
export LC_NUMERIC=C

# a function for text output
# should be used for all printing
# the variable NO_PRINTING can be set to discard all messages
print_line()
{
    if test "x${NO_PRINTING}" = "x" ; then
        echo "$*" >&2
    fi
}

get_bindir ()
{
#  Taken from https://stackoverflow.com/a/246128/3180795
  local SOURCE="$1" NAME="$2" TARGET DIR RDIR
  #  resolve $SOURCE until the file is no longer a symlink
  while [ -h "$SOURCE" ]; do 
    TARGET="$(readlink "$SOURCE")"
    if [[ $TARGET == /* ]]; then
      echo "INFO: SOURCE '$SOURCE' is an absolute symlinky to '$TARGET'" >&2
      SOURCE="$TARGET"
    else
      DIR="$( dirname "$SOURCE" )" 
      echo "INFO: SOURCE '$SOURCE' is a relative symlink to '$TARGET' (relative to '$DIR')" >&2
      #  If $SOURCE was a relative symlink, we need to resolve 
      #+ it relative to the path where the symlink file was located
      SOURCE="$DIR/$TARGET"
    fi
  done
  echo "INFO: SOURCE is '$SOURCE'"  >&2
  RDIR="$( dirname "$SOURCE")"
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  if [ "$DIR" != "$RDIR" ]; then
    echo "INFO: $NAME '$DIR' resolves to '$DIR'" >&2
  fi
  echo "INFO: $NAME is '$DIR'" >&2
  if [[ -z $DIR ]] ; then
    echo "."
  else
    echo "$DIR"
  fi
}

if test "x${APPLICATION_BASE}" = "x" ; then
   print_line "Fatal error: $0 Environment variable APPLICATION_BASE not set by calling script"
fi
#
CONQUEST_MAIN=
#
debug=0
#
test "$1" = "-d" && debug=1

if test "x${CQLOCAL}" = "x" ; then

  BINDIR=$(get_bindir "$0" "BINDIR")

  test ${debug} = 1 && print_line "BINDIR        : ${BINDIR}"

  CQLOCAL=${BINDIR%/*}

fi

if test "x${CSDHOME}" = "x" ; then

   export CSDHOME="${CQLOCAL}"
   test ${debug} = 1 && print_line "CSDHOME       : ${CSDHOME}"

fi

if test ${debug} = 1 ; then
   if test -h "$0" ; then
      print_line "Symbolic Link : $0"
   fi
   print_line "CQLOCAL       : ${CQLOCAL}"
   exit 0
fi

noexec=0

if test "x$CSDMACHINE" != "x" ; then
   mach=$CSDMACHINE
elif test -f "${CQLOCAL}/bin/csdmach.sh" ; then
   mach=$("$CQLOCAL/bin/csdmach.sh")
else
   print_line "Could not determine machine type" >&2 
   exit 1
fi

# ensure netscape wrapper script is in the user's PATH
if test -f "${CQLOCAL}/bin/nss.sh" ; then
   PATH="${CQLOCAL}/bin:${PATH}"
else
   print_line "Could not find netscape startup script nss.sh"
   PATH="${PATH}"
fi
export PATH

# Fall back to 32-bit linux files if no 64-bit are present on a 64-bit linux system
if test ! -d "${CQLOCAL}/c_${mach}" && test "${mach}" = "linux-64" ; then
    print_line "No 64-bit files found, attempting to use 32-bit files instead"
    mach=linux
fi

if test ! -d "${CQLOCAL}/c_${mach}" ; then
   if test "x${CONQUEST_MAIN}" = "x" ; then
      noexec=1
   else
      if test ! -d "${CONQUEST_MAIN}/c_${mach}" ; then
         noexec=1
      else
         CQROOT="${CONQUEST_MAIN}"
      fi
   fi
else
   CQROOT="${CQLOCAL}"
fi


if test ${noexec} = 1 ; then
   print_line "Could not find files for ${mach}"
#   exit
fi


mesa=0
mesamethod=
mesamessage="No OpenGL libraries found, using fallback MesaGL. \
This software requires  OpenGL libraries for optimum performance \
and some features may not work correctly without them. \
We highly recommend installation of OpenGL libraries for your system \
- see http://www.opengl.org/wiki/Getting_started for more details."

verify=0
checkgl=1
cmdopt=

while  test $# -ne 0  ; do
  case "$1" in
    -mesa)
        mesa=1
        mesamethod='-mesa'
        ;;
    -verify)
        verify=1
        ;;
    -debug)
        debug=1
        ;;
    -nogl) # Don't check for OS openGL capabilities, this supresses the OpenGL mesa warning.
        checkgl=0
        ;;
#pass other options through to executable
    *)  
        cmdopt="$cmdopt $1"
        ;;

  esac

  shift

done

#ensure executable exists

if test -f "${CQROOT}/c_${mach}/bin/${APPLICATION_BASE}.x"; then 
    executable="${CQROOT}/c_${mach}/bin/${APPLICATION_BASE}.x"
elif test -d "${CQROOT}/c_${mach}/bin/${APPLICATION_BASE}.app" ; then
    executable="${CQROOT}/c_${mach}/bin/${APPLICATION_BASE}.app/Contents/MacOS/${APPLICATION_BASE}"
else
    executable=""
fi


#verify mode
if test "X${executable}" != "X"; then
    if test "$verify" = "1" ; then
        print_line "Found executable ${CQROOT}/c_${mach}/bin/${APPLICATION_BASE}.x"
        exit 0
    fi
    
else

    print_line "Cannot find ${APPLICATION_BASE}.x executable for architecture ${mach} in ${CQROOT}/c_${mach}/bin"

fi


if test ${mesa} != 1 ; then
   if test "X${CQGRAPHICS}" = "Xmesa" ; then 
      mesa=1
      mesamethod='CQGRAPHICS'
   fi
fi

TCL_LIBRARY="${CQROOT}/share/lib/tcl" ; export TCL_LIBRARY
PYTHONHOME="${CQROOT}/share:${CQROOT}/c_${mach}"; export PYTHONHOME

if test "x$CCDC" = "x" ; then
    CCDC=CCDC
fi

# When running on slow disks, a lot of time can be spent at start-up searching for 
# libraries. See bug 7842.
# For this reason, directories should be added to CQLIB in the order:
#   - directory containing the most used libraries 
#   - directory containing the next most used libraries 
#   - etc
CQLIB="${CQROOT}/c_${mach}/lib/${CCDC}"
CQLIB="$CQLIB:${CQROOT}/c_${mach}/lib/qt"
CQLIB="$CQLIB:${CQROOT}/c_${mach}/lib"
CQLIB="$CQLIB:$CQROOT/c_$mach/lib/expat"
GLLIB="${CQROOT}/c_${mach}/lib/MesaGL"
GCCLIB="${CQROOT}/c_${mach}/lib/GCC"

# Use this to detect OpenGL when running from SG or linux
: "${glxinfo=/usr/sbin/glxinfo}"

case ${mach} in 

   linux*)
         if test ${checkgl} = 1; then
             if test ${mesa} = 1 ; then
                print_line "Mesa being forced by ${mesamethod}"
                print_line "$mesamessage"
                CQ_LD_LIBRARY_PATH="${GLLIB}"
             # The glxinfo executable is in a different location depending on linux version
             #was: elif test -x `which glxinfo` ; then
             elif command -v glxinfo 2>&1 /dev/null ; then
                glxout=$(glxinfo 2>&1 | grep -i "opengl version string")
                if test "x$glxout" = "x"  ; then
                   print_line "Cannot use native OpenGL. Using Mesa."
                   print_line "$mesamessage"
                   CQ_LD_LIBRARY_PATH="${GLLIB}"
                else
                   print_line "Using native OpenGL"
                   CQ_LD_LIBRARY_PATH=
                fi
             else
                print_line "Cannot get graphics info. Using Mesa."
                print_line "$mesamessage"
                CQ_LD_LIBRARY_PATH="${GLLIB}"
             fi
         fi

         CQLIB="${CQLIB}:${GCCLIB}:${CQ_LD_LIBRARY_PATH}"
         if test "X${LD_LIBRARY_PATH}" != "X" ; then
              LD_LIBRARY_PATH="${CQLIB}:${LD_LIBRARY_PATH}"
         else
              LD_LIBRARY_PATH="${CQLIB}"
         fi
         export LD_LIBRARY_PATH         ;;   
     
   # MAC OSX requires DYLD_LIBRARY_PATH instead of LD_LIBRARY_PATH
   # actually, their all statically linked at the moment, but for the future
    macx*)
        if test "X${DYLD_LIBRARY_PATH}" != "X" ; then
            DYLD_LIBRARY_PATH="${CQLIB}:${LIBPATH}"
        else
            DYLD_LIBRARY_PATH="${CQLIB}"
        fi
        export DYLD_LIBRARY_PATH
        ;;

   *)
         print_line "ERROR: Unrecognised machine type \"${mach}\""
         exit 1
         ;;

esac 

# rt 17975
unset XMODIFIERS

# work around transparent menus (bz10711)
XLIB_SKIP_ARGB_VISUALS=1; export XLIB_SKIP_ARGB_VISUALS

QT_PLUGIN_PATH="$CQROOT/c_$mach/lib/qt/plugins"
export QT_PLUGIN_PATH

#Finally, execute the program
${CSDDEBUGGER} "${executable}" "${cmdopt}"


