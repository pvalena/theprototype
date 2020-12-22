#!/bin/bash
#
# ./updrade.sh [options]
#
#   Simple script to upgrade from current Ruby on Rails in Fedora
#   to latest version. Uses `gems/gup.sh` to update the respective packages.
#   Also handles continuation (`-c`) well.
#
#   Specifically:
#     - DOES NOT handle the order of packages build/upgrade
#     - handle `rails` repo cloning and symlinking for creating sources
#     - creates folder for copr build logs
#     - switch to rebase branch
#     - bootstrap the packages (using bcond_without macro)
#     - create `.built` file on success
#     - run coprbld.sh (builds the packages)
#     - run bootstrap.sh (enables tests)
#     - run coprbld.sh (builds the bootstrapped packages)
#     - output status of commits periodically
#     - run test.sh in the end
#
# Options:
#
#   -c      Do not remove Sources (*.txz) and SRPM, and '.built' file.
#
#   -n      Do not abort on upgrade error (also passed to coprbld.sh).
#
#   -p      Download pre-release version.
#
#   -w S    Time to wait (passed to coprbld) after an upgrade. (Default: 15)
#           For availability in COPR repo.
#

set -e
bash -n "$0"
set -o pipefail

abort () {
  { set +x; } &>/dev/null
  {
    echo -n "> Error: "
    echo "$@"
  } >&2
  exit 1
}

status () {
  { set +x; } &>/dev/null
  ls -d rubygem-*/ \
    | cut -d'/' -f1 \
    | xargs -i bash -c "echo -ne '\n> '; cd '{}' && pwd && gitl -2 --oneline | cat || exit 255"
  echo
  set -x
}

d="`pwd`"
myd="$(dirname "`readlink -e "$0"`")"
GUP="$(readlink -e "${myd}/../gems/gup.sh")"
BOT="$(readlink -e "${myd}/bootstrap.sh")"
CRB="$(readlink -e "${myd}/coprbld.sh")"
TST="$(readlink -e "${myd}/test.sh")"

set +e
[[ -x "$GUP" && -x "$BOT" && -x "$CRB" && -x "$TST" ]] \
  || abort 'Dependent scripts not found!'

[[ "$1" == "-c" ]] && {
  CON="$1"
  shift
  :
} || {
  rm */.built
  rm */.prepared
  rm */*.txz
  rm */*.src.rpm
}

[[ "$1" == '-n' ]] && {
  BREAK=
  shift
  :
} || BREAK=y

[[ "$1" == '-p' ]] && {
  PRE='-e'
  shift
  :
} || PRE=

[[ "$1" == '-r' ]] && {
  CRR="$2"
  shift 2
  :
} || CRR='ruby-on-rails'

[[ "$1" == '-w' ]] && {
  W="$2"
  shift 2
  :
} || W=15

[[ -z "$1" ]] || abort "Unknown arg: '$1'."

mkdir -p "copr-r8-${CRR}"
git clone https://github.com/rails/rails.git
bash -c "
  set -xe
  cd rails
  git pull
  [[ -r rails ]] || ln -s . rails
  ls -d a*/ r*/ | xargs -i bash -c \"echo; cd '{}'; pwd; set -x; [[ -r rails ]] || ln -s .. rails\"
  :
" || abort 'Symlinking failed!'

rm -rf rubygem-*-bs/

while read x; do
  y="rubygem-${x}"

  cd "${d}/${y}" || abort "Failed to cd: '$y'"

  [[ -r .prepared ]] && continue

  set -x

  git checkout rebase

  ln -s ../rails .

  cp -n ../rubygem-activesupport/rails-*-tools.txz .

  $GUP -b ${CRR} $CON $PRE -j -r -x -y && {
    touch .prepared
    :
  } || {
    [[ -n "$BREAK" ]] && abort 'Failed to upgrade.'
  }

  sed -i 's/^%bcond_with bootstrap/%bcond_without bootstrap/' *.spec

  M="$(cat .git/COMMIT_EDITMSG | grep -v '^#')"
  git commit -a --amend -m "$M"

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
activestorage
actionmailbox
actiontext
actioncable
EOLX

[[ -n "$BREAK" ]] && {
  n=''
  :
} || n='-n'

set -e
cd "${d}" || abort "Failed to cd: '$d'"

status

$CRB $n -w "$W" "$CRR"

$BOT

status

$CRB $n -w "$W" "$CRR"

mar="$mar -r fedora-rails-x86_64"
$TST

exit 0

# Older version, for documentation purposes only:
ls -d rubygem-* | \
  xargs -i bash -c "cd '{}' && set -x && for x in \$(spectool -A *.spec | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev | grep -vE '^(binstub|macros\.vagrant|macros|rubygems\.)' | grep -vE '(\.rb)$') ; do echo \"SHA512 (\$x) = \$(sha512sum \"\$x\" | cut -d' ' -f1)\" ; done > sources && fedpkg commit -c && git remote add pvalena 'ssh://pvalena@pkgs.fedoraproject.org/forks/pvalena/rpms/{}' && { gitc rebase || gitc -b rebase } && gitf pvalena && gitu -uf pvalena rebase || exit 255 ; gits ; gith"
