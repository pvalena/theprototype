#!/bin/bash
#
# coprbld [-n]
#   -n  nobreak
#
# use ./reset.sh prior to this
# repos need to be prepared (Using gup.sh)
#

set -e
bash -n "$0"

d="`pwd`"
CRB="$(dirname "`dirname "$(readlink -e "$0")"`")/pkgs/cr-build.sh"
[[ -x "$CRB" ]]
set +e

[[ "$1" == '-n' ]] && {
  BREAK=
  shift
  :
} || BREAK=y

[[ "$1" == '-w' ]] && {
  W="$1"
  shift 2
  :
} || W=15

[[ -n "$1" ]] && {
  echo "Unknown arg: '$1'" >&2
  exit 2
}

while read x; do
  y="rubygem-${x}"

  cd "${d}/${y}" || {
    echo "Failed to cd: '$y'" >&2
    exit 1
  }

  [[ -r .built ]] && continue

  $CRB ruby-on-rails && {
    touch .built
    git push
    :
  } || {
    [[ -n "$BREAK" ]] && break
  }

  sleep "$W"

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
