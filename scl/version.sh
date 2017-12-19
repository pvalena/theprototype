#!/bin/bash

 [[ "$4" ]] && D="$4" || D="$3"

 P=""
 Y="`~/Work/RH/my/scl/listpkgs.sh -b "$1" "$3" | grep '^rubygem-'`" || { echo FAIL_LIST_OLD >&2 ; exit 1 ; }
 Z=""

 while Z="`~/Work/RH/my/scl/listpkgs.sh -b "$2" "$D" | grep '^rubygem-'`" ; do
  [[ "$Z" ]] || { echo FAIL_LIST_NEW >&2 ; exit 1 ; }
  [[ "$P" == "$Z" ]] || {
    clear
    P="$Z"

    date -I'ns'
    echo -e "\nVersion mismatch:"
    while read y; do
      grep "^$y$" <<< "$Z" &>/dev/null && continue
      echo -ne "  $y => "

      z="$(grep -E "^`rev <<< "$y" | cut -d'-' -f3- | rev`-[0-9]" <<< "$Z")" || z="(missing)"
      echo "$z"

    done <<< "$Y"

    echo -e "\nAdditional builds:"
    while read l; do
      echo -e "  $l"

    done < <( grep -vE "^rubygem-(`cut -d'-' -f2- <<< "$Y" | rev | cut -d'-' -f3- | tr -s '\n' '|' | rev | cut -d'|' -f2-`)-[0-9]" <<< "$Z" )

  }

  sleep 3m

 done
