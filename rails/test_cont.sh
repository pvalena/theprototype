#!/bin/bash

set -xe
bash -n "$0"

debug='head'
rm='--rm'
dline=
s='s'

[[ "$1" == '-d' ]] && {
  shift
  debug='cat'
  rm=
  dline='echo " =================== "'
  s=
}||:

[[ "$1" == '-g' ]] && {
  shift
  gem="$1"
  shift
}||:

[[ "$1" == '-l' ]] && {
  shift
  blocal='--local'
}||:

read -r -d '' BSC << EOS||:
  set -xe
  ruby -v
  gem list
  gem env

  which rails || gem install rails
  export GEM_HOME=\$( ruby -e 'puts Gem.user_dir' )

  # The bellow can fail, but just continue until log
  { set +e ; }&>/dev/null

  rails new app --skip-bundle --skip-spring --skip-test --skip-bootsnap -f
  cd app || exit 1

  [[ -z "$gem" ]] || echo "gem '$gem'" >> Gemfile

  rm Gemfile.lock
  bundle install --path vendor/bundle -r 3 $blocal

  $dline

  bash -c "set -x ; timeout 60 rails server puma -P rails.pid &>rails.log" &

  sleep 45
  $dline

  curl -Lk$s 'http://0.0.0.0:3000' | $debug
  sleep 20
  $dline

  cat rails.log
EOS

exec podman run $rm -it "$1" bash -c "$BSC"
