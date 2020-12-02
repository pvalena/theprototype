#!/bin/bash

set -e
bash -n "$0"

SRC_FPO_RPMS='https://src.fedoraproject.org/api/0/rpms/'

TOKEN="`cat ~/.config/fedora`"

abort () {
  echo "Error:" "$@" >&2
  exit 1
}

[[ -n "$1" ]] || exec "$0" "`basename "$PWD"`"

[[ "$1" == '-d' ]] && {
  DEBUG="$1"
  shift
  :
} ||:

[[ "$1" == '-i' ]] && {
  ID="$2"
  shift 2
  :
} || ID=

# Positional args
[[ -n "$1" ]] && {
  REPO="$1"
  shift
  :
} || REPO="$(basename "`pwd`")"

[[ -n "$ID" ]] || abort 'No ID specified.'

[[ -n "$DEBUG" ]] && set -x && v='-v' || v=

curl -s $v -X POST -H "Authorization: token $TOKEN" -d "wait=1" \
  "${SRC_FPO_RPMS}${REPO}/pull-request/${ID}/merge"
