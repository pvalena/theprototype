#!/bin/bash
#
# ./download-builds.sh [-d] [-b] [-x] PACKAGE DIST1 [DIST2 [...]]
#   perform search for packages named PACKAGE(regexp)
#   and download all latest corresponding builds for DIST(f.e.: fc24 el7)
#
#  Specific options order is required!
#
# Options:
#   -d    debug mode
#   -b    use brew instead of koji
#   -x    use exact PACKAGE name; do not perform search
#
#

die () {
  echo "Error: $@!" >&2
  exit 1

}

 [[ "$1" == "-d" ]] && { DEBUG=y ; shift ; } || DEBUG=
 [[ "$1" == "-b" ]] && { tool="brew" ; shift ; } || tool=koji
 [[ "$1" == "-x" ]] && { E="$1" ; shift ; } || E=

 [[ "$1" ]] || die "Arg 'package' Missing"
 [[ "$2" ]] || die "Arg 'dist' Missing"

 PKG="$1"

 shift

[[ "$E" ]] && GS="$PKG" || GS="`$tool search package "$PKG"`"

while read P; do
for A in "$@"; do
  X="`$tool search build -r "^$P\-[0-9]" 2>/dev/null | grep "\.$A$" | sort -r | head -1`" || echo "$P:$A > search failed"
  [[ "$DEBUG" ]] && debug "`$tool search build -r "^$P\-[0-9]" 2>/dev/null`"

  [[ -n "$X" ]] && {
    c=0
    S=
    while [[ $c -lt 100 ]] ; do
      let 'c += 1'
      set -x
      $tool download-build -q -a noarch -a x86_64 "$X" && S=Y && break
      set +x

    done

    [[ "$S" ]] || echo "$P:$A > download failed: $X"

  }

done
done <<< "$GS"
