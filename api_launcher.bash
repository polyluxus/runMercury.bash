#!/bin/bash

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

BINDIR=$(get_bindir "$0" "BINDIR")

PYTHON_DIR=$(get_bindir "$1" "PYTHON_DIR")

export PYTHONHOME="${PYTHON_DIR%/*}"
export PYTHONPATH="${PYTHONHOME}:$PYTHONPATH"

mach=$("${BINDIR}/csdmach.sh")

if test "${mach}" = "macx"; then

    # Locate API libraries
    if [ -d "${PYTHONHOME}/lib/python2.7/site-packages/ccdc/_lib" ] ; then
        export DYLD_LIBRARY_PATH="$PYTHONHOME/lib/python2.7/site-packages/ccdc/_lib"
        export DYLD_FRAMEWORK_PATH="$PYTHONHOME/lib/python2.7/site-packages/ccdc/_lib"
    elif [ -d "${PYTHONHOME}/lib/python2.7/site-packages/ccdc/lib" ] ; then
        export DYLD_LIBRARY_PATH="$PYTHONHOME/lib/python2.7/site-packages/ccdc/lib"
        export DYLD_FRAMEWORK_PATH="$PYTHONHOME/lib/python2.7/site-packages/ccdc/lib"
    fi

else

    # Locate API libraries
    if [ -d "${PYTHONHOME}/lib/python2.7/site-packages/ccdc/_lib" ] ; then
        export LD_LIBRARY_PATH="$PYTHONHOME/lib/python2.7/site-packages/ccdc/_lib"
    elif [ -d "${PYTHONHOME}/lib/python2.7/site-packages/ccdc/lib" ] ; then
        export LD_LIBRARY_PATH="$PYTHONHOME/lib/python2.7/site-packages/ccdc/lib"
    fi

    # Try to locate CSD install if no CSDHOME currently set
    if [ ! -d "${CSDHOME}/csd" ] ; then
      if [ -d "${BINDIR%/*}/csd" ] ; then
         export CSDHOME="${BINDIR%/*}"
      elif [ -d "${BINDIR%/*/*}/cambridge/csd" ] ; then
         export CSDHOME="${BINDIR%/*/*}/cambridge"
      fi
    fi
fi

"$@"
