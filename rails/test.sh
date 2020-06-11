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

bash -n "$0" || exit 1

trap 'kill 0 ; exit 0' SIGTERM
trap 'kill 0 ; exit 0' SIGINT
trap 'kill 0 ; exit 0' SIGABRT

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

[[ '--' == "$1" ]] && shift

 #echo rubygem-{spring-watcher-listen,listen,rails,sqlite3,coffee-rails,sass-rails,uglifier,jquery-rails,turbolinks,jbuilder,therubyracer,sdoc,spring,byebug,web-console,io-console,bigdecimal} \
 # | xargs -n1 mock "$@" -n -qi

[[ "$d" ]] && set -x
[[ "$S" ]] && mck -scrub=all

[[ "$C" ]] || {
  mck -clean || die 'Clean failed'
  mck -init || die "Init failed"
}

[[ "$N" ]] || {
  mck -pm-cmd group install 'Ruby on Rails' || die 'group install failed'
}

[[ -n "$I" ]] && {
  mck i $I || die 'additional install failed'
}

mck -unpriv --chroot "set -xe ; cd && rm -rf app/"
sleep 0.1
mck -unpriv --chroot "set -xe ; cd && rails new app --skip-bundle --skip-spring --skip-test --skip-bootsnap --skip-webpacker --skip-javascript -f" || die "rails new failed"
sleep 0.1
mck -unpriv --chroot "set -xe ; cd ~/app && sed -i 's/\(gem..puma.\).*/\1/' Gemfile" || die "Gemfile edits failed"
sleep 0.1
mck -unpriv --chroot "set -xe ; cd ~/app && sed -i 's/\(gem..listen.\).*/\1/' Gemfile" || die "Gemfile edits failed"
sleep 0.1
mck -unpriv --chroot "set -xe ; cd ~/app && bundle install --local --without development test" || die "bundle install"
sleep 0.1
mck -unpriv --chroot "set -e  ; cd ~/app ; ( timeout 20 rails s puma &> rails.log & ) ; sleep 5 ; curl -s http://0.0.0.0:3000 | grep -q '<title>Ruby on Rails</title>' && rpm -q rubygem-rails && echo OK && exit 0 ; cat rails.log ; exit 1" || die '`rails server` failed'
sleep 0.1
