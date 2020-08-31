#!/bin/bash

set -e
bash -n "$0"

myd="`dirname "$(readlink -e "$0")"`"
gup="${myd}/gup.sh"
tst="${myd}/test.sh"
cpr="`readlink -e "${myd}/../fedora/create_pr.sh"`"
gpr="`readlink -e "${myd}/../fedora/get_pr.sh"`"
hom="`readlink -e "${myd}/../../"`/"

abort () {
  echo -e "Error:" "$@" 1>&2
  exit 1
}

gistf () {
  [[ -n "`which gist`" && -n "$GST" ]] \
    && gist -sf "$1" < "$1"
}

addlog () {
  [[ -r "$2" ]] || return 1

  sed -i "s|${hom}||" "$2"
  echo -e "${1}: `gistf "$2"`" | tee -a "$o"
}

[[ -n "$1" && "${1:0:1}" != '-' ]] && {
  x="$1"
  AUT=
  shift
  :
} || {
  x="$(basename "$PWD" | grep '^rubygem\-' | cut -d'-' -f2-)"
  AUT=y
}

[[ "$1" == '-n' ]] && {
  GST=
  shift
  :
} || GST=y

[[ "$1" == '-u' ]] && {
  UPD=y
  shift
  :
} || UPD=

[[ "$1" == '--' ]] && {
  shift
  :
}

[[ -n "$AUT" ]] && cd ..

l='.log'
s=".spec"

y="cpr/${x}-"
u="${y}update${l}"
o="${y}summary.md"
e="${y}test${l}"
d="${y}gem2rpm.diff"

p="rubygem-${x}"
f="${p}/.update"
g="${p}/.generated${s}"
s="${p}/${p}${s}"

sep="_ _ _ _"
nl='
'

[[ -n "$x" ]] || abort 'Name of gem is missing.'
[[ -d "$p" ]] || abort 'gem directory missing.'
[[ -x "$tst" ]] || abort 'Test script not accessible.'
[[ -x "$gup" ]] || abort 'Update script not accessible.'
[[ -x "$cpr" ]] || abort 'CPR script not accessible.'
[[ -d "cpr" ]] || abort '`cpr` directory missing.'

set -o pipefail

rm -f "$o"
rm -f "$e"
rm -f "$d"

[[ -n "$UPD" ]] && {
  rm -f "$u"

  [[ -r "$f" || -n "$($gpr "$p")" ]] && {
    echo "Update already pending"
    exit 0
  }

  for a in "$@"; do
    [[ "$a" == "-b" || "$a" == '-c' ]] && abort "You cannot use '$a' arg with '-u'."
  done

  echo ">> Update"
  bash -c "echo; set -e; cd '$p'; $gup -j -u -x -y" 2>&1 | cat | tee "$u"

  [[ $? -eq 0 ]] || abort "Update failed"

  B="$(grep '^Created builds: ' "$u" | cut -d' ' -f3 | grep -E '^[0-9]+$' | head -1)"
  [[ -n "$B" ]] || abort 'COPR Build missing'

  B="-b $B -c"

  t="$(bash -c "set -e; cd '$p'; git log -1 2>/dev/null | tail -n +5 | sed -e 's/^\s*//'")"
  grep -q "^Update to " <<< "$t" || abort "Malformed git log entry: $t"

  tt="$(bash -c "set -e; cd '$p'; git status -uno 2>&1")"
  for a in \
    'On branch rebase' \
    "Your branch is up to date with 'pvalena/rebase'." \
    "nothing to commit"
  do
    grep -q "^$a" <<< "$tt" \
      || abort "Invaild git status(did not match '$a'):\n$tt"
  done

  # Rest of the changelog entry not used for title
  tr="$(tail -n +2 <<< "$t")"
  [[ -n "$tr" ]] && tr="${tr}${nl}${sep}${nl}"

cat > "$o" <<-EOF
${tr}__Note: this update was created and tested automatically, but it has not yet been checked manually. Please check the logs, and merge it if you find it ok. It will be built automatically in an hour.__
EOF
  :
} || B=

set +e

# gem2rpm diff
bash -c "set -e; cd '$p'; gem2rpm --fetch '$x' 2>/dev/null" > "$g" && {
  diff -dbBZrNU 3 "$g" "$s" | tee "$d"
  rm -f "$g"
}

# This is intentional to redirect stderr to "$e" file and stdout to "$o"
# TODO: properly parse and forward args; we're gessing '-u' is the last
[[ -z "$UPD" ]] && {
  $tst $B "$@" -u "$x" 2>&1 >>"$o" | tee "$e"
  :
} || {
  echo ">> Tests"
  $tst $B "$@" -u "$x" 2>&1 >>"$o" > "$e"
}

[[ $? -eq 0 ]] || exit 1
touch "$f"

echo -e "\n${sep}\n" | tee -a "$o"

# Let's add update and stderr log into report
[[ -n "$UPD" ]] && addlog 'Update log' "$u"
addlog 'Test log' "$e"
addlog 'gem2rpm diff' "$d"

[[ -z "$UPD" ]] || {
  $cpr "$p" "`head -1 <<< "$t"`" "`cat "$o"`"
  exit
}

echo "${sep}"
pr="$($gpr "$p")"

[[ -z "$pr" ]] && {
  echo "https://src.fedoraproject.org/fork/pvalena/rpms/${p}/diff/master..rebase"
  gistf "$o"
  :
} || {
  echo "PR already exists: ${pr}"
}

exit 0
