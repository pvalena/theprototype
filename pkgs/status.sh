#!/bin/bash

[[ '-s' == "$1" ]] && {
  SP="\n"
  shift
  :
} || SP=

[[ '-z' == "$1" ]] \
  || exec cloop -w 30 "$0 -z '$1' '${2:-$SP}'"

shift

BR="${1:-master}"
SP="${2:-}"

ls -d rubygem-*/ | cut -d'/' -f1 | xargs -i bash -c "set -e; cd '{}'; O=\"\$(gits | grep -v '^Changes no staged for commit' | grep -v '^nothing to commit' | grep -vE '^On branch (${BR})$' | grep -v '^Your branch is up to date with' | grep -v ^$ | grep -v 'use \"git push\" to publish your local commits')\"; [[ -z \"\O\" ]] && exit 0; echo -e \"${SP}>>> {}\"; echo \"\$O\"; grep -q '^Your branch is ahead of ' <<< \"\$O\" && gitl -\$(grep '^Your branch is ahead of ' <<< \"\$O\" | rev | cut -d' ' -f2) --oneline | cat"
