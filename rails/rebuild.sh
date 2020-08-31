#!/usr/bin/bash
#
# ./rebuild.sh [-c][-n][-s][-t TARGET] SOURCE_BRANCH DESTINATION_BRANCH
#
#   -c  Continue where left
#   -n  No `git fetch`
#   -s  Skip modifications, just run build
#   -t  target for build
#
#

set -e
bash -n "$0"
set +e

die () { echo "$@" >&2 ; exit 1 ; }

delim () {
  local r
  { set +x ; } &>/dev/null
  echo
  read -n1 -p "--> Continue? " r
  echo
  grep -i '^y' <<< "$r" || die 'User abort!'
  set -x
  clear
}

# CONST

# fedora NR
FX=34

# starting folders
ST=13

# bootstrap
BS="actionview railties actionpack activemodel activestorage"

# total folders
TT=18

# ARGS

[[ '-c' == "$1" ]] && { C="$1" ; shift ; } || C=
[[ '-n' == "$1" ]] && { N="$1" ; shift ; } || C=
[[ '-s' == "$1" ]] && { S="$1" ; shift ; } || S= # Skip all modifications

[[ '-t' == "$1" ]] && {
  TG="$2"
  shift 2
  [[ -z "$TG" ]] && die "Sidetag missing: $1"
  :
} || TG=

SB="${1:-pvalena/rebase}"
shift

DB="${1:-origin/master}"
shift

[[ -z "$1" ]] || die "Unknown arg: $1"

clear
set -xe

[[ -z "$S" ]] && {
  echo "Will bootstrap:"
  for a in $BS; do echo "rubygem-$a"; done
  delim

  echo ">>> Cleaning up boostrap folders"
  for a in $BS; do
    rm -rf rubygem-${a}-bs &>/dev/null
  done

  [[ `ls | wc -l` -eq $ST ]] || die "Invalid initial number of folders: `ls`"
  clear

  [[ -z "$C" ]] && {
    echo ">>> Preparing commits in master"
    [[ -z "$N" ]] && fetch="git fetch || exit 255 ;" || fetch=

    ls | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; [[ -r .skip ]] && exit 0 ; git checkout '`cut -d'/' -f2- <<< "${DB}"`' || exit 255 ; $fetch git stash ; git reset --hard '${DB}' || exit 255 ; git merge ${SB} || exit 255"
    delim
  }

  echo ">>> Creating bootstrap folders"
  for a in $BS; do
    bash -c "echo; set -x; cp -ir rubygem-${a}{,-bs}"
  done
  delim

  echo ">>> Setting up bootstrap folders"
  ls -d *-bs | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; [[ -r .skip ]] && exit 0 ; git reset --hard HEAD^ || exit 255"
  delim

  [[ `ls | wc -l` -eq $TT ]] || die "Invalid number of folders incl. *-bs: `ls`"
  clear
}

echo ">>> Display diffs"
ls | sort -r | xargs -n1 -i bash -c "echo ; cd {} || exit 255 ; [[ -r .skip ]] && exit 0 ; echo \"--> {}\" ; git show --patch-with-stat | colordiff  ; git status -uno"
delim

echo ">>> Running builds"
xargs -n1 -i bash -c "echo ; set -x ; ls 'rubygem-{}' &>/dev/null || exit 255 ; cd 'rubygem-{}' || exit 255 ; [[ -r .skip ]] && exit 0 ; git fetch || exit 255 ; git status | grep -q \"Your branch is up to date with '${DB}'.\" && exit 0 ; git status -uno | grep -q \"Your branch is ahead of '${DB}' by 1 commit.\" || exit 255 ; for z in {1..10}; do fedpkg scratch-build --srpm --target '${TG}' && fedpkg new-sources \$(cut -d'(' -f2 < sources | cut -d')' -f1) && { fedpkg push || exit 255 ; for x in {1..10}; do fedpkg build --target '${TG}' && { touch .skip; P=\"\$(cut -d'-' -f1 <<< '{}')\"; [[ 'bs' == \"\$(cut -d'-' -f2 <<< '{}')\" ]] && B='~bootstrap' || B=''; koji wait-repo '${TG}' --build=\"rubygem-\$P-\$(grep -A 1 '^%changelog$' *.spec | tail -n 1 | rev | cut -d' ' -f1 | rev | sed -e 's/[0-9]*://').fc${FX}\$B\" ; exit 0 ; } ; sleep 600 ; done ; exit 255 ; } ; sleep 600 ; done ; exit 255" <<EOLX
activesupport
activejob
activemodel-bs
rails
actionview-bs
actionpack-bs
activerecord
actionmailer
actioncable
activestorage-bs
railties-bs
actiontext
actionmailbox
activemodel
actionview
actionpack
activestorage
railties
EOLX
