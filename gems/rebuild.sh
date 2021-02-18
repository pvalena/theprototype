#!/bin/bash
set -xe
bash -n "$0"

c="$1"
[[ -n "$c" ]]

ls -d rubygem-* | xargs -i bash -c "[[ -d {} ]] || exit 1 ; cd {} || exit 255 ; [[ -r .built ]] && exit 0 ; git status &>/dev/null || exit 1 ; git remote -v | grep ^origin | tr -s '\t' ' ' | cut -d' ' -f2 | sort -u | grep -q 'fedoraproject\.org' && { echo ; pwd ; gitt && gitc master && gitp && ../cr-build.sh $c &> cr-build.log && touch .built ; }"
