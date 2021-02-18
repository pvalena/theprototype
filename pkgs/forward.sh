#!/bin/bash
#
# ./forward.sh BRANCH
#   Take ale git folders in current folder (depth 1), stash,
#   checkout to BRANCH
#   and pull changes.
#
#   Prints out 'Uncommited changes' if changes are made to files
#   tracked by git. Otherwise gives you first line of last commit entry.
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

[[ "$1" == '-b' ]] && {
  BR="$2"
  shift 2
  :
} || BR=rawhide

[[ -z "BR" ]] && die 'Invalid branch'

while read G; do
  cd "$my" || die "Failed to cd to '$my'"

  [[ -d "$G" ]] || continue
  cd "$G" || die "Failed to cd '$G'"

  printf "%-30s" "$G "
  [[ -d .git ]] || { error "Not a git repository!" ; continue ; }

  git stash &>/dev/null
  git checkout "$BR" &>/dev/null
  [[ "`git rev-parse --abbrev-ref HEAD`" == "$BR" ]] || { error "Failed to checkout $BR" ; continue ; }
  git status -uno | grep -q 'nothing to commit (use -u to show untracked files)' || { error 'Uncommited changes' ; continue ; }
  git config pull.rebase true || { error 'Failed to set pull.rebase' ; continue ; }
  git pull &>/dev/null || { error 'Pull failed' ; continue ; }
  git pull | grep -q 'Already up to date.' || { error 'Failed to pull changes' ; continue ; }

  echo "Ok        `git log --oneline -1 | grep -v '^$' | cut -d' ' -f2-`"
done < <( ls -d "$@" | grep -v '^\.' )

echo
