#!/bin/bash

set -e
bash -n "$0"

abort () {
  echo "Error:" "$@" >&2
  exit 1
}

BZ_REST="https://bugzilla.redhat.com/rest/"

# ARGS
[[ "$1" == "-d" ]] && {
  set -x
  shift
  :
} ||:

[[ -n "$1" ]] && {
  component="$1"
  shift
  :
} || component="`basename "$PWD"`"

[[ -n "$1" ]] && {
  product="$1"
  shift
  :
} || product='Fedora'

[[ -n "$1" ]] && {
  creator="$1"
  shift
  :
} || creator='upstream-release-monitoring'

[[ -n "$1" ]] && {
  summary="$1"
  shift
  :
} || summary="${component}+is+available"

for status in ASSIGNED NEW; do

  QUERY="product=${product}&component=${component}&creator=${creator}&summary=${summary}&status=${status}"

  R=0
  OUT="$(
    curl -s "${BZ_REST}bug?${QUERY}" \
      | jq -r '.bugs[].id'
  )" || R=1
  [[ $R -eq 0 ]] || abort 'Curl failed; stdout:' "$OUT"

  [[ -n "$OUT" ]] && break
done

[[ -z "$OUT" ]] || echo "$OUT"
