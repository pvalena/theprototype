#!/bin/bash
set -xe
bash -n "$0"

[[ "$1" == '-w' ]] && {
  shift
  P="$1"
  shift

  while copr-cli status $P \
      | tee -a /dev/stderr \
      | grep -q running ; do
    sleep 300
  done
}

c="$1"
[[ -n "$c" ]]

x="${2}"
[[ -n "$x" ]] || x='fedora-rawhide-x86_64'

p="$(basename "$PWD")"
[[ -n "$p" ]]

rm *.src.rpm ||:
fedpkg --dist f31 srpm

{ set +xe ; } &>/dev/null

O="`copr-cli build $c *.src.rpm 2>&1 | tee /dev/stderr`" && R=0 || R=1

b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`"
[[ -n "$b" ]] || exit 1
grep -qE '^[0-9]*' <<< "$b" || exit 3

[[ -t 1 ]] && d=lss || d=cat

grep -q succeeded <<< "$O" || {
  for l in build root; do
    (
      echo "$O"
      curl -#Lk "https://copr-be.cloud.fedoraproject.org/results/pvalena/${c}/${x}/`printf "%08d" $b`-${p}/${l}.log.gz" \
        | zcat
    ) \
    | uniq | $d
  done
}

exit $R
