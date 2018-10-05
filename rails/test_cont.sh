#!/bin/bash

set -xe
bash -n "$0"

[[ "$1" == '-d' ]] && {
  shift
  debug='| tee -a /dev/stderr'
}||:

[[ "$1" == '-g' ]] && {
  shift
  gem="$1"
  shift
}||:

[[ "$1" == '-l' ]] && {
  shift
  bundle='--local'
}||:

read -r -d '' BSC << EOS||:
  set -xe
  which rails || gem install rails
  export GEM_HOME=\$( ruby -e 'puts Gem.user_dir' )
  rails new app
  cd app

  [[ -n "$gem" ]] && echo "gem '$gem'" >> Gemfile
  rm Gemfile.lock
  bundle $bundle

  ( rails s ; ) &
  sleep 3

  curl -Lks http://0.0.0.0:3000 $debug | head
EOS

exec docker run --rm -it "$1" bash -c "$BSC"
