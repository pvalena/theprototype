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
      | grep -q running ; do
    sleep 300
  done
}||:

n="$1"
[[ -n "$n" ]]

x="${2}"
[[ -n "$x" ]] || x='fedora-rawhide-x86_64'

p="$(basename "$PWD")"
[[ -n "$p" ]]

ls *.src.rpm &>/dev/null || fedpkg --dist f31 srpm

{ set +xe ; } &>/dev/null

O="`copr-cli build $n *.src.rpm 2>&1 | tee /dev/stderr`" && R=0 || R=1

b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`"
[[ -n "$b" ]] || exit 1
grep -qE '^[0-9]*' <<< "$b" || exit 3

[[ -t 1 ]] || d=cat
[[ -t 0 ]] || d=cat

grep -q succeeded <<< "$O" || {
  for l in build root; do
    (
      echo "$O"
      curl -#Lk "https://copr-be.cloud.fedoraproject.org/results/pvalena/${n}/${x}/`printf "%08d" $b`-${p}/${l}.log.gz" \
        | zcat
    ) \
    | uniq | $d
  done
}

exit $R
