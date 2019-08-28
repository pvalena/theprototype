#!/bin/bash

set -xe
bash -n "$0"
mkdir -p result
f1='result/root.log'
f2='result/build.log'
l='--release'

srpm () {
  local x=
  [[ -n "$1" ]] && x="$l $1"
  bash -c "fedpkg $x srpm" && return 0
  return 1
}

d=lss
[[ "$1" == '-c' ]] && d=cat && shift
[[ "$1" == '-s' ]] && S=y && shift

r="$1"
[[ -n "$r" ]] || {
  r="`gitb | grep '^*' | cut -d' ' -f2-`"
  grep -q '^rebase-' <<< "$r" && r="`cut -d'-' -f2- <<< "$r"`"
  grep -q '^rebase$' <<< "$r" && r="master"
}

[[ -z "$S" && -n "`ls *.src.rpm`" ]] || {
  rm *.src.rpm ||:

  for i in 0 1; do
    # $r already specified
    [[ -n "$1" ]] && {
      srpm "$r" && break
      :
    } || {
      s=
      for t in "$r" '' 'master'; do
        srpm "$t" && {
          s="$t"
          break
        }||:
      done

      # success
      [[ -z "$s" ]] || {
        r="$s"
        break
      }
    }

    # Failed
    [[ "$i" -eq 0 ]] || exit 7

    # Try without richdeps
    sed -i 's/^Recommends: /Requires: /' *.spec
    sed -i '/^Suggests: / s/^/#/' *.spec
  done
}

[[ -n "$r" ]] && r="$l $r"

[[ -n "`ls *.src.rpm`" ]] || exit 6

[[ -t 1 ]] || d=cat
[[ -t 0 ]] || d=cat

{ set +xe ; } &>/dev/null
date -Isec

bash -c "fedpkg $r scratch-build --srpm *.src.rpm" 2>&1 \
  | tee -a /dev/stderr \
  | grep 'buildArch' \
  | grep -E '(FAILED|closed)' \
  | tr -s ' ' \
  | cut -d' ' -f1-2 \
  | tr -s ' ' '\n' \
  | grep -E '^[0-9]+$' \
  | sort -u \
  | head -1 \
  | while read b; do
      sleep 1
      z="`rev <<< "$b" | cut -c -4 | rev | sed 's/^0*//'`"
      for f in "$f1" "$f2"; do
        rm "$f"
        fastdown -O "$f" "https://kojipkgs.fedoraproject.org/work/tasks/$z/`printf "%08d" $b`/`cut -d'/' -f2 <<< "$f"`"
      done
      bash -c "$d '$f2' '$f1'"
   done
exit 0
###########################################################
#             EXITED
###########################################################

# TODO: adopt one approach

O="`copr-cli build $c *.src.rpm 2>&1 | tee /dev/stderr`" && R=0 || R=1

b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`"
[[ -n "$b" ]] || exit 1
grep -qE '^[0-9]*' <<< "$b" || exit 3

[[ -t 1 ]] && d=lss || d=cat
[[ -t 0 ]] || d=cat

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
