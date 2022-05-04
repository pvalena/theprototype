#!/usr/bin/bash

bash -n "$0" || exit 1

[[ "$1" == '-m' ]] && { M="$1"; shift; } || M=

while [[ -n "$1" ]]; do
  n="$1"
  shift

  r="$(grep '^Subject: ' "$n" | head -1 | cut -d' ' -f2-)"

  f="$(cut -d' ' -f1,2 <<< "$r" | grep '^\[PATCH [0-9]*\/[0-9]*')"

  [[ -n "$f" ]] && r="$(cut -d' ' -f3- <<< "$r")"

  d="$(basename "$PWD")"
  v="$(grep '^\s*Version:\s*' *.spec | tr -s '\t' ' ' | cut -d' ' -f2)"

  t="${d}-${v}-$(tr -s ' ' '-' <<< "$r").patch"

  echo $t

  [[ -n "$M" ]] && \
    mvi "$n" "$t"
done
