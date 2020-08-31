#!/bin/bash

set -e
bash -n "$0"

d="`pwd`"
GUP="$(dirname "`dirname "$(readlink -e "$0")"`")/gems/gup.sh"
[[ -x "$GUP" ]]
set +e

[[ "$1" == "-c" ]] && {
  shift
  :
} || {
  rm */*.src.rpm */*.txz
}

[[ "$1" == '-n' ]] && {
  BREAK=
  shift
  :
} || {
  BREAK=y
}

[[ "$1" == '-w' ]] && {
  W="$1"
  shift 2
  :
} || W=15

[[ -n "$1" ]] && {
  echo "Unknown arg: '$1'" >&2
  exit 2
}

mkdir -p copr-r8-ruby-on-rails
git clone https://github.com/rails/rails.git
bash -c "
  set -xe
  cd rails
  git pull
  [[ -r rails ]] || ln -s . rails
  ls -d a*/ r*/ | xargs -i bash -c \"echo; cd '{}'; pwd; set -x; [[ -r rails ]] || ln -s .. rails\"
  :
" || exit 2

while read x; do
  y="rubygem-${x}"

  cd "${d}/${y}" || {
    echo "Failed to cd: '$y'" >&2
    exit 1
  }

  [[ -r .built ]] && continue

  set -x

  git checkout rebase

  ln -s ../rails .

  sed -i 's/^%bcond_with bootstrap/%bcond_without bootstrap/' *.spec

  cp -n ../rubygem-activesupport/rails-*-tools.txz .

  $GUP -b ruby-on-rails -c -j -x -y && {
    touch .built
    git push
    :
  } || {
    [[ -n "$BREAK" ]] && break
  }

  sleep "$W"
  { set +x; } &>/dev/null

done <<EOLX
activesupport
activejob
activemodel
rails
railties
actionview
actionpack
activerecord
actionmailer
actionmailbox
actiontext
actioncable
activestorage
EOLX

exit 1

ls -d rubygem-* | \
  xargs -i bash -c "cd '{}' && set -x && for x in \$(spectool -A *.spec | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev | grep -vE '^(binstub|macros\.vagrant|macros|rubygems\.)' | grep -vE '(\.rb)$') ; do echo \"SHA512 (\$x) = \$(sha512sum \"\$x\" | cut -d' ' -f1)\" ; done > sources && fedpkg commit -c && git remote add pvalena 'ssh://pvalena@pkgs.fedoraproject.org/forks/pvalena/rpms/{}' && { gitc rebase || gitc -b rebase } && gitf pvalena && gitu -uf pvalena rebase || exit 255 ; gits ; gith"
