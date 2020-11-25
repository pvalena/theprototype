#!/bin/bash

set -e
bash -n "$0"

# CONFIG
SRC_FPO_RPMS='https://src.fedoraproject.org/api/0'
TOKEN="`cat ~/.config/fedora`"

# METHODS
abort () {
  echo "Error:" "$@" >&2
  exit 1
}

# ARGS
[[ "$1" == '-d' ]] && {
  DEBUG="$1"
  shift
} ||:

[[ -n "$1" ]] || abort 'You need to provide repo.'
REPO="$1"
shift

[[ -n "$1" ]] || abort 'You need to provide title.'
TITLE="$1"
shift

[[ -n "$1" ]] || abort 'You need to provide comment.'
COMMENT="$1"
shift

[[ -n "$1" ]] && {
  USERNAME="$2"
  shift 2
  :
} || USERNAME=pvalena

[[ -n "$1" ]] && {
  BRANCH_FROM="$2"
  shift 2
  :
} || BRANCH_FROM=rebase

[[ -n "$1" ]] && {
  BRANCH_TO="$2"
  shift 2
  :
} || BRANCH_TO=master

# MAIN
getpr="$(dirname "$0")/get_pr.sh"

[[ -x "$getpr" ]] || abort "Could not find 'get_pr.sh'"

PR="$($getpr "$REPO")" ||:

[[ -z "$PR" ]] || abort "PR already exists: $PR"

[[ -n "$DEBUG" ]] && set -x && v='-v' || v=

curl $v -s -X POST -H "Authorization: token $TOKEN" -d \
  "title=${TITLE}&branch_to=${BRANCH_TO}&repo_from_namespace=rpms&repo_from_username=${USERNAME}&repo_from=${REPO}&branch_from=$BRANCH_FROM&initial_comment=$COMMENT" \
  "${SRC_FPO_RPMS}/rpms/$REPO/pull-request/new"