#!/bin/bash

 MY="`pwd`"

 B="`cut -d'-' -f1-2,5- <<< "$2"-build`"
 C="`cut -d'-' -f3-4 <<< "$2"`"

 stat () {
  while read l; do
    echo
    cd "$MY/$l" || { echo "cd '$MY/$l'" >&2 ; return 1 ; }
    #git f || { echo "FETCH_FAIL: $l" ; break ; }
    git c "$2" 2>&1 | grep "^Already on '$2'$" &>/dev/null || { echo "INVALID_BRANCH: $l ($2)" ; continue ; }
    git s | grep '^nothing to commit, working directory clean$' &>/dev/null || { echo "NOT_COMMITED: $l" ; continue ; }
    git s | grep 'branch is ahead' && { echo "NOT_PUSHED: $l" ; continue ; }
    G="`git d "origin/$1"`" || { echo "DIFF_FAIL: $l" ; break ; }
    grep -E '^[+-]Release: ' <<< "$G" && { echo "RELEASE_DIFF: $l" ; continue ; }

  done < <( ~/Work/RH/my/scl/listpkgs.sh "$B" "$C" )

  return 0

 }

 subs () {
  local f="$1"
  local t="$2"
  shift ; shift

  while [[ "$1" ]]; do
    ruby -e "s='`tr -s "'" '"' <<< "$1"`' ; r='' ; until r.eql?(s) do r=s ; s = s.gsub(\"$f\", \"$t\") end ; puts r"
    shift

  done

 }

 P=""

 while A="$(subs "\n\n\n" "\n\n" "`stat "$1" "$2"`")"; do
  [[ "$A" ]] || { echo FAIL_DATA >&2 ; exit 1 ; }

  [[ "$P" == "$A" ]] || {
    P="$A"
    clear
    date -I'ns'
    echo "${A:1}"
    sleep 3m

  }

 done

 echo FAIL_STATUS >&2
 exit 1
