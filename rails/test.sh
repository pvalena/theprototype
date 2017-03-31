#!/bin/bash
# Smoke test for Rails 5.0+
#
# test.sh [-h] [-d] [-t] [-c] [-s]
#	  -h 	print help
#	  -d 	debug mode
#   -t  enables repo 'updates-testing'
#   -c  do not scrub/clean/init mock
#   -s  skip scrubbing mock
#
#   Note that order of options matter.
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

 [[ '-h' == "$1" ]] && usage

 [[ '-d' == "$1" ]] && { Q= ; shift ; } || Q='-q'

 [[ '-t' == "$1" ]] && { shift ; T='--enablerepo=updates-testing' ; } || T=

[[ '-c' == "$1" ]] && shift || {
  [[ '-s' == "$1" ]] && shift || mock "$@" $Q $T --scrub=all

  mock "$@" $Q $T --clean && mock "$@" $Q $T --init || die "Init/clean failed"

}

 #echo rubygem-{spring-watcher-listen,listen,rails,sqlite3,coffee-rails,sass-rails,uglifier,jquery-rails,turbolinks,jbuilder,therubyracer,sdoc,spring,byebug,web-console,io-console,bigdecimal} \
 # | xargs -n1 mock "$@" -n -qi

 mock "$@" -n $Q $T --pm-cmd group install 'Ruby on Rails' || die 'group install failed'

 mock "$@" -n $Q $T --unpriv --chroot "cd && rails new app --skip-bundle" || die "rails new failed"

 mock "$@" -n $Q $T --unpriv --chroot "cd && cd app && sed -i \"/'puma'/,/'therubyracer'/ s/^/# /\" Gemfile && sed -i \"/'listen'/ s/'~> 3.0.5'/'~> 3.1.5'/\" Gemfile" || die "Gemfile edits failed"

 mock "$@" -n $Q $T --unpriv --chroot "cd && cd app && rails s" || die "rails s failed"
