#!/bin/bash
set -e
bash -n "$0"
set +e

d="`pwd`"
while read x; do
  cd "$d" && cd "rubygem-${x}" && echo ">> $x" && {
    [[ -r .built ]] && continue;
    rm *.src.rpm ; rm sources ; fedpkg --dist f30 srpm&&copr-cli build ruby-on-rails *.src.rpm&&touch .built
  }
done <<EOLX
activesupport
activejob
activemodel
activerecord
actionmailer
actioncable
rails
actionview
actionpack
railties
EOLX
