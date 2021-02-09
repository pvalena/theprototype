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

[[ '-t' == "$1" ]] && { shift ; mar="$mar --enablerepo=updates-testing" ; }

[[ -z "$1" ]] || die "Unknown arg: $1"

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

for cmd in \
  "cd; [[ -d ~/app ]] || exit 0; rm -rf ~/app/" \
  "rails new app --skip-bundle --skip-test --skip-bootsnap --skip-webpacker --skip-javascript -f" \
  "sed -i \"s/\(gem .puma.\).*/\1/\" Gemfile" \
  "sed -i \"s/\(gem .listen.\).*/\1/\" Gemfile" \
  "sed -i \"/gem .sass-rails./ d\" Gemfile" \
  "sed -i \"/gem .rack-mini-profiler./ d\" Gemfile" \
  "bundle config set deployment false" \
  "bundle config set without test" \
  "bundle install -r 3 --local" \
  "( timeout 20 rails s -u puma &> rails.log & ) ; sleep 5 ; curl -s http://0.0.0.0:3000 | grep -q \"<title>Ruby on Rails</title>\" && rpm -q rubygem-rails && echo OK && exit 0 ; cat rails.log ; exit 1"
do
  bash -c -n "$cmd" || die "Invalid command syntax: $cmd"
  lcmd="set -xe; cd ~/app || cd; $cmd || { { set +xe; } &>/dev/null; grep -vE '^#' Gemfile | grep -vE '^$'; gem list | grep '^rails '; exit 1; }"
  bash -c -n "$lcmd" || die "Invalid command syntax: $lcmd"

  mck -unpriv --shell "$lcmd" || die "Command failed: '$cmd'"
  sleep 0.1
done

#  "bundle config set path vendor" \
