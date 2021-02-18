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
  DEBUG=y
  :
} || DEBUG=

u="$1"
[[ -n "$u" ]] || u="$USER"
[[ -n "$u" ]] || abort 'No username specified'

for i in {1..1000}; do
  URL="${SRC_FPO_API}/projects?username=$u&namespace=rpms&fork=0&short=1&perpage=100&page=$i"

  [[ -n "$DEBUG" ]] && echo "$URL" >&2

  R="$(curl -s "$URL" | jq -r '.projects[].name')" \
    || abort "Curl / jq failed for URL: '$URL'"

  [[ -z "$R" ]] && exit 0
  echo "$R"
done
