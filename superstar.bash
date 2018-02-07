#!/bin/bash
# was /bin/sh
#-------------------------------------------------------------------------------
# superstar                                                 Willem Nissink 2002
#
# Format:
#
#   superstar [<list of residues>]
#   superstar sa   [file.ins] 
#   superstar mult [file.ins] [<list of directories,moleculefiles>]
#
# Shellscript to start superstar, or a batch-mode superstar. 
#
# When invoked without arguments, or with a list of residues, the 
# superstar python/tkinter interface will start, picking the appropriate
# python instance from the SUPERSTAR_ROOT installation.
#
# The stand-alone version is started by specifying 'sa' as the first argument
# It will automatically pick the appropriate executable. Further arguments
# will be passed on to the superstar executable.
#
# Use 'superstar mult' to run superstar_mult.py with the appropriate python
# version. This script can be used to run batch jobs of more than one
# superstar run. Further arguments will be passed on. Directories and
# molecule files may be mixed in the list. The second argument must be the 
# (template) superstar.ins file that will be used for all jobs. Third and
# further arguments must consitute a list of molecule files and/or directories.
# All files in directories will be treated as molecule file entries.
# SuperStar automatically recognises the molecule file format based on the
# file extension. Output will be written to the directory where each
# molecule file resides, and gzipped.
#
#-------------------------------------------------------------------------------
# Changed some syntax to make compatible with symlinks.
# Martin (2018)

export APPLICATION_BASE="superstar_app"

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
RUNSCRIPT="$BINDIR/run_application.sh"

# Workaround for BZ 14220.  Avoid run_application.sh printing messages to stderr
# as Hermes thinks these indicate a fatal error in Superstar.
export NO_PRINTING=1

if test ! -x "$RUNSCRIPT" ; then
    echo "Fatal error: $0 $RUNSCRIPT is either missing or not executable."
    exit 1
fi

export mach=$("${BINDIR}/csdmach.sh")

debug=0
standalone=0
mult=0
test "$1" = "-d" && debug=1
test "$1" = "sa" && standalone=1
test "$1" = "standalone" && standalone=1
test "$1" = "mult" && mult=1

#-------------------------------------------------------------------------------
# Separate out argument string
#-------------------------------------------------------------------------------
n=0
m=0
all_args=" "
# if one of the three options has been set, ignore first argument.
if test $standalone = 1 || test $debug = 1 || test $mult = 1; then
   argno=1
else
   argno=0
fi

for arg in "$@"
do
   if test $n -ge $argno ; then
      all_args="$all_args $arg"
      m=$(( m++ ))
   fi
   n=$(( n++ )) 
done

if test $mult = 1 ; then
   ${echo} "Starting SuperStar batch version (mult) with args$all_args"
   python "${BINDIR}/superstar_mult.py" "$all_args"
else
   . "$RUNSCRIPT" "$all_args"
fi

exit
