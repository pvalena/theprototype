#!/bin/bash
#
# ./bld.sh [-b BRANCH][-m BRANCH][-r][TARGET]
#   -b  checkout branch $BRANCH_B
#   -m  stash & merge $BRANCH_M (defaults to -)
#   -r  stash & reset to origin/$BRANCH_B (defaults to HEAD; see '-b')
#   -s  DO NOT run scratch-build
#   -t  side-tag (target)
#

set -e
bash -n "$0"

trap 'kill 0 ; exit 0' SIGINT

die () {
  echo "--> Error: Failed to $1!" 2>&1
  exit 1
}

KJB="`dirname "$(readlink -e "$0")"`/kj-build.sh"
[[ -x "$KJB" ]] || die "KJB '$KJB' not available."

[[ "$1" == "-b" ]] && { BR="$2" ; shift 2 ; } || BR=
[[ "$1" == "-m" ]] && { MB="$2" ; shift 2 ; } || MB=
[[ "$1" == "-r" ]] && { RE='yy' ; shift 1 ; } || RE=
[[ "$1" == "-s" ]] && { SB='yy' ; shift 1 ; } || SB=

[[ "$1" == '-t' ]] && {
  TR="--target '$2'"
  shift 2
  :
} || TR=

[[ -z "$1" ]] || die "Unknown arg: $1"

kl="pvalena@FEDORAPROJECT.ORG"
klist -A | grep -q ' krbtgt\/FEDORAPROJECT\.ORG@FEDORAPROJECT\.ORG$' || {
  kinit "$kl" -l 30d -r 30d -A
  pgrep -x krenew &>/dev/null || krenew -i -K 60 -L -b
}

[[ -z "$RE" ]] || {
  set -x
    git stash || die 'stash git'
  { set +x ; } &>/dev/null
}

[[ -z "$BR" ]] && BR=HEAD || {
  set -x
    git checkout "$BR" || {
      #fedpkg switch-branch "$BR"
      git checkout "$BR"
    }
    git branch -u "origin/$BR"
    git status 2>&1 | grep -q "On branch $BR$"
  { set +x ; } &>/dev/null
}

git fetch

[[ -z "$RE" ]] || {
  set -x
    git reset --hard "origin/$BR" || die "reset git: $BR"
  { set +x ; } &>/dev/null
}

[[ -z "$MB" ]] || {
  set -x
    git merge "$MB"
    git status -uno 2>&1 | grep -q "^nothing to commit"
  { set +x ; } &>/dev/null
}

# Bad idea. Removes files if not present on server (before new-sources).
# fedpkg sources || :
d="`basename "$PWD"`"

grep -q '^rubygem\-' <<< "$d" \
  && gem fetch "$(cut -d'-' -f2- <<< "$d")" \
  || :

for y in {1..10}; do
  [[ -z "$SB" ]] && {
    set -x
      bash -c "set -xe ; echo | $KJB -c $TR" && SB=y
      git stash
    { set +x ; } &>/dev/null
    [[ -n "$SB" ]] || continue
    false
  } || {
    set -x
      fedpkg new-sources `cut -d'(' -f2 < sources | cut -d')' -f1 | cut -d' ' -f2-` \
        && fedpkg push \
        && bash -c "fedpkg build --skip-nvr-check $TR" \
        && exit 0 \
        || : "Build failed!"
    { set +x ; } &>/dev/null
  }
  sleep 30
done

die "build"
