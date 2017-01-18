#!/bin/bash
#
# ./sections.sh
#
#   Print possibly invalid scl-enable sections.
#
#   Needs listpkgs.sh script in same directory.
#   Please edit values below.
#

 scl="rh-ror50"
 bra="rhscl-2.4-${scl}-rhel-7"
 myd="$(readlink -e "`pwd`")"
 fst= # runs `rhpkg co` checkout, git checkout etc. if set to YES

###

 die () { echo -e "\n==> $1" >&2 ; [[ "$2" ]] || git status ; exit 1 ; }

 mylist="$(readlink -e "`dirname "$0"`/listpkgs.sh")"

 [[ -x "$mylist" ]] || die 'No listpkgs.sh found: $mylist' nogit

 [[ -n "$myd" && -d "$myd" ]] || die "Invalid working directory" nogit

$mylist ${bra}-build ${scl}- | while read z; do
  cd "$myd" || die "Failed to cd '$myd'" nogit

  [[ -z "$fst" || -d "$z" ]] || { rhpkg co "$z" &>/dev/null ; }
  [[ -d "$z" ]] || die "$z : directory missing" nogit
  cd "$z" || die "$z : failed to cd" nogit

  [[ "$fst" ]] && {
    git fetch &>/dev/null || die "$z : failed to fetch"
    git checkout "$bra" &>/dev/null || die "$z : failed to checkout"
    git pull &>/dev/null || die "$z : p"

  }

  [[ -r "$z.spec" ]] || die "$z : spec file missing"

  O="`sed -n '/^%{?scl:scl enable/,/%{?scl:EO/ p' "$z.spec" | tr -s '\t' ' ' | grep -v '^#' | grep -v '^$' \
    | while read l; do echo "$l" ; done`"

  while [[ -n "$O" ]]; do
    P="`grep -m 1 -B 10000 '^%{?scl:EO' <<< "$O"`"
    C="`wc -l <<< "$P"`"
    let 'C += 1'

    O="`tail -n+$C <<< "$O"`"

    E=

    [[ "$C" -lt 4 ]] && E=y
    [[ "$C" -gt 4 && -z "`tail -n+2 <<< "$P" | head -n1 | grep -E '^set -x?ex?$'`" ]] && E=y

    [[ "$E" ]] && echo -e "\n--> $z" && echo "$P"

  done

done
