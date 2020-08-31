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

[[ -n "$1" ]] || abort 'You need to provide repo.'
REPO="$1"
shift

[[ -n "$1" ]] && {
  USERNAME="$2"
  shift 2
  :
} || USERNAME=pvalena

[[ -n "$DEBUG" ]] && set -x && v='-v' || v=

curl -s $v "${SRC_FPO_RPMS}/$REPO/pull-requests?author=$USERNAME" \
  | jq -r '.requests[].title'
