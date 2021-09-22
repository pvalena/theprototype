#!/bin/bash

set -e
bash -n "$0"

## CONFIG
me='pvalena'

kpf='rubygem|vagrant'
l='.log'
s=".spec"
sep="_ _ _ _"
nl='
'

# for koji scratch-build
kl="$me@FEDORAPROJECT\.ORG"

# Directories
myd="`dirname "$(readlink -e "$0")"`"
gup="${myd}/gup.sh"
tst="${myd}/test.sh"
cpr="`readlink -e "${myd}/../fedora/create_pr.sh"`"
src="`readlink -e "${myd}/../pkgs/sources.sh"`"
gpr="`readlink -e "${myd}/../fedora/get_pr.sh"`"
hom="`readlink -e "${myd}/../../"`/"


## METHODS
abort () {
  echo -e "--> Error:" "$@" 1>&2
  exit 1
}

gistf () {
  [[ -n "$GST" ]] && {
    sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" "$1" \
      | gist -sf "$1"
    :
  } || readlink -e "$1"
}

addlog () {
  [[ -r "$2" ]] || return 1

  sed -i "s|${hom}||" "$2"
  echo -e "${1}: `gistf "$2"`" | tee -a "$o"
}

crb () {
  [[ -n "$CON" ]] && CON='-s' || CON=''

  bash -c "set -e; cd '$p'; $gup -j ${CON} -u -x -y" 2>&1 | tee -a "$u"
  R=$?

  [[ $R -eq 2 ]] && exit 2                    #<< Package is up to date
  [[ $R -eq 0 ]] || abort "Update failed"

  BLD="$(grep '^Created builds: ' "$u" | cut -d' ' -f3 | grep -E '^[0-9]+$' | head -1)"

  [[ -n "$BLD" ]] || abort 'COPR Build missing'
}


## VARS
ARG=

[[ "$1" == '-b' ]] && {
  BLD="$2"
  shift 2
  :
} || BLD=

[[ "$1" == '-c' ]] && {
  CON="$1"
  shift
  :
} || CON=

[[ "$1" == '-d' ]] && {
  DEB="$1"
  shift
  set -x
  :
} || DEB=

[[ "$1" == '-f' ]] && {
  FCE=y
  shift
  :
} || FCE=

[[ "$1" == '-n' ]] && {
  GST=
  shift
  :
} || GST="`which gist`"

[[ "$1" == '-p' ]] && {
  pre="$2"
  shift 2
  :
} || pre=

[[ "$1" == '-s' ]] && {
  SRC="$1"
  shift
  :
} || SRC=

[[ "$1" == '-u' ]] && {
  UPD=y
  shift
  :
} || UPD=

[[ -z "$1" || "$1" == '--' ]] && {
  x="$(basename "$PWD")"
  cd ..
  :
} || {
  [[ "${1:0:1}" == '-' ]] && abort "Unkown arg: '$1'"
  x="$1"
  shift
}

[[ "$1" == '--' ]] && {
  shift
  :
}

## INIT
# Auto-detect prefix
[[ -z "$pre" ]] && {
  pre="$(echo "$x" | cut -d'-' -f1 | grep -E "^(${kpf})$")"
}

[[ -n "$pre" ]] && {
  # No validation required, at this point
  x="$(echo "$x" | cut -d'-' -f2-)"
}

[[ -n "$pre" ]] \
  && p="${pre}-${x}" \
  || p="$x"

[[ "$pre" == 'vagrant' ]] && {
  x="$p"
  ARG="${ARG} -v"
}

[[ "$pre" == 'rubygem' ]] && {
  ARG="${ARG} -g"
}

y="$(readlink -f cpr)/${p}_"
u="${y}update${l}"
e="${y}test${l}"
o="${y}summary.md"
d="${y}gem2rpm.diff"

g="${p}/.generated${s}"
s="${p}/${p}${s}"

[[ -n "$x" ]] || abort 'Name of gem is missing.'
[[ -d "$p" ]] || abort 'gem directory missing.'
[[ -x "$tst" ]] || abort 'Test script not accessible.'
[[ -x "$gup" ]] || abort 'Update script not accessible.'
[[ -x "$cpr" ]] || abort 'CPR script not accessible.'
[[ -x "$src" ]] || abort 'SRC script not accessible.'
[[ -d "`dirname "$y"`" ]] || abort 'CPR directory non-existent:' "`dirname "$y"`"

[[ -n "$pre" ]] || abort "Non-prefix packages are not supported yet."


## MAIN
set -o pipefail
echo "> $p :: $x :: $pre"

