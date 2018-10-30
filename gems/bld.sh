#!/bin/bash
# -b  checkout branch $2
# -r  stash & reset to origin/HEAD
# -s  do not run scratch-build

set -e
bash -n "$0"

trap 'kill 0 ; exit 0' SIGINT

die () {
  echo "--> Error: Failed to $1!" 2>&1
  exit 1
}

[[ "$1" == "-b" ]] && { BR="$2" ; shift 2 ; } || BR=
[[ "$1" == "-r" ]] && { RE='yy' ; shift 1 ; } || RE=
[[ "$1" == "-s" ]] && { SB='yy' ; shift 1 ; } || SB=

[[ -z "$BR" ]] || {
  set -x
    fedpkg switch-branch "$BR"
    git checkout "$BR"
    git status 2>&1 | grep -q "^On branch $BR$"
  { set +x ; } &>/dev/null
}

git fetch

[[ -z "$RE" ]] || {
  set -x
    git stash || die 'stash git'
    git reset --hard origin/HEAD || die 'reset git'
  { set +x ; } &>/dev/null
}

for y in {1..10}; do
  [[ -z "$SB" ]] && {
    set -x
      fedpkg scratch-build --srpm && SB=y
    { set +x ; } &>/dev/null
    [[ -n "$SB" ]] || continue
    false
  } || {
    set -x
      fedpkg new-sources `cut -d'(' -f2 < sources | cut -d')' -f1` \
        && fedpkg push \
        && fedpkg build \
        && exit 0 \
        || : "Build failed!"
    { set +x ; } &>/dev/null
  }
  sleep 30
done

die "build"
