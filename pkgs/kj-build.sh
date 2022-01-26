#!/bin/bash

set -e
bash -n "$0"

abort () {
  echo -e "Error: " "$@" >&2
  exit 1
}

P=fed

mkdir -p result
f1='result/root.log'
f2='result/build.log'

l='--release'

me=pvalena
stderr=/dev/stderr

srpm () {
  local x=
  [[ -n "$1" ]] && x="$l $1" ||:
  [[ -n "$Q" ]] && q=' &>/dev/null' || q=
  bash -c "${DEBUG}${P}pkg $x srpm$q" && return 0
  return 1
}

buildid () {
  [[ "$P" == 'fed' ]] && {
    printf "%08d" "$1"
    :
  } || echo "$b"
}

d=lss
which "$d" &>/dev/null || d=less
which "$d" &>/dev/null || d=more
which "$d" &>/dev/null || d=cat

# ARGS
[[ "$1" == '-a' || "$1" == '--arch' ]] && {
  A=" --arch '$2'"
  shift 2
  :
} || A=
[[ "$1" == '-c' ]] && d=cat && shift
[[ "$1" == '-d' ]] && DEBUG=y && shift
[[ "$1" == '-o' ]] && P=cent && shift
[[ "$1" == '-q' ]] && Q=y && shift
[[ "$1" == '-r' ]] && P=rh && shift
[[ "$1" == '-s' ]] && S=y && shift
[[ "$1" == '-t' || "$1" == '--target' ]] && {
  G=" --target '$2'"
  shift 2
  :
} || G=

[[ -n "$DEBUG" ]] && DEBUG="set -x; " || DEBUG=

[[ "${1:0:1}" == '-' ]] && abort "Unkown arg:" "$1"

[[ -n "$1" ]] && {
  r="$1"
  shift
  :
} || {
  r="`gitb | grep '^*' | cut -d' ' -f2-`"
  grep -q '^rebase-' <<< "$r" && r="`cut -d'-' -f2- <<< "$r"`"
  grep -q '^rebase$' <<< "$r" && r="rawhide"
}

[[ -z "$1" ]] || { echo "Unkown arg: $1" >&2; exit 1; }

which "${P}pkg" &>/dev/null || abort "Dependency missing: ${P}pkg"

# SRPM
[[ -n "$S" && -n "`ls *.src.rpm`" ]] || {
  rm *.src.rpm ||:

  for i in 0 1; do
    # $r already specified
    [[ -n "$1" ]] && {
      srpm "$r" && break
      :
    } || {
      s=
      c=1
      for t in "$r" '' 'rawhide' 'f35'; do
        srpm "$t" && {
          s="$t"
          c=0
          break
        } ||:
      done

      # success
      [[ $c -eq 1 ]] || {
        r="$s"
        break
      }
    }

    # Failed
    [[ "$i" -eq 0 ]] || exit 7

    # Try without richdeps
    sed -i 's/^Recommends: /Requires: /' *.spec
    sed -i '/^Suggests: / s/^/#/' *.spec
    sed -i -e 's/\(Requires\:\)\s*(.*with\(.*\))/\1\2/' *.spec
  done
}

[[ -n "$r" ]] && r="$l $r"
[[ -n "`ls *.src.rpm`" ]] || exit 6

[[ -t 1 ]] || d=cat
[[ -t 0 ]] || d=cat
[[ -t 0 ]] || d=cat

{ set +e ; } &>/dev/null

[[ "$P" == 'fed' ]] && {
  kl="$me@FEDORAPROJECT\.ORG"
  klist -A | grep -q ' krbtgt\/FEDORAPROJECT\.ORG@FEDORAPROJECT\.ORG$' || {
    kinit "$kl" -l 30d -r 30d -A
    pgrep -x krenew &>/dev/null || krenew -i -K 60 -L -b
  }
  URL="https://kojipkgs.fedoraproject.org"
}
[[ "$P" == 'rh' ]] && {
  URL="http://download.eng.bos.redhat.com/brewroot"
}
[[ "$P" == 'cent' ]] && {
  URL="https://kojihub.stream.rdu2.redhat.com/kojifiles"
}

cmd="${DEBUG}${P}pkg $r scratch-build --fail-fast --srpm *.src.rpm${G}${A}"

# Quiet run
[[ -z "$Q" ]] || {
  Y="$( bash -c "${cmd} --nowait" 2>&1 )"

  X="$( grep '^Created task: ' <<< "$Y" | cut -d' ' -f3 )"

  [[ -n "$X" ]] \
    && grep -E '^[0-9]*' <<< "$X" \
    || abort "Failed to start build: $Y"

  S=
  for x in {1..5}; do
    sleep 15

    S="$( koji watch-task "$X" 2>&1 )"
    grep -q 'completed successfully$' <<< "$S" && exit 0
    grep -v '0 failed$' <<< "$S" | grep -q 'failed$' && exit 1
    grep -q 'canceled$' <<< "$S" && exit 1
  done

  abort "Could not get task status for $X!\n$S"
}

# Standard run
date -Isec
[[ -w "$stderr" ]] && debug_out="tee -a $stderr" || debug_out=cat

eval "$DEBUG"

bash -c "${cmd}" 2>&1 \
  | $debug_out \
  | grep 'buildArch' \
  | grep -E '(FAILED|closed)' \
  | tr -s ' ' \
  | cut -d' ' -f1-2 \
  | tr -s ' ' '\n' \
  | grep -E '^[0-9]+$' \
  | sort -u \
  | head -1 \
  | while read b; do
      sleep 15
      z="`rev <<< "$b" | cut -c -4 | rev | sed 's/^0*//'`"

      for f in "$f1" "$f2"; do
        rm "$f"
        u="${URL}/work/tasks/$z/`buildid "$b"`/`cut -d'/' -f2 <<< "$f"`"
        echo "> $u"
        curl -sLk -o "$f" "$u"
      done

      bash -c "$d '$f2' '$f1'"
    done

exit 0
###########################################################
#             EXITED
###########################################################

# TODO: adopt one approach

p="$(basename "$PWD")"

O="`copr-cli build $c *.src.rpm 2>&1 | tee /dev/stderr`" && R=0 || R=1

b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`"
[[ -n "$b" ]] || exit 1
grep -qE '^[0-9]*' <<< "$b" || exit 3

[[ -t 1 ]] && d=lss || d=cat
[[ -t 0 ]] || d=cat

grep -q succeeded <<< "$O" || {
  for l in build root; do
    (
      echo "$O"
      curl -#Lk "https://download.copr.fedorainfracloud.org/results/pvalena/${c}/${x}/`printf "%08d" $b`-${p}/${l}.log.gz" \
        | zcat
    ) \
    | uniq | $d
  done
}

exit $R
