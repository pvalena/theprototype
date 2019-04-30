#!/bin/bash
# Smoke test for Rails 5.0+
#
# ./test.sh [options]
#   -c  do not clean/init mock
#	  -h 	print help
#   -i  additionall install
#   -n  no comps install
#   -s  start anew = scrub mock
#   -t  enables repo 'updates-testing'
#
# !!! Options have to be specified in alphabetical order !!!
#
# All other args will be passed to mock(specify '--' to force delimeter), e.g.:
#     -r  mock-config-x86_64.cfg
#     -v
#     -q
#

bash -n "$0" || exit 1

trap 'kill 0 ; exit 0' SIGTERM
trap 'kill 0 ; exit 0' SIGINT
trap 'kill 0 ; exit 0' SIGABRT

MAR='--bootstrap-chroot --new-chroot'

die () {
  local ERR
  [[ "$1" ]] && ERR="$1" || ERR="Unknown"

  ERR="Error: $ERR!"
  echo "$ERR" 1>&2
  exit 1
}

usage () {
  awk '{if(NR>1)print;if(NF==0)exit(0)}' < "$0" | sed '
    s|^#[   ]||
    s|^#$||
  ' | ${PAGER-more}

  exit 0
}

[[ '-c' == "$1" ]] && {
  C="$1"
  shift
} || C=

[[ '-h' == "$1" ]] && usage

[[ '-i' == "$1" ]] && {
  shift
  I="$1"
  shift
} || I=

[[ '-n' == "$1" ]] && { N="$1" ; shift ; } || N=

[[ '-s' == "$1" ]] && { S="$1" ; shift ; } || S=

[[ '-t' == "$1" ]] && { shift ; T='--enablerepo=updates-testing' ; } || T=

[[ '-v' == "$1" ]] && { shift ; MAR="-v $MAR" ; } ||:

[[ '--' == "$1" ]] && shift

 #echo rubygem-{spring-watcher-listen,listen,rails,sqlite3,coffee-rails,sass-rails,uglifier,jquery-rails,turbolinks,jbuilder,therubyracer,sdoc,spring,byebug,web-console,io-console,bigdecimal} \
 # | xargs -n1 mock "$@" -n -qi

[[ "$d" ]] && set -x
[[ "$S" ]] && mock $MAR "$@" $T --scrub=all

[[ "$C" ]] || {
  mock $MAR "$@" $T --clean || die 'Clean failed'
  mock $MAR "$@" $T --init || die "Init failed"
}

[[ "$N" ]] || {
  mock $MAR "$@" -n $T --pm-cmd group install 'Ruby on Rails' || die 'group install failed'
}

[[ -n "$I" ]] && {
  mock $MAR "$@" -n $T -i $I || die 'additional install failed'
}

mock $MAR "$@" -n $T --unpriv --chroot "set -x ; cd && rm -rf app/"
sleep 0.1

mock $MAR "$@" -n $T --unpriv --chroot "set -x ; cd && rails new app --skip-bundle --skip-spring --skip-test --skip-bootsnap -f" || die "rails new failed"
sleep 0.1

#mock $MAR "$@" -n $T --unpriv --chroot "cd && cd app && sed -i '/chromedriver-helper/ s/^/#/g' Gemfile" || die "Gemfile edits failed"
#sleep 0.1

mock $MAR "$@" -n $T --unpriv --chroot "set -x ; cd ~/app || exit 7 ; ( timeout 20 rails s puma &> rails.log & ) ; sleep 5 ; curl -s http://0.0.0.0:3000 | tee -a /dev/stderr | grep -q '<title>Ruby on Rails</title>' && rpm -q rubygem-rails && echo OK && exit 0 ; cat rails.log ; exit 1" || die '`rails server` failed'
sleep 0.1
