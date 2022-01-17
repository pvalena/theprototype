#!/bin/bash

set -xe
bash -n "$0"

debug='head'
dline=
s='s'
scl=
dep="ruby-devel make redhat-rpm-config gcc-c++ sqlite3-devel"

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

[[ "$1" == '-s' ]] && {
  scl="$2"
  shift 2
}||:

read -r -d '' BSC << EOS||:
  set -xe
  export http_proxy=''
  export PATH="\${PATH}:/builddir/bin"

  [[ -z "$scl" ]] ||  . scl_source enable $scl||:

  ruby -v
  gem list
  gem env

  rpm -q $dep \
    || dnf install -y $dep

  which rails || \
    gem install rails

  export GEM_HOME=\$( ruby -e 'puts Gem.user_dir' )

  # The bellow can fail, but just continue until log
  { set +e ; }&>/dev/null

  rails new app --skip-bundle --skip-test --skip-bootsnap --skip-webpacker --skip-javascript -f
  #rails new app --skip-bundle --skip-spring --skip-test --skip-bootsnap --skip-webpacker --skip-javascript -f
  cd app || exit 1

  [[ -z "$gem" ]] || echo "gem '$gem'" >> Gemfile

  rm Gemfile.lock
  bundle config set deployment false path vendor without 'development:test'
  bundle config set deployment false
  bundle config set without test

  bundle platform
  bundle lock --add-platform x86_64-linux
  bundle lock --add-platform ruby || exit 2

  bundle install -r 3 $blocal || exit 3

  $dline

  #bundle exec rails webpacker:install

  $dline

  bash -c "set -x ; timeout 60 rails server -u puma -P rails.pid &>rails.log" &

  sleep 45

  PID="\$(cat rails.pid)" && {
    grep '^[0-9]' <<< "\$PID" || exit 1

    $dline
    curl -Lk$s 'http://0.0.0.0:3000' | $debug
    sleep 20
  }||:

  $dline

  cat rails.log
EOS

bash -n <<< "$BSC"

exec mck -unpriv --shell --enable-network "$BSC"

