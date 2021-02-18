#!/bin/bash
#
# Usage: source the file
#     To be used for querying Pull Requests.
#
# Args - the following arguments are parsed from ARGV
#
#     -i            Select PR ID
#
#     -g            Filter with REGEXP.
#
#
# Defines - the following Env variables are defined:
#
#     $O            Output from the query.
#
#     $R            Object for jq to filter on (null or .repos[])
#
#     $G            Grep. Regexp for further filtering.
#
#     $REPO         The package repository name.
#
#     $USERNAME     Username to filter on.
#
#     yield         Method that encapsulates usage of the above, and you simply print the value.
#                   When used with filtering, grep is run with a title.
#                   The following is available when yielding: $id, $title
#
#

set -e
bash -n "$0"

SRC_FPO_RPMS='https://src.fedoraproject.org/api/0/rpms/'

abort () {
  echo "Error:" "$@" >&2
  exit 1
}

yield () {
  I="$(echo "$O" | jq -r "${R}.id" 2>/dev/null)"

  echo "$O" \
    | jq -r "${R}.title" 2>/dev/null \
    | while read t; do
        i="`head -n 1 <<< "$I"`"
        I="`tail -n +2 <<< "$I"`"

        grep -q "$G" <<< "$t" \
          && bash -c "
              id='$i'
              title='$t'
              USERNAME='$USERNAME'
              REPO='$REPO'
              $@
            "
      done
}

[[ "$1" == '-d' ]] && {
  DEBUG="$1"
  shift
  :
} ||:

[[ "$1" == '-g' ]] && {
  G="$2"
  shift 2
  :
} || G=

[[ "$1" == '-i' ]] && {
  ID="/$2"
  shift 2
  :
} || ID=

# Positional args
[[ -n "$1" ]] && {
  REPO="$1"
  shift
  :
} || REPO="$(basename "`pwd`")"

[[ -n "$1" ]] && {
  USERNAME="$1"
  shift
  :
} || USERNAME=pvalena

[[ -n "$DEBUG" ]] && set -x && v='-v' || v=

O="$(curl -s $v "${SRC_FPO_RPMS}${REPO}/pull-request${ID:-s}?author=${USERNAME}")"

[[ -z "$ID" ]] && R=".requests[]" || R=
:
