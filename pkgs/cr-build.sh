#!/bin/bash
set -e
bash -n "$0"

COPR_URL="https://copr-be.cloud.fedoraproject.org/results/pvalena/"

d=lss
[[ "$1" == '-d' ]] && set -x && shift
[[ "$1" == '-c' ]] && d=cat && shift
[[ "$1" == '-d' ]] && set -x && shift
[[ "$1" == '-r' ]] && {
  RETRY="$2"
  grep -qE "^[0-9]+$" <<< "$RETRY"
  shift 2
  :
} || RETRY=0
[[ "$1" == '-s' ]] && shift || {
  rm *.src.rpm ||:
}

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
[[ -n "$n" ]]

x="${2}"
[[ -n "$x" ]] || x='fedora-rawhide-x86_64'

p="$(basename "$PWD")"
[[ -n "$p" ]]

l="`readlink -f "../copr-r8-${n}"`"
# don't
# mkdir -p "$l"
[[ -n "$l" && -d "$l" ]] || {
  echo "Error: log directory '$l' does not exist" >&2
  exit 1
}

f="${l}/${p}.log"
touch "$f"

ls *.src.rpm &>/dev/null || {
  fedpkg --dist f31 srpm || {
    echo "Warning: modifying spec file..." >&2
    sed -i 's/^Recommends: /Requires: /' *.spec
    sed -i '/^Suggests: / s/^/#/' *.spec
    sed -i -e 's/\(Requires\:\)\s*(.*with\(.*\))/\1\2/' *.spec
    fedpkg --dist f31 srpm
  }
}

echo -ne "\e]2;C:$p\a"

set +e -o pipefail
nr=0
while :; do
  O="`date -Isec; copr-cli build $n *.src.rpm 2>&1 | tee -a /dev/stderr`"
  R=$?

  b="`echo "$O" | grep '^Created builds: ' | cut -d' ' -f3`" ||:
  [[ -n "$b" ]] || exit 1
  grep -qE '^[0-9]*' <<< "$b" || exit 3

  [[ -t 1 ]] || d=cat
  [[ -t 0 ]] || d=cat
  [[ $R -eq 0 || $nr -lt $RETRY ]] && d=cat

  sleep 15
  {
    echo "$O"
    u="${COPR_URL}${n}/${x}/`printf "%08d" $b`-${p}/builder-live.log.gz"
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
