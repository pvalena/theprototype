#!/bin/zsh

set -e
bash -n "$0"

i=''

for c in {2..12}; do
  X="`podman images | tail -n +$c | head -1`"

  [[ -n "$X" ]] || {
    f="$(ls *.tar.gz | head -1)"
    [[ -n "$f" ]]
    podman load < "$f"

    exec "$0" "$@"
  }

  [[ -n "$X" ]]

  i="$(tr -s '\t' ' ' <<< "$X" | cut -d' ' -f3)"

  echo "$X"
  read -q "z?Use '$i'? " && break || exit 1
done

[[ -n "$i" ]]

podman inspect "$i"

exec ./test_cont.sh "$@" "$i"
