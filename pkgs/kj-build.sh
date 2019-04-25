#!/bin/bash

set -xe
bash -n "$0"
f='build.log'
l='--release'

srpm () {
  local x=
  [[ -n "$1" ]] && x="$l $1"
  bash -c "fedpkg $x srpm" && return 0
  return 1
}

[[ "$1" == '-c' ]] && CS=y && shift

r="$1"
[[ -n "$r" ]] || {
  r="`gitb | grep '^*' | cut -d' ' -f2-`"
  grep -q '^rebase-' <<< "$r" && r="`cut -d'-' -f2- <<< "$r"`"
}

[[ -z "$CS" && -n "`ls *.src.rpm`" ]] || {
  rm *.src.rpm ||:

  c=
  for t in "$r" '' 'master'; do
    srpm "$t" && c="$t" && break

    [[ -z "$1" ]] || exit 5
  done
  r="$c"
}

[[ -n "$r" ]] && r="$l $r"

[[ -n "`ls *.src.rpm`" ]] || exit 6

set +xe

bash -c "fedpkg $r scratch-build --srpm *.src.rpm" 2>&1 \
  | tee -a /dev/stderr \
  | grep 'buildArch' \
  | grep -E '(FAILED|closed)' \
  | tr -s ' ' \
  | cut -d' ' -f1-2 \
  | tr -s ' ' '\n' \
  | grep -E '^[0-9]+$' \
  | sort -u \
  | while read b; do
      z="`rev <<< "$b" | cut -c -4 | rev`"
      let 'z=z+0'
      rm "$f"
      fastdown "https://kojipkgs.fedoraproject.org/work/tasks/$z/$b/$f"
      lss "$f"
   done
