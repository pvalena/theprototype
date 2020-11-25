#!/bin/bash

set -e
bash -n "$0"

SRC_FPO_RPMS='https://src.fedoraproject.org/api/0/rpms/'

abort () {
  echo "Error:" "$@" >&2
  exit 1
}

[[ "$1" == '-d' ]] && {
  DEBUG="$1"
  shift
} ||:

[[ -n "$1" ]] && {
  REPO="$1"
  shift
  :
} || REPO="$(basename "`pwd`")"

[[ -n "$1" ]] && {
  USERNAME="$2"
  shift 2
  :
} || USERNAME=pvalena

[[ -n "$DEBUG" ]] && set -x && v='-v' || v=

O="$(curl -s $v "${SRC_FPO_RPMS}/$REPO/pull-requests?author=$USERNAME")"

echo "$O" | jq -r '.requests[].title' 2>/dev/null

I="$(echo "$O" | jq -r '.requests[].id' 2>/dev/null)"
[[ -n "$I" ]] \
  && echo "https://src.fedoraproject.org/rpms/$REPO/pull-request/$I"
