#!/usr/bin/bash

set -e
bash -n "$0"


## METHODS
branch () {
  gitb | grep '^*' | cut -d' ' -f2
}

commit () {
  git show --stat | grep ^commit | head -1 | cut -d' ' -f2
}

abort () {
  { echo -e "\n" ; } 2>/dev/null
  echo "Error:" "$@" >&2

  { echo -e "\n" ; } 2>/dev/null
  [[ -n "$b" ]] && git checkout "$b"
  exit 1
}


## ARGS
[[ "$1" == "-d" ]] && {
  shift
  set -x
  :
}

[[ "$1" == "-r" ]] && {
  r="--release $2"
  shift 2
  :
} || r=

[[ -n "$1" ]] && {
  c="$1"
  shift
  :
} || c=HEAD

[[ -z "$1" ]] || abort "Unknown arg '$1'"


## INIT
b="$(branch)"
[[ -z "$b" ]] && exit 2


## SETUP
git checkout "$c"
[[ "$(commit)" == "$c" ]] || abort "Failed to checkout to '$c'"

f="$(git show --stat | grep -E ' \S*\.patch \| ' | head -1 | cut -d' ' -f2)"
[[ -r "$f" ]] || abort "Patch file not found: '$f'"
f="$(readlink -e "$f")"
[[ -w "$f" ]] || abort "Patch file not writable: '$f'"

l="$(cat "$f")"
[[ -n "$l" ]] || abort "Failed to load patch file: '$f'"

n="$(grep -E "^Patch[0-9]*:\s*`basename "$f"`$" *.spec | cut -d':' -f1 | cut -d'h' -f2)"
grep -E '^[0-9]+$' <<< "$n" || abort "Could detect patch number: '$n'"

x="$(grep -E "^%patch${n} " *.spec | cut -d' ' -f2 | cut -d'p' -f2)"
grep -E '^[0-9]+$' <<< "$x" || abort "Could not detect patch strip number: '$x'"


## PREP
git checkout HEAD^

o="$(centpkg $r prep 2>&1)" \
  || abort 'Failed to prep.'

d="$(grep '^\s*+ cd ' <<< "$o" | tail -n 1 | cut -d' ' -f3)"
[[ -d "$d" ]] || abort "Prepped dir not found: '$d'"


## PATCH
pushd "$d"
  git init
  git add -A .
  git commit -am 'init'

  patch -N -F 0 "-p$x" <<< "$l" ||:

  git commit -am 'patch' || {
    popd
    abort 'Failed to create patch (1).'
  }

  p="$(git format-patch HEAD^ --stdout)"
popd

[[ -n "$p" ]] || abort 'Failed to create patch(2).'

## APPLY
a="apply_cleanly-${RANDOM}"

git checkout -b "$a" "$b"
[[ "$(branch)" == "$a" ]] || abort "Failed to switch to branch '$a'"

GIT_SEQUENCE_EDITOR="sed -i -ze 's/^pick/edit/'" \
  git rebase --interactive "${c}~1"

echo "$p" > "$f"

git add --patch

git rebase --continue || {
  git rebase --abort

  abort 'Failed to rebase changes.\n\n' \
    'Leftover branches:\n' "$(git branch | grep '^  apply_cleanly-')"
}


## CLEANUP
# git branch -D "$a" ??
# rm -rf "$d"
