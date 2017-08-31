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

 my="$(readlink -e "`pwd`")"

 [[ "$my" && -d "$my" ]] || die "Invalid working dir: '$my' in `pwd`"

for x in railties rails activesupport activerecord activejob actionview actionpack actionmailer actioncable activemodel; do
  G="rubygem-$x"

  [[ -d "$G" ]] || {
    fedpkg co "$G" &>/dev/null || die "Failed to checkout gem '$G'"

  }

  cd "$G" || {
    echo "Failed to cd '$G'" 2>&1
    exit 1

  }

  #git stash &>/dev/null
  #git checkout master &>/dev/null
  #[[ "`git rev-parse --abbrev-ref HEAD`" == 'master' ]] || die 'Failed to checkout master'
  #git status | grep -q 'nothing to commit, working directory clean' || die 'Uncommited changes'
  #git pull &>/dev/null || die 'Pull failed'
  #git status | grep -q 'Your branch is up-to-date' || die 'Failed to fast-forward'

    fnd=
    grep '^acti' <<< "$x" &>/dev/null && {
      N="`cut -c7- <<< "$x"`"
      N="`cut -c-6 <<< "$x"` ${N^}"

    } || N="$x"

    N="${N^}"

    echo -e "\n>>> $N"

    T="Update to $N $1"

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

echo
