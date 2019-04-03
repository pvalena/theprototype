#!/bin/zsh

set -e

f='build.log'
r=

gitb -u "origin/`gitb | grep '^*' | cut -d' ' -f2-`" \
  || r='--release master'

[[ "$1" == '-c' ]] && {
  rm *.src.rpm
  bash -c "fedpkg $r srpm"
}

[[ -r "`ls *.src.rpm | head -1`" ]] || exit 1

set +e

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
