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
} || BREAK=y

while read x; do
  y="rubygem-${x}"

  cd "${d}/${y}" || {
    echo "Failed to cd: '$y'" >&2
    exit 1
  }

  [[ -r .built ]] && continue

  set -o pipefail
  bash -c "$CRB -s ruby-on-rails || exit 1" && {
    echo "$?"
    touch .built
    :
  } || {
    [[ -n "$BREAK" ]] && break
  }

done <<EOLX
activesupport
activejob
activemodel
activerecord
rails
actionview
actionpack
actionmailer
actioncable
railties
activestorage
EOLX
