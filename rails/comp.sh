#!/bin/bash
# Compare Rails core packages's versions using gem-compare
# TODO: DOC

set -xe
bash -n "$0"

die () {
  echo "Error: $1!" 1>&2
  exit 1
}

[[ "$1" ]] && FROM="$1" || FROM="5.0.1"
[[ "$2" ]] && INTO="$2" || INTO="5.0.2"

mkdir -p tmp
cd tmp || die "Could not cd to tmp"

pwd
ls

echo -n "Remove all? "
read R

[[ "$R" == "y" || "$R" == "Y" ]] && rm -vfr *

{ set +x ; } &>/dev/null

{
  while read x; do
      echo " >> $x"
      gem compare -bk "$x" "$FROM" "$INTO"
      echo
      :
  done < <(
      tr -s ' ' <<< "
        rails
        activesupport
        activejob
        activemodel
        railties
        actionview
        actionpack
        activestorage
        activerecord
        actionmailer
        actionmailbox
        actiontext
        actioncable
       " \
        | cut -d' ' -f2 \
        | grep -vE "^$"
    )
 :
} 2>&1 | less


