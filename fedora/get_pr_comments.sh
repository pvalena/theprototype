#!/bin/bash

set -e
bash -n "$0"

myd="`dirname "$(readlink -e "$0")"`"
com="${myd}/get_pr_common.sh"

[[ -r "$com" ]] || false 'Could not find common!'
 . "$com"

[[ -n "$1" ]] && {
  FROM="$1"
  shift
  :
} || FROM="pvalena vondruch jaruga decathorpe ilgrad stevetraylen mtasaka leigh123linux"

sel=""
for n in ${FROM}; do
  [[ -n "$sel" ]] && sel="${sel} or "

  sel="${sel}.user.name == \"${n}\""
done

C="$(echo "$O" | jq -r "${R}.comments[] | select($sel).comment" | grep "$G")"

echo "$C"
:
