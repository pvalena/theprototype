#!/bin/zsh
#

die () { echo "$@!" >&2 ; exit 1 ; }
delim () { { set +x ; } &>/dev/null ; echo ; read -qs "?--> Continue?" ; set -x ; clear ; }

[[ '-c' == "$1" ]] && { C="$1" ; shift ; } || C= # Skip merge from master (Continue, or do a master build)
[[ '-s' == "$1" ]] && { S="$1" ; shift ; } || S= # Skip all modifications

[[ -z "$1$C$S" ]] && die "You have to specify destination branch or some option"

B="${1:-master}"

clear
set -xe

[[ -z "$S" ]] && {
  for a in actionview railties actionpack; do
    rm -rf rubygem-${a}-bs &>/dev/null
  done

  [[ `ls | wc -l` -eq 10 ]]
  clear

  [[ -z "$C" ]] && {
    ls | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; git c "$B" || exit 255 ; git p || exit 255 ; git m origin/master || exit 255"
    delim
  }

  for a in actionview railties actionpack; do
    cp -ir rubygem-${a}{,-bs}
  done
  delim

  ls -d *-bs | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; git r --hard HEAD^ || exit 255"
  delim

  [[ `ls | wc -l` -eq 13 ]]
  clear
}

ls | sort -r | xargs -n1 -i bash -c "echo ; cd {} || exit 255 ; echo \"--> {}\" ; git h --patch-with-stat | colordiff  ; git s -uno"
delim

xargs -n1 -i bash -c "echo ; set -x ; ls rubygem-{} &>/dev/null || exit 255 ; cd rubygem-{} || exit 255 ; git p || exit 255 ; git s | grep -q \"Your branch is up-to-date with 'origin/$B'.\" && exit 0 ; git s | grep -q \"Your branch is ahead of 'origin/$B' by 1 commit.\" || exit 255 ; for z in {1..10}; do fedpkg scratch-build --srpm && { fedpkg push || exit 255 ; for x in {1..10}; do fedpkg build && exit 0 ; sleep 600 ; done ; exit 255 ; } ; sleep 600 ; done ; exit 255" <<EOLX
activesupport
activejob
activemodel
activerecord
actionview-bs
actionpack-bs
actionmailer
actioncable
railties-bs
rails
actionview
actionpack
railties
EOLX
