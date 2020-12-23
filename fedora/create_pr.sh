#!/bin/bash

set -e
bash -n "$0"

# METHODS
abort () {
  echo "Error:" "$@" >&2
  exit 1
}

# VARS
myd="`dirname "$(readlink -e "$0")"`"
get="${myd}/get_pr.sh"
[[ -x "$get" ]] || abort "Could not find 'get_pr.sh'."

# CONFIG
SRC_FPO_RPMS='https://src.fedoraproject.org/api/0'
TOKEN="`cat ~/.config/fedora`"

# ARGS
[[ "$1" == '-d' ]] && {
  DEBUG="$1"
  shift
  :
} || DEBUG=

[[ "$1" == '-f' ]] && {
  FORCE="$1"
  shift
  :
} || FORCE=

[[ "$1" == '-g' ]] && {
  GEN="$1"
  shift
  :
} || GEN=


[[ -n "$1" ]] && {
  REPO="$1"
  shift
  :
} || {
  [[ -n "$GEN" ]] \
    && REPO="`basename $PWD`" \
    || abort 'You need to provide repo.'
}

[[ -n "$1" ]] && {
  TITLE="$1"
  shift
  :
} || {
  [[ -n "$GEN" ]] \
    && TITLE="`gith --oneline | head -1 | cut -d' ' -f2-`" \
    || abort 'You need to provide title.'
}

[[ -n "$1" ]] && {
  COMMENT="$1"
  shift
  :
} || {
  [[ -n "$GEN" ]] \
    && COMMENT="`git show --stat | tail -n +6 | head -n -3`" \
    || abort 'You need to provide comment.'
}

[[ -n "$1" ]] && {
  USERNAME="$1"
  shift
  :
} || USERNAME=pvalena

[[ -n "$1" ]] && {
  BRANCH_FROM="$1"
  shift
  :
} || BRANCH_FROM="`gitb | grep '^* ' | cut -d' ' -f2-`"

[[ -n "$1" ]] && {
  BRANCH_TO="$1"
  shift
  :
} || BRANCH_TO='master'

# MAIN
getpr="$(dirname "$0")/get_pr.sh"

[[ -x "$getpr" ]] || abort "Could not find 'get_pr.sh'"

PR="$($getpr "$REPO")" ||:

[[ -z "$PR" ]] || {
  m="PR already exists: $PR"

  [[ -n "$FORCE" ]] \
    && echo "Warning: $m" \
    || abort "$m"
}

[[ -n "$DEBUG" ]] && set -x && v='-v' || v=

curl $v -s -X POST -H "Authorization: token $TOKEN" -d \
  "title=${TITLE}&branch_to=${BRANCH_TO}&repo_from_namespace=rpms&repo_from_username=${USERNAME}&repo_from=${REPO}&branch_from=$BRANCH_FROM&initial_comment=$COMMENT" \
  "${SRC_FPO_RPMS}/rpms/$REPO/pull-request/new"

$get
