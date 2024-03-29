#!/bin/bash
#
# coprbld [-n]
#
#   -d        debug mode
#
#   -n        nobreak
#
#   -w S      Time to wait (passed to coprbld) after an upgrade. (Default: 15)
#             For availability in COPR repo.
#
# You need to remove `.build` files prior to this.
# Also repos need to be prepared (using upgrade.sh).
#

set -e
bash -n "$0"

d="`pwd`"
CRB="$(dirname "`dirname "$(readlink -e "$0")"`")/pkgs/cr-build.sh"
[[ -x "$CRB" ]]
set +e

[[ "$1" == '-d' ]] && {
  set -x
  shift
  :
}

[[ "$1" == '-n' ]] && {
  BREAK=
  shift
  :
} || BREAK=y

[[ "$1" == '-w' ]] && {
  W="$2"
  shift 2
  :
} || W=30

[[ -n "$1" ]] && {
  CRR="$1"
  shift
  :
} || CRR='ruby-on-rails'

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

  $CRB "$CRR" && {
    touch .built
    #git checkout rebase && \
    #git push
    :
  } || {
    [[ -n "$BREAK" ]] && exit 1
  }

  # Do not wait on the last run
  [[ "$x" == 'actioncable' ]] || sleep "$W"

done <<EOLX
rails
activesupport
activejob
activemodel
railties
actionview
actionpack
activestorage
activerecord
actionmailer
actionmailbox
actiontext
actioncable
EOLX

echo DONE

exit 0
