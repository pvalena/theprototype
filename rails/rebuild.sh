#!/usr/bin/zsh
#
# ./rebuild.sh [-c][-s] SOURCE_BRANCH DESTINATION_BRANCH
#
#   -c  Continue where left
#   -s  Skip modifications, just run build
#
#

set -e
bash -n "$0"
set +e

die () { echo "$@!" >&2 ; exit 1 ; }
delim () { { set +x ; } &>/dev/null ; echo ; read -qs "?--> Continue?" ; set -x ; clear ; }

[[ '-c' == "$1" ]] && { C="$1" ; shift ; } || C=
[[ '-s' == "$1" ]] && { S="$1" ; shift ; } || S= # Skip all modifications

SB="${1:-pvalena/rebase}"
DB="${2:-origin/master}"

# bootstrap
BS=(actionview railties actionpack activemodel activestorage)

clear
set -xe

[[ -z "$S" ]] && {
  for a in $BS; do
    rm -rf rubygem-${a}-bs &>/dev/null
  done

  [[ `ls | wc -l` -eq 11 ]]
  clear

  [[ -z "$C" ]] && {
    ls | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; git checkout '`cut -d'/' -f2- <<< "${DB}"`' || exit 255 ; git fetch || exit 255 ; git stash ; git reset --hard '${DB}' || exit 255 ; git merge ${SB} || exit 255"
    delim
  }

  for a in $BS; do
    cp -ir rubygem-${a}{,-bs}
  done
  delim

  ls -d *-bs | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; git reset --hard HEAD^ || exit 255"
  delim

  [[ `ls | wc -l` -eq 16 ]]
  clear
}

ls | sort -r | xargs -n1 -i bash -c "echo ; cd {} || exit 255 ; echo \"--> {}\" ; git h --patch-with-stat | colordiff  ; git s -uno"
delim

xargs -n1 -i bash -c "echo ; set -x ; ls 'rubygem-{}' &>/dev/null || exit 255 ; cd 'rubygem-{}' || exit 255 ; git pull || exit 255 ; git status | grep -q \"Your branch is up to date with '${DB}'.\" && exit 0 ; git s | grep -q \"Your branch is ahead of '${DB}' by 1 commit.\" || exit 255 ; for z in {1..10}; do fedpkg scratch-build --srpm && fedpkg new-sources \$(cut -d'(' -f2 < sources | cut -d')' -f1) && { fedpkg push || exit 255 ; for x in {1..10}; do fedpkg build && exit 0 ; sleep 600 ; done ; exit 255 ; } ; sleep 600 ; done ; exit 255" <<EOLX
activesupport
activejob
activemodel-bs
activerecord
activestorage-bs
actionview-bs
actionpack-bs
actionmailer
actioncable
railties-bs
rails
activemodel
actionview
actionpack
activestorage
railties
EOLX
