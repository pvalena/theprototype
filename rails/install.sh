#!/bin/bash
#
# mock -q --clean
# mock -q --init
set -xe
bash -n "$0"

[[ -n "$1" ]] && {
  mar="-r $1"
  shift
} || mar=

mar="${mar} --old-chroot"

for s in {1..20}; do Err=
  while read z; do echo ; set -x ;
    mck i "$z" || Err=yes
    { set +x ;} &>/dev/null
  done < <(
    ls -d */result/*.rpm | grep -v '\.src.rpm$' | grep -v '\-doc'
  )
  [[ -z "$Err" ]] && break
done