klist -A | grep -q ' krbtgt\/FEDORAPROJECT\.ORG@FEDORAPROJECT\.ORG$' || {
  kinit "$kl" -l 30d -r 30d -A
  pgrep -x krenew &>/dev/null || krenew -i -K 60 -L -b
}

rm -f "$o"
rm -f "$e"
rm -f "$d"
rm -f "$u"


[[ -n "$SRC" ]] && {
  bash -c "set -e; cd '$p'; ${src} -y"
  echo
}

[[ -n "$UPD" ]] && {
  pr="$($gpr "$p")"
  SKIPPR=
  [[ -n "$pr" ]] && {
    echo -e ">> Update already pending\nPull request: ${pr}\n"
    [[ -z "$GST" || -n "$FCE" ]] || {
      [[ -n "$CON" ]] || exit 0
      SKIPPR=y
    }
  }

  echo ">> Update"

  [[ -n "$BLD" ]] && {
    [[ -n "$CON" ]] || abort "NYI: You cannot specify '-b' without '-c' while '-u' is specified."
    :
  } || {
    crb
  }

  ARG="-b $BLD -c ${ARG}"

  t="$(bash -c "set -e; cd '$p'; git log -1 2>/dev/null | tail -n +5 | sed -e 's/^\s*//'")"
  grep -qE "^Up(date|grade) to " <<< "$t" || {
    [[ -z "$FCE" ]] && abort "Malformed git log entry: $t"
  }

  tt="$(bash -c "set -e; cd '$p'; git status -uno 2>&1")"
  for a in \
    'On branch rebase' \
    "Your branch is up to date with '$me/rebase'." \
    "nothing to commit"
  do
    grep -q "^$a" <<< "$tt" || {
      m="Invaild git status (did not match '$a'):\n$tt"
      [[ -n "$GST" && -z "$FCE" ]] \
        && abort "$m" \
        || echo -e "Warning: $m" >&2
    }
  done

  # Rest of the changelog entry not used for title
  tr="$(tail -n +2 <<< "$t")"
  [[ -n "$tr" ]] && tr="${tr}${nl}${sep}${nl}"

  [[ -n "$CON" ]] || {
cat >> "$o" <<-EOF
${tr}__Note: this update was created and tested automatically, but it was not checked by anyone. Please check the logs, commits, and comment "LGTM" it if you find it ok. Afterwards it will be merged and built automatically as well (and checked by me).__
EOF
  }
  :
} || {
  [[ -n "$CON" ]] && ARG="-c ${ARG}"

  [[ -n "$BLD" ]] || {
    crb
  }

  [[ -n "$BLD" ]] && ARG="-b $BLD ${ARG}"
}

set +e

# gem2rpm diff
bash -c "set -e; cd '$p'; gem fetch '$x'; gem2rpm \"\$(ls -d ${x}-*.gem | tail -n1)\"" > "$g" && {
  diff -dbBZrNU 3 "$g" "$s" \
    | grep '^ %changelog$' -B 10000 \
    | tee "$d"

  grep '^ %changelog$' -A 4 < "$d" | grep '^+'

  rm -f "$g"
}

# This is intentional to redirect stderr to "$e" file (and print to terminal), and stdout to "$o"
# TODO: properly parse and forward args (we rely on '-u' is the last)
#       or fix test to accept them in any order
echo ">> Tests"
$tst $ARG "$@" "$x" 2>&1 >> "$o" | tee -a "$e"
R=$?

[[ $R -eq 0 ]] || abort "Testing failed!"
[[ "`wc -l < "$o"`" == "0" ]] && abort "Summary ('$o') is empty!"
[[ "`wc -l < "$e"`" == "0" ]] && abort "Test log ('$e') is empty!"

echo -e "\n${sep}\n" | tee -a "$o"

# Let's add update and stderr log into report
addlog 'Update log' "$u"
addlog 'Test log' "$e"
addlog 'gem2rpm diff' "$d"

echo -e "${sep}\n"

[[ -z "$SKIPPR" && -n "$UPD" && -n "$GST" ]] && {
  Q="$($cpr "$p" "`head -1 <<< "$t"`" "`cat "$o"`" "$me" rebase)" \
    || echo "Failed to create PR:" "$Q" 1>&2

  sleep 1
}

pr="$($gpr "$p")"

[[ -z "$pr" ]] && {
  echo "You can create PR manualy: https://src.fedoraproject.org/fork/$me/rpms/${p}/diff/rawhide..rebase"
  # gistf "$o"
  :
} || {
  echo "Pull request: ${pr}"
}

exit 0
