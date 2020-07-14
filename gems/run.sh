#!/bin/bash

set -e
bash -n "$0"

tst="`readlink -e ~/lpcsf-new/test/scripts/gems/test.sh`"

abort () {
  echo "Error:" "$@" 1>&2
  exit 1
}

gistf () {
 [[ -z "`which gist`" ]] || gist -sf "`basename "$1"`" < "$1"
}

[[ -n "$1" && "${1:0:1}" != '-' ]] && {
  x="$1"
  shift
  :
} || {
  x="$(basename "$PWD" | grep '^rubygem\-' | cut -d'-' -f2-)"
}

cd "$(dirname "$0")"

[[ -n "$x" ]] || abort 'Name of gem is missing.'
[[ -d "rubygem-$x" ]] || abort 'gem directory missing.'
[[ -x "$tst" ]] || abort 'Test script not accessible.'
[[ -d "cpr" ]] || abort '`cpr` directory missing.'

l='.log'
y="cpr/${x}-"
o="${y}o${l}"
e="${y}e${l}"

# This is intentional to redirect stderr to "$e" file and stdout to "$o"
set -o pipefail
$tst "$@" "$x" 2>&1 >"$o" | tee "$e"
r=$?

# Let's add stderr log into report
echo "Log: `gistf "$e"`" >> "$o"

#clear
#cat "$o"
[[ $r -eq 0 ]] && {
cat <<-EOF
_ _ _ _


https://src.fedoraproject.org/fork/pvalena/rpms/rubygem-${x}/diff/master..rebase
`gistf "$o"`

EOF
} || less "$e"
