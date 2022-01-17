#!/bin/bash
#
# ./status.sh [-d] [-l] [-r] [-s] [BRANCH] [PREFIX] [SEPARATOR]
#   Git status for all!
#
#   `rawhide` branch is the default.
#
#   No prefix is default. Filtered by `grep "PREFIX^"`
#
#   No separator is default. Interpreted by `echo -e "SEPARATOR"`.
#
# Args, in alphabetical order:
#
#   -d  debug mode
#
#   -l  run in loop
#
#   -r  set 'rubygem-' as a prefix (filter)
#
#   -s  set empty line as a separator
#
#

set -e
bash -n "$0"

[[ '-d' == "$1" ]] && {
  D="$1"
  set -x
  shift
  :
}

[[ '-l' == "$1" ]] && {
  LO="$1"
  shift
  :
} || LO=

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

[[ "${1:0:1}" == '-' ]] && { echo "Unknown arg: $1"; exit 1; }

BR="${1:-rawhide}"
FL="${2:-${FL}}"
SP="${3:-${SP}}"

echo "> Branch: $BR"
echo "> Prefix: $FL"
echo "> Separator: $SP"
echo

while :; do
  set +e
  ls -d */.git/ | grep "^$FL" | cut -d'/' -f1 | xargs -i bash -c "set -e; cd '{}'; O=\"\$(gits | grep -v '^Changes no staged for commit' | grep -v '^nothing to commit' | grep -vE '^On branch (${BR})$' | grep -v '^Your branch is up to date with' | grep -v ^$ | grep -v 'use \"git push\" to publish your local commits')\"; [[ -z \"\O\" ]] && exit 0; echo -e \"${SP}>>> {}\"; echo \"\$O\"; grep -q '^Your branch is ahead of ' <<< \"\$O\" && gitl -\$(grep '^Your branch is ahead of ' <<< \"\$O\" | rev | cut -d' ' -f2) --oneline | cat"

  [[ -z "$LO" ]] && break
  sleep 15
  clear
done
