#!/bin/bash
set -e
bash -n "$0"

error () {
  echo "Error:" "$@" >&2
  exit 1
}

COPR_URL="https://download.copr.fedorainfracloud.org/results/pvalena/"
stderr=/dev/stderr

[[ -n "`which mock`" ]] || error "Dependency missing: mock"
[[ -n "`which fedpkg`" ]] || error "Dependency missing: fedpkg"

d=lss
[[ "$1" == '-c' ]] && d=cat && shift
[[ "$1" == '-d' ]] && set -x && shift
[[ "$1" == '-n' ]] && { NEW=y; shift; } || NEW=
[[ "$1" == '-r' ]] && {
  RETRY="$2"
  grep -qE "^[0-9]+$" <<< "$RETRY"
  shift 2
  :
} || RETRY=0
[[ "$1" == '-s' ]] && shift || {
  rm *.src.rpm ||:
}
[[ "$1" == '-t' ]] && {
  T="$2"
  shift 2
  :
} || T='2h'

[[ "$1" == '-w' ]] && {
  shift
  P="$1"
  shift

  while copr-cli status $P \
      | grep -qvE '(succeeded|failed|cancelled)' ; do
    sleep 300
  done
}||:

n="$1"
[[ -n "$n" ]] || { echo 'Missing copr repo!'; exit 1; }
[[ ! "${n:0:1}" == '-' ]]

x="${2}"
[[ -n "$x" ]] || x='fedora-rawhide-x86_64'

l="`readlink -f "../copr-r8-${n}"`"
[[ -d "$l" ]] || {
  [[ -n "$NEW" ]] && mkdir -p "$l"

  [[ -d "$l" ]] || {
    error "log directory '$l' does not exist"
    exit 1
  }
}

ls *.src.rpm &>/dev/null || {
  rm result/*.src.rpm ||:
  mar='-n --result=./result --bootstrap-chroot --buildsrpm --sources . --spec'
  mock $mar *.spec || \
    mock -v $mar *.spec || {
      echo "Warning: failed to build SRPM in mock, fallback to fedpkg." >&2
    }
  mv result/*.src.rpm . ||:

  ls *.src.rpm &>/dev/null || {
    fedpkg --dist f34 srpm || {
      echo "Warning: modifying spec file..." >&2
      sed -i 's/^Recommends: /Requires: /' *.spec
      sed -i '/^Suggests: / s/^/#/' *.spec
      sed -i -e 's/\(Requires\:\)\s*(.*with\(.*\))/\1\2/' *.spec
      fedpkg --dist f34 srpm
    }
  }
}

p="$(ls *.src.rpm | rev | cut -d'-' -f3- | rev)"
[[ -n "$p" ]]

f="${l}/${p}.log"
touch "$f"

echo -ne "\e]2;C:$p\a"

set +e -o pipefail
nr=0
while :; do
  [[ -w "$stderr" ]] && debug="tee -a $stderr" || debug=cat

  O="`set +e -o pipefail; date -Isec; timeout "${T}" copr-cli build $n *.src.rpm 2>&1 | $debug`"
  R=$?

  b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`" ||:
  [[ -n "$b" ]] || exit 1
  grep -qE '^[0-9]*' <<< "$b" || exit 3

  [[ -t 1 ]] || d=cat
  [[ -t 0 ]] || d=cat
  [[ $R -eq 0 || $nr -lt $RETRY ]] && d=cat

  sleep 30
  {
    echo "$O"
    u="${COPR_URL}${n}/${x}/`printf "%08d" "$b"`-${p}/builder-live.log.gz"
    echo "> $u"
    curl -sLk "$u" | zcat | uniq

  } 2>&1 | tee "$f" | $d

  [[ $R -eq 0 || $nr -ge $RETRY ]] && exit $R || {
    let 'nr += 1'
    echo -e "\n> Retrying ($nr/$RETRY) ..."
  }
done

echo "You shouldn't see this..." >&2
exit 1
