#!/bin/bash
#
# ./whatrequires.sh [-a][-v][-d] GEM1 GEM2 GEM3
#   Looks up dependencies using `dnf repoquery` in 'rawhide*' repos.
#   You need to have `rawhide` repos installed.
#   Auto-fills rubygem(GEM) or rubygem-GEM.
#   Does lookup for both Requires and BuildRequires(`--arch=src`).
#   Outputs only entries with upper bound contraint(`<`).
#
#   ! Run it as a same user you run dnf(f.e. with sudo) !
#
#   Options; expected in alpabetic order:
#     -a  all entries (no debug output)
#     -d  debug output (with all entries)
#     -q  quieter output (upper limits only)
#     -v  verbose output (all constraints)
#

bash -n "$0"

abort () {
  echo -e "Error: $@" >&2
  exit 1
}

xdnf="dnf -q --disablerepo='*' --enablerepo='rawhide*'"
D=requires
C=what$D

[[ "$1" == '-a' ]] && { DEBUG=y ; shift ; } ||:
[[ "$1" == '-d' ]] && { DEBUG=y ; setx='set -x;' ; shift ; } ||:
[[ "$1" == '-q' ]] && { QUIET=y ; shift ; } ||:
[[ "$1" == '-v' ]] && { VERBO=y ; shift ; } ||:
[[ "${1:0:1}" != '-' ]] || abort "Invalid arg: $1"

for g in "$@"; do
  [[ -z "$QUIET" ]] && echo -e "\n--> $g"

  for a in '' --arch=src ; do
    for z in -$g "($g)"; do
      QR="$xdnf repoquery ${a} --${C} 'rubygem${z}'"
      bash -c "${setx}$QR 2>&1" || abort "Repoquery failed: \"$QR\"\n with:\n$O"
    done
  done \
  | rev | cut -d'-' -f3- | rev | sort -u \
  | while read p; do
    QR="$xdnf repoquery --${D} '$p' 2>&1"
    O="$(bash -c "${setx}$QR")" || abort "Repoquery failed: \"$QR\"\n with:\n$O"
    O="$(grep "${g}" <<< "$O")"

    # NOT Debug
    [[ -z "$DEBUG" ]] && {
      [[ -n "$VERBO" ]] && {
        O="$(grep '[><=]' <<< "$O")"
        :
      } || {
        O="$(grep '<' <<< "$O")"
      }
    }

    O="$(grep -v "^$" <<< "$O")"
    [[ -z "$O" ]] && continue

    # Debug + Non-debug
    [[ -z "$QUIET" ]] && {
      echo -e "${p}:\n$O\n"
      :
    } || {
      echo "${p}: `tr -s '\n' ' ' <<< "$O"`"
    }
  done
done
