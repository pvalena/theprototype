#!/bin/bash
set -xe
bash -n "$0"

d=lss
[[ "$1" == '-c' ]] && d=cat && shift
[[ "$1" == '-s' ]] && {
  rm *.src.rpm ||:
  shift
}||:

[[ "$1" == '-w' ]] && {
  shift
  P="$1"
  shift

  while copr-cli status $P \
      | tee -a /dev/stderr \
      | grep -qv succeeded ; do
    sleep 300
  done
}||:

n="$1"
[[ -n "$n" ]]

x="${2}"
[[ -n "$x" ]] || x='fedora-rawhide-x86_64'

p="$(basename "$PWD")"
[[ -n "$p" ]]

l="`readlink -e "../copr-r8-${n}"`"
[[ -n "$l" && -d "$l" ]]

f="${l}/${p}.log"
touch "$f"

ls *.src.rpm &>/dev/null || {
  fedpkg --dist f31 srpm || {
    echo "Warning: modifying spec file..." >&2
    sed -i 's/^Recommends: /Requires: /' *.spec
    sed -i '/^Suggests: / s/^/#/' *.spec
    fedpkg --dist f31 srpm
  }
}

{ set +xe ; } &>/dev/null
date -Isec

O="`copr-cli build $n *.src.rpm 2>&1 | tee /dev/stderr`" && R=0 || R=1

b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`"
[[ -n "$b" ]] || exit 1
grep -qE '^[0-9]*' <<< "$b" || exit 3

[[ -t 1 ]] || d=cat
[[ -t 0 ]] || d=cat

grep -q succeeded <<< "$O" || {
  (
    echo "$O"
    for l in root build; do
      u="https://copr-be.cloud.fedoraproject.org/results/pvalena/${n}/${x}/`printf "%08d" $b`-${p}/${l}.log.gz"
      echo -e "\n > $u" >&2
      curl -sLk "$u" | zcat | uniq
    done

  ) 2>&1 | tee "$f" | $d
}

exit $R
