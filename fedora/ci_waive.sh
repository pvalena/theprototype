#!/usr/bin/env bash
#
# ./ci_waive.sh [-d] [-r EL] PACKAGE TESTCASE COMMENT
#

set -e

n=0
arg () {
  #local A="$(printf "%q" "$1")"
  A="$(sed -e 's/"/'\''/g'<<< "$1")"
  let "n += 1"
  [[ -n "$A" ]] || exit ${n:-1}

  echo "$A"
}

[[ "$1" == "-d" ]] && {
  set -x
  shift
}

[[ "$1" == "-r" ]] && {
  EL="$2"
  shift 2
  :
} || EL=9

PACKAGE="$(arg "$1")"
shift

TESTCASE="$(arg "$1")"
shift

COMMENT="$(arg "$1")"
shift

{ echo ; } 2>/dev/null

curl --negotiate -u: -X POST https://waiverdb.engineering.redhat.com/api/v1.0/waivers/ \
  -d "{\"subject_type\": \"brew-build\", \"subject_identifier\": \"${PACKAGE}\", \"testcase\": \"${TESTCASE}\", \"waived\": true, \"product_version\": \"rhel-${EL}\", \"comment\": \"${COMMENT}\"}"
