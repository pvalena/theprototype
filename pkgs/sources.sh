#!/usr/bin/bash

set -e
bash -n "$0"

die () {
  echo
  warn "Error" "$1"
  exit 1
}

warn () {
  echo
  echo "--> $1: $2!" >&2
}

ask () {
  local r=
  local s=
  [[ "$1" == '-s' ]] && s="$1" && shift

  for x in {1..10}; do
    echo
    [[ -n "$YES" ]] && {
      echo ">> $@. "
      return 0
      :
    } || {
      read -n1 -p ">> $@? " r

      grep -qi '^y' <<< "${r}" && {
        #clear
        return 0
        :
      }||:

      grep -qi '^n' <<< "${r}" && {
        break
        :
      }||:
    }
  done

  [[ -n "$s" ]] || die 'User quit'
  return 1
}

X="`ls *.spec`"
gcom="git|cd|tar|wget|curl"
YES=
stderr=/dev/stderr

[[ -w "$stderr" ]] && debug_out="tee -a $stderr" || debug_out=cat

set +e

[[ "$1" == '-c' ]] && {
  shift
  CLEAN=y
  :
} || CLEAN=

[[ "$1" == '-y' ]] && {
  shift
  YES=y
  :
} || YES=

[[ -z "$1" ]] || {
  X="$1"
  shift
}

[[ -z "$1" ]] || {
  gcom="$1"
  shift
}

[[ -z "$1" ]] || {
  YES="$1"
  shift
}

find -L -mindepth 2 -maxdepth 3 -type d -name .git -exec bash -c "cd '{}/..'; git fetch origin" \;
cmd="$(
    grep -B 20 '^Source' "$X" | grep '^#' | cut -d'#' -f2- | grep -E "^\s*(${gcom})\s*" \
      | xargs -i echo -n " && {}" \
      | xargs -i echo "set -x {} && echo Ok || exit 1"
  )"

cmd="$( sed -e 's/\(&& git clone [^&]* \)&&/\1;/g' <<< "$cmd" )"

[[ -z "$cmd" ]] || {
  echo
  echo "\$cmd: $cmd"
  ask 'execute $cmd'
  bash -c "$cmd" || die 'Failed to execute $cmd'
}
find -L -mindepth 2 -maxdepth 3 -type f -name '*.tar.xz' -o -name '*.tar.gz' -o -name '*.txz' -o -name '*.tgz' | xargs -ri mv -v "{}" .

# Cleanup
[[ -n "$CLEAN" ]] && {
  cmd="$(
      grep -B 20 '^Source' "$X" | grep '^#' | cut -d'#' -f2- | grep -E "^\s*(git clone)\s*" \
        | tr -s ' ' '\n' | grep -E '^http(s)?\:\/\/' \
        | rev | cut -d'/' -f1 | rev \
        | sed -e 's/\.git$//' \
        | xargs -i echo -n " && rm -rf '{}'" \
        | xargs -i echo "set -x {} && echo Ok || exit 1"
    )"
  [[ -z "$cmd" ]] || {
    echo
    echo "\$cmd: $cmd"
    ask 'execute $cmd'
    bash -c "$cmd" || die 'Failed to execute $cmd'
  }
}

spectool -S "$X" | grep ^Source | cut -d' ' -f2- | grep -E '^http[s]*://' | xargs -r -P 0 curl -sLO

regex='(\.(rb|js|patch|1|sh|stp|gtk3|preset|conf|logrotate|rules|service)|LICENSE|binstub|rubygems\..*|macros\..*)$'

spectool -S "$X" | grep ^Source | tr -s '\t' ' ' | cut -d' ' -f2- \
  | rev | cut -d'/' -f1 | rev | grep -vE "$regex" \
  | while read x; do
      echo "SHA512 ($x) = `sha512sum "$x" | cut -d' ' -f1`" | $debug_out
    done > sources

spectool -S "$X" | grep -E '^(Source|Patch)' | tr -s '\t' ' ' | cut -d' ' -f2- \
  | rev | cut -d'/' -f1 | rev | grep -E "$regex" \
  | while read x; do
      git add "$x"
    done
