#!/usr/bin/bash
#
# ./rebuild.sh [-c][-n][-s] TARGET SOURCE_BRANCH DESTINATION_BRANCH
#
#   -c  Skip setting up repositories, do only bootstrap ones.
#       This is more reliable than internal '.continue' locking mechanism.
#   -l  Only local changes (no push etc.).
#   -s  Skip modifications (merge), run only builds.
#
#

set -e
bash -n "$0"
set +e

die () {
  { set +x ; } &>/dev/null
  echo "$@" >&2
  exit 1
}

delim () {
  [[ -n "$Y" ]] && return 0
  local r
  { set +x ; } &>/dev/null
  echo
  read -n1 -p "--> Continue? " r
  echo
  grep -i '^y' <<< "$r" || die 'User abort!'
  set -x
  clear
}

# CONST

# starting folders
ST=13

# bootstrap
BS="actionview railties actionpack activemodel activestorage"

# total folders
TT=18

# ARGS

[[ '-c' == "$1" ]] && { C="$1" ; shift ; } || C=
[[ '-f' == "$1" ]] && { F="$1" ; shift ; } || F=
[[ '-l' == "$1" ]] && { L="$1" ; shift ; } || L=
[[ '-s' == "$1" ]] && { S="$1" ; shift ; } || S=
[[ '-y' == "$1" ]] && { Y="$1" ; shift ; } || Y=

TG="$1"
shift
[[ -z "$TG" ]] && die "Target (sidetag) missing: $TG"

SB="${1:-pvalena/rebase}"
shift

DB="${1:-origin/rawhide}"
shift

[[ -z "$1" ]] || die "Unknown arg: $1"

# fedora NR
FX="$(cut -d'-' -f1 <<< "$TG" | grep -E 'f[0-9]*' | cut -d'f' -f2- | grep -E '^[0-9]*$')"
[[ -z "$FX" ]] && die "Could not detect fedora version from target: $TG"

clear
set -xe

[[ -n "$S" ]] || {
  : ">>> Remove boostrap folders?"
  delim
  for a in $BS; do
    rm -rf rubygem-${a}-bs &>/dev/null
  done

  [[ `ls -d rubygem-*/ | wc -l` -eq $ST ]] \
    || die "Invalid initial number of folders: `ls`"
  clear

  [[ -n "$C" ]] || {
    [[ -z "$L" ]] && fetch="git fetch || exit 255;" || fetch=

    : ">>> Checkout '${DB}' and rebase onto '${SB}'?"
    delim

    ls -d rubygem-*/ | xargs -n1 -i bash -c "echo; set -x; cd {} || exit 255; [[ -r .continue || -r .skip ]] && exit 0; git checkout '`cut -d'/' -f2- <<< "${DB}"`' || { git checkout -t '${DB}' || exit 255; }; git stash; ${fetch} git reset --hard '${DB}' || exit 255 ; git rebase '${SB}' || exit 255; touch .continue; rm .built ||:"
    delim
  }

  : ">>> Create bootstrap folders"
  for a in $BS; do
    bash -c "echo; set -x; cp -ir rubygem-${a}{,-bs}"
  done
  delim

  : ">>> Set up bootstrap folders"
  ls -d rubygem-*-bs/ | xargs -n1 -i bash -c "echo ; set -x ; cd {} || exit 255 ; [[ -r .skip ]] && exit 0 ; git reset --hard HEAD^ || exit 255"
  delim

  [[ `ls -d rubygem-*/ | wc -l` -eq $TT ]] || die "Invalid number of folders incl. *-bs: `ls`"
  clear
}

: ">>> Display diffs"
ls -d rubygem-*/ | sort -r | xargs -n1 -i bash -c "echo ; cd {} || exit 255 ; [[ -r .skip ]] && exit 0 ; echo \"--> {}\" ; git show --patch-with-stat | colordiff  ; git status -uno"
delim

{ set +e; } &>/dev/null

timeout 3 koji wait-repo "$TG"
[[ $? -eq 124 ]] || die "Repo not available: $TG"

: ">>> Run builds"
xargs -n1 -i bash -c "echo; set -x; [[ -d 'rubygem-{}' ]] || exit 255 ; cd 'rubygem-{}' || exit 255; [[ -r .skip || -r .built ]] && exit 0 ; git fetch || exit 255 ; [[ -n '$F' ]] || { git status | grep -q \"Your branch is up to date with '${DB}'.\" && exit 0 ; git status -uno | grep -q \"Your branch is ahead of '${DB}' by 1 commit.\" || exit 255 ; } ; for z in {1..10}; do [[ -n '$F' ]] || fedpkg scratch-build --srpm --target '$TG' && { [[ -z '$L' ]] || exit 0; } && fedpkg new-sources \$(cut -d'(' -f2 < sources | cut -d')' -f1) && { fedpkg push || exit 255 ; for x in {1..10}; do fedpkg build --target '$TG' && { rm .continue; touch .built; P=\"\$(cut -d'-' -f1 <<< '{}')\"; [[ 'bs' == \"\$(cut -d'-' -f2 <<< '{}')\" ]] && B='~bootstrap' || B=''; koji wait-repo --timeout=30 '${TG}' --build=\"rubygem-\$P-\$(grep -A 1 '^%changelog$' *.spec | tail -n 1 | rev | cut -d' ' -f1 | rev | sed -e 's/[0-9]*://').fc${FX}\$B\" ; exit 0; } ; sleep 600 ; done ; exit 255; } ; sleep 600; done ; exit 255" <<EOLX
activesupport
activejob
activemodel-bs
rails
actionview-bs
actionpack-bs
activerecord
actionmailer
actioncable
activestorage-bs
railties-bs
actiontext
actionmailbox
activemodel
actionview
actionpack
activestorage
railties
EOLX
