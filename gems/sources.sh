#!/usr/bin/bash

set -e
bash -n "$0"

die () {
  echo
  warn "Error" "$1"
  exit 1
}

warn () {
  echo
  echo "--> $1: $2!" >&2
}

ask () {
  local r=
  local s=
  [[ "$1" == '-s' ]] && s="$1" && shift

  for x in {1..10}; do
    echo
    [[ -n "$YES" ]] && {
      echo ">> $@. "
      return 0
      :
    } || {
      read -n1 -p ">> $@? " r

      grep -qi '^y' <<< "${r}" && {
        clear
        return 0
        :
      }||:

      grep -qi '^n' <<< "${r}" && {
        break
        :
      }||:
    }
  done

  [[ -n "$s" ]] || die 'User quit'
  return 1
}

X="`ls *.spec`"
gcom="git|cd|tar"
YES=

[[ -z "$1" ]] || {
  X="$1"
  shift
}

[[ -z "$1" ]] || {
  gcom="$1"
  shift
}

[[ -z "$1" ]] || {
  YES="$1"
  shift
}

find -L -mindepth 2 -maxdepth 3 -type d -name .git -exec bash -c "cd '{}/..'; git fetch origin" \; ||:
cmd="$(
    grep -B 20 '^Source' "$X" | grep '^#' | cut -d'#' -f2- | grep -E "^\s*(${gcom})\s*" \
      | xargs -i echo -n "; {}" \
      | xargs -i echo "set -x{} && echo Ok || exit 1"
  )"
[[ -z "$cmd" ]] || {
  echo
  echo "\$cmd: $cmd"
  ask 'execute $cmd'
  bash -c "$cmd" || die 'Failed to execute $cmd'
}
find -L -mindepth 2 -maxdepth 3 -type f -name '*.txz' -o -name '*.tgz' | xargs -ri mv -v "{}" .

for x in `spectool -S "$X" | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev` ; do
  echo "SHA512 ($x) = `sha512sum "$x" | cut -d' ' -f1`"
done > sources
