#!/usr/bin/bash

set -e
bash -n "$0"
cd "$(dirname "$0")"

gname () {
  local A="$1"
  local Z
  shift
  while [[ -n "$1" ]]; do
    Z="$(basename -s ".${1}" "$(grep -iE "\s*\.${1}" <<< "$A")")"

    [[ -n "$Z" ]] && break

    shift
  done

  echo "$Z"
}

[[ "$1" == '-d' ]] && set -x

mkdir -p tmp
cd tmp

while A="$(grep -v ^$)"; do
  N="`gname "$A" jpg jpeg JPG JPEG PNG png`"
  [[ -n "$N" ]] || break

  echo -en "\n--> ${N}: "

  [[ -r "$N" ]] && break
  echo "$A" > "$N"

  ../count.sh "$N" | cut -d' ' -f2
done
