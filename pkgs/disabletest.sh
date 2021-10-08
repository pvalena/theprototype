#!/usr/bin/bash

set -xe
bash -n "$0"


N="`echo -e "\n"`"

# Test to match
M="${1}"
shift

# Where to append
W="${1}"
shift

while :; do
  Q="$(
    tail -n 30 < <(xzcat result/build.log.xz) \
      | grep -B 1 '^RPM build errors:$' \
      | head -1 | cut -d']' -f2 \
      | grep -E 'make: ***' \
      | tr -s ' ' '\n' \
      | grep 'make:$' \
      | sed -e 's/\(.*\)make:/\1/'
    )"

  [[ -n "$Q" ]] && {
    echo "gotit: $Q"
    grep -q "^${M}#test_" <<< "$Q" || break

    Q="$(cut -d'_' -f2- <<< "$Q")"

    sed -i "/${W}/ a\ \ ${Q} \\\\" *.spec

    clear
    gitd | cat

    sleep 300
  }
  echo notit
  sleep 30
done
