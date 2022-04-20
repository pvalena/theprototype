#!/bin/zsh

set -e
set -o pipefail
bash -n "$0"

prefix=
pretend=
target=
slp=
rebuild() {
    cut -d'/' -f1 \
  | cut -d'.' -f1 \
  | grep "^${prefix}" \
  | xargs -i zsh -c "
      fail () {
        echo \"{}: \${1}\" >> ../failed.txt
      }
      [[ -d '{}' ]] || fedpkg co '{}'
      cd '{}' || {
        fail cd
        exit 1
      }
      echo -e '\n'
      pwd
      set -x
      [[ -n '$skip' ]] || {
        gitc rawhide || fail gitc
        gitfo || fail gitfo
        gitt || fail gitt
        giteo || fail giteo
      }
      gem fetch \"\$(basename \"\$PWD\" | cut -d'-' -f2-)\" || fail fetch
      fedpkg sources || fail sources
      ${pretend} $crb -c -t 30m ${target} || fail build
      sleep ${slp}
      echo
    "
}

[[ "$1" == "-d" ]] && {
  set -x
  debug="set -x;"
  shift
  :
} || debug=

[[ "$1" == "-i" ]] && {
  slp="$2"
  shift 2
  :
} || slp=30

[[ "$1" == "-p" ]] && {
  pretend="echo"
  shift
  :
} || pretend=

[[ "$1" == "-r" ]] && {
  prefix="rubygem-"
  shift
  :
} || prefix=

[[ "$1" == "-s" ]] && {
  skip="$1"
  shift
  :
} || skip=

[[ "${1:0:1}" == '-' ]] && exit 1

target="${1:-rubygems}"
shift ||:
[[ -n "$target" ]] || exit 2

N="${1:-1}"
shift ||:
grep -E '^[0-9]+' <<< "$N" || exit 3


myd="$(dirname "$(readlink -f "$0")")"
crb="$(readlink -f "${myd}/cr-build.sh")"

[[ -x "$crb" ]]
[[ -n "$slp" ]]

set +e
for n in {1..$N}; do
  [[ -z "$1" ]] && {
    ls -d ${prefix}*/ \
      | rebuild
    :
  } || {
    [[ -r "$1" && ! -d "$1" ]] && {
      cat "$1" | rebuild
      :
    } || {
      echo "$@" | tr -s ' ' '\n' \
        | rebuild

    }
  }
done
