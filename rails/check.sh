#!/bin/bash
# Check for update commit with VERSION
#
# ./check.sh VERSION [BRANCH]
#   Optionally input 'f*' as BRANCH as a first arg. Default is 'rawhide'.
#   Mandatory is VERSION which will be checked for.
#
#   Uses current working directory.
#

die () {
  echo "Error: $1!" 2>&1
  exit 1
}

[[ -n "$1" ]] && { V="$1" ; shift ; } || die "Version missing"
[[ -n "$1" ]] && { D="$1" ; shift ; } || D="rawhide"

my="$(readlink -e "`pwd`")"

[[ "$my" && -d "$my" ]] || die "Invalid working dir: '$my' in `pwd`"

while read x; do
  G="rubygem-$x"

  [[ -d "$G" ]] || {
    fedpkg co "$G" &>/dev/null || die "Failed to checkout gem '$G'"

  }

  cd "$G" || {
    echo "Failed to cd '$G'" 2>&1
    exit 1
  }

  fnd=
  grep '^acti' <<< "$x" &>/dev/null && {
    N="`cut -c7- <<< "$x"`"
    N="`cut -c-6 <<< "$x"` ${N^}"

  } || N="$x"

  N="${N^}"

  echo -e "\n>>> $N"

  T="Update to $N $V"

  git fetch &>/dev/null || die "git fetch failed"

  while read z; do
    grep "$T" <<< "$z" && fnd=y && break
    echo "$z"

  done < <( git log --oneline -100 "origin/$D" )

  [[ "$fnd" ]] || {
    echo -e "\n !! Update commit for $x not found !!"

  }

  cd "$my" || die "Failed to cd to '$my'"

done

done <<EOLX
rails
activesupport
activejob
activemodel
railties
actionview
actionpack
activestorage
activerecord
actionmailer
actionmailbox
actiontext
actioncable
EOLX

echo
