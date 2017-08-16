#!/bin/bash
#
# ./forward.sh
#   Take ale git folders in current folder (depth 1), checkout to master
#   and pull changes.
#
#   Prints out 'Uncommited changes' if working directory is not clean.
#   Otherwise gives you first line of last commit entry.
#

die () {
  error "$@"
  git status
  exit 1
}

error () {
  echo "Error     $@!" 2>&1
}

my="$(readlink -e "`pwd`")"
pad=50

[[ "$my" && -d "$my" ]] || die "Invalid working dir: '$my' in `pwd`"

while read G; do
  cd "$my" || die "Failed to cd to '$my'"

  [[ -d "$G" ]] || continue
  cd "$G" || die "Failed to cd '$G'"

  printf "%-30s" "$G "
  [[ -d .git ]] || { error "Not a git repository!" ; continue ; }

  git stash &>/dev/null
  git checkout master &>/dev/null
  [[ "`git rev-parse --abbrev-ref HEAD`" == 'master' ]] || { error 'Failed to checkout master' ; continue ; }
  git status | grep -q 'nothing to commit, working directory clean' || { error 'Uncommited changes' ; continue ; }
  git pull &>/dev/null || { error 'Pull failed' ; continue ; }
  git status | grep -q 'Your branch is up-to-date' || { error 'Failed to fast-forward' ; continue ; }

  echo "Ok        `git log --oneline -1 | grep -v '^$' | cut -d' ' -f2-`"
done < <( ls )

echo
