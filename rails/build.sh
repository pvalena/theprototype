#!/bin/zsh
#

echo "Use rebuild.sh -c instead."
exit 1

clear
set -xe

for a in actionview railties actionpack; do
  rm -rf rubygem-$a-bs &>/dev/null
  cp -ir rubygem-$a{,-bs}
done
{ set +x ; } &>/dev/null ; echo ; read -qs "?--> Continue?" ; set -x ; clear

[[ `ls | wc -l` -eq 13 ]]
clear

ls -d *-bs | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; git r --hard HEAD^ || exit 255"
{ set +x ; } &>/dev/null ; echo ; read -qs "?--> Continue?" ; set -x ; clear

ls | sort -r | xargs -n1 -i bash -c "echo ; cd {} || exit 255 ; git c master || exit 255 ; git p || exit 255 ; echo \"--> {}\" ; git h --patch-with-stat | colordiff  ; git s -uno"
{ set +x ; } &>/dev/null ; echo ; read -qs "?--> Continue?" ; set -x ; clear

xargs -n1 -i bash -c "echo ; set -x ; ls rubygem-{} &>/dev/null || exit 255 ; cd rubygem-{} || exit 255 ; git p || exit 255 ; git s | grep -q \"Your branch is ahead of 'origin/master' by 1 commit.\" || exit 255 ; for z in {1..10}; do fedpkg scratch-build --srpm && { fedpkg push || exit 255 ; for x in {1..10}; do fedpkg build && exit 0 ; sleep 600 ; done ; exit 255 ; } ; sleep 600 ; done ; exit 255" <<EOLX
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
