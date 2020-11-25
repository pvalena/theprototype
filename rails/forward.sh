#!/bin/bash
#
# ./forward.sh
#   [Rails-specific]
#   Checkout or update(pull) git repository in local directory and list its status (commit message)
#

die () {
  echo "Error: $1!" 2>&1
  git status
  exit 1
}

my="$(readlink -e "`pwd`")"

[[ "$my" && -d "$my" ]] || die "Invalid working dir: '$my' in `pwd`"

for x in railties rails activesupport activestorage activerecord activejob actionview actionpack actionmailer actioncable activemodel actionmailbox actiontext; do
  G="rubygem-$x"

  [[ -d "$G" ]] || {
    fedpkg co "$G" &>/dev/null || die "Failed to checkout gem '$G'"
    continue
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

  for f in .skip .bootstrapped .{,scratch-}built result; do
    rm -rf "$f"
  done

  git stash &>/dev/null
  git checkout master &>/dev/null
  [[ "`git rev-parse --abbrev-ref HEAD`" == 'master' ]] || die 'Failed to checkout master'
  git status -uno | grep -q '^nothing to commit ' || die 'Uncommited changes'
  git pull &>/dev/null || die 'Pull failed'
  git status -uno | grep -q '^Your branch is up to date' || die 'Failed to fast-forward'

  git log --oneline -1 | grep -v '^$'

  cd "$my" || die "Failed to cd to '$my'"
done

echo
