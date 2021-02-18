#!/bin/bash

[[ '-z' == "$1" ]] && {
  shift
  :
} \
  || exec cloop -w 30 "$0 -z '$1' '$2' '$3' '$4' '$5' '$6' '$7'"

[[ '-d' == "$1" ]] && {
  set -x
  shift
  :
}

[[ '-r' == "$1" ]] && {
  FL="rubygem-"
  shift
  :
} || FL=

[[ '-s' == "$1" ]] && {
  SP="\n"
  shift
  :
} || SP=

BR="${1:-rawhide}"
SP="${2:-${SP}}"
FL="${3:-${FL}}"

ls -d ${FL}*/.git/ | cut -d'/' -f1 | xargs -i bash -c "set -e; cd '{}'; O=\"\$(gits | grep -v '^Changes no staged for commit' | grep -v '^nothing to commit' | grep -vE '^On branch (${BR})$' | grep -v '^Your branch is up to date with' | grep -v ^$ | grep -v 'use \"git push\" to publish your local commits')\"; [[ -z \"\O\" ]] && exit 0; echo -e \"${SP}>>> {}\"; echo \"\$O\"; grep -q '^Your branch is ahead of ' <<< \"\$O\" && gitl -\$(grep '^Your branch is ahead of ' <<< \"\$O\" | rev | cut -d' ' -f2) --oneline | cat"
