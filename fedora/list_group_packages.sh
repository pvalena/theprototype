#!/bin/bash

set -e
bash -n "$0"

SRC_FPO_API='https://src.fedoraproject.org/api/0'

abort () {
  echo "$@" >&2
  exit 1
}

[[ "$1" == "-d" ]] && {
  shift
  DEBUG="| tee -a /dev/stderr"
  :
} || DEBUG=

u="$1"
[[ -n "$u" ]] || abort 'No group specified'

URL="${SRC_FPO_API}/group/${u}?projects=1&acl=commit"

[[ -n "$DEBUG" ]] && echo "$URL" >&2

R="$(bash -c "curl -s '$URL' $DEBUG | jq -r '.projects[].name'")" \
  || abort "Curl / jq failed for URL: '$URL'"

[[ -z "$R" ]] && exit 0
echo "$R"
