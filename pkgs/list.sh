#!/bin/bash
#
# ./listpkgs.sh [-a][-b][-c][-f][-k][-r] TAG PREFIX
#
#   Get a list of packages in a TAG with prefix PREFIX.
#   Uses brew brew command by default.
#   PREFIX is validated as a regular expression (grep -E).
#
#   Options have to be specified before Arguments.
#   Options are expected in an alphabetical order.
#
# Arguments:
#   TAG     brew tag, f.e.: 
#                           
#   PREFIX  prefix to filter by, f.e. scl name with trailing '-',
#           like 'rubygem-'
#
# Options:
#   -a    keep prefix
#   -b    keep version
#   -c    use cbs command
#   -f    use koji command
#   -k    keep NVR
#   -r    result in random order
#
#

 die () {
  echo "Error: $@" >&2
  exit 1
 }

 usage () {
  local mf="`readlink -e "$0"`"
  [[ -r "$mf" ]] || die "Invalid file "

  local N="`cat -n "$mf" | tr -s '\t' ' ' | grep -vE '^ [0-9]+ #' | head -n1 | cut -f2 -d' ' | grep -E '^[0-9]+$'`"

  [[ -n "$N" && $N -gt 2 ]] || die 'No help :('

  let 'N -= 1'

  head -n$N "$mf" | tail -n+2 | cut -d'#' -f2- | ${PAGER-more}
  exit 0
 }

 cutx () {
  rev | cut -d'-' -f${1}- | rev
 }

 [[ "$1" == "-a" ]] && { PRE= ; shift ; } || PRE=y
 [[ "$1" == "-b" ]] && { VER="cutx 2" ; shift ; } || VER="cutx 3"
 [[ "$1" == "-c" ]] && { WHA="koji -p cbs" ; shift ; } || WHA=brew
 [[ "$1" == "-d" ]] && { DEB="y" ; shift ; } || DEB=
 [[ "$1" == "-f" ]] && { WHA=koji ; shift ; }
 [[ "$1" == "-k" ]] && { VER=cat ; shift ; }
 [[ "$1" == "-r" ]] && { RAN=R ; shift ; } || RAN=
 [[ -z "$1" || "$1" == "-h" ]] && usage

 [[ -n "$PRE" ]] && PRE="$2"

 [[ -n "$DEB" ]] && set -x

 exec $WHA list-tagged --quiet --inherit --latest "$1" | grep -E "^$2" | cut -d' ' -f1 | sed "s/^$PRE//" | $VER | sort -u$RAN | grep -v '^$'
