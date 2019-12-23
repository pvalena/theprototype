#!/bin/bash

set -ex
bash -n "$0"

SRC_FPO_RPMS_FORK='https://src.fedoraproject.org/api/0/fork'

TOKEN="`cat ~/.config/fedora`"

abort () {
  echo "$@" >&2
  exit 1
}

[[ -n "$1" ]] || abort 'Provide repo at least.'

while [[ -n "$1" ]]; do
  repo="$1"
  curl -s -X POST -H "Authorization: token $TOKEN" -d "repo=$repo&namespace=rpms&wait=1" "${SRC_FPO_RPMS_FORK}"
  shift
done
