#!/bin/bash
# Smoke test for Rails 5.0+
#
# test.sh [-h] [-c] [-s]
#   -s  skip scrubbing mock
#   -c  do not scrub/clean/init mock
#
#   Note that order of arguments matter
#
#   All other args will be passed to mock, e.g.:
#   -r  mock-config-x86_64.cfg
#

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

 [[ "-h" == "$1" ]] && usage

 [[ "$1" == "-c" ]] && shift || {
  [[ "$1" == "-s" ]] && shift || mock "$@" -q --scrub=all

  mock "$@" -q --clean && mock "$@" -q --init || die "Init/clean failed"

 }

 # TODO: use group install instead
 mock "$@" -n -qi rubygem-{spring-watcher-listen,listen,rails,sqlite3,coffee-rails,sass-rails,uglifier,jquery-rails,turbolinks,jbuilder,therubyracer,sdoc,spring,byebug,web-console,io-console,bigdecimal} || die "Install failed"

 mock "$@" -n -q --unpriv --chroot "cd && rails new app --skip-bundle" || die "rails new failed"

 mock "$@" -n -q --unpriv --chroot "cd && cd app && sed -i \"/'puma'/,/'therubyracer'/ s/^/# /\" Gemfile && sed -i \"/'listen'/ s/'~> 3.0.5'/'~> 3.1.5'/\" Gemfile" || die "Gemfile edits failed failed"

 mock "$@" -n -q --unpriv --chroot "cd && cd app && rails s" || die "rails s failed"
