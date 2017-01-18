#!/bin/bash
# Check for update commit with VERSION
#
# ./check.sh [BRANCH] VERSION
#   Optionally input 'f*' as BRANCH as a first arg. Default is 'master'.
#   Mandatory is VERSION which will be checked for.
#
#   Uses current working directory.
#

 die () {
    echo "Error: $1!" 2>&1
    exit 1

 }

 [[ "${1:0:1}" == "f" ]] && { D="$1" ; shift ; } || D="master"
 [[ "$1" ]] || die "Arg missing"

for x in railties rails activesupport activerecord activejob actionview actionpack actionmailer actioncable activemodel; do
  G="rubygem-$x"

  [[ -d "$G" ]] || {
    fedpkg co "$G" || die "Failed to checkout gem '$G'"

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

    T="Update to $N $1"

    git f &>/dev/null || die "git f"

    while read z; do
      grep "$T" <<< "$z" && fnd=y && break
      echo "$z"

    done < <( git log --oneline -100 "origin/$D" )

    [[ "$fnd" ]] || {
      echo -e "\n !! Update commit for $1 not found !!"

    }

  cd .. || die "Failed to cd .."

done

echo
