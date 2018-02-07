#!/bin/bash 
APPLICATION_BASE="mercury"

get_bindir ()
{
#  Taken from https://stackoverflow.com/a/246128/3180795
  local SOURCE="$1" NAME="$2" TARGET DIR RDIR
  #  resolve $SOURCE until the file is no longer a symlink
  while [ -h "$SOURCE" ]; do 
    TARGET="$(readlink "$SOURCE")"
    if [[ $TARGET == /* ]]; then
      echo "INFO: SOURCE '$SOURCE' is an absolute symlink to '$TARGET'" >&2
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
RUNSCRIPT="$BINDIR/run_application.sh"

if test ! -x "$RUNSCRIPT" ; then
	echo "ERROR: $0 $RUNSCRIPT is either missing or not executable." >&2
	exit 1
fi

mach=$("$BINDIR/csdmach.sh")
if test "$mach" = "macx"; then
    if test "X$DISPLAY" = "X"; then
        DISPLAY=localhost:0.0
        export DISPLAY
    fi
    x=$(pgrep -c xinit)
    if test "$x" -le 1; then
        echo ""
        echo "WARNING: You should start an X11 server in order to use the sketcher"
        echo ""
    fi
fi

CCDC="CCDC_MERCURY"
export APPLICATION_BASE CCDC

. "$RUNSCRIPT" "$@"
