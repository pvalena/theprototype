#!/bin/bash
# ./list.sh [-v VER] TAG

getlatest () {
  local P=
  local C=

  while read X; do
    C="`cut -d'-' -f3- <<< "$X"`"

    [[ "$C" == "$P" ]] || {
      P="$C"
      echo "$X"

    }

  done < <(sort -r | rev) | rev | sort

}

VER='[0-9]+'
LAT='--latest'
PST='cat'

[[ "$1" == '-v' ]] && { shift ; VER="$1" ; LAT= ; PST='getlatest' ; shift ; }
[[ "$1" ]] || { echo 'Tag missing (fXX)' >&2 ; exit 1 ; }

echo

while [[ "$1" ]]; do
  koji list-tagged $LAT "$1" \
    | grep -E "^rubygem-(acti(on(cable|mailer|pack|view)|ve(storage|job|model|record|support))|rail(s|ties))-$VER" \
    | tr -s '\t' ' ' | cut -d' ' -f1 | sort -u | $PST

  echo
  shift

done
