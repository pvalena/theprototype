#!/bin/bash

set -e
bash -n "$0"

SRC_FPO_RPMS='https://src.fedoraproject.org/rpms/'
PREFIX='PKGS_'
WAIT='1'
LONG_WAIT='40'
R=0

rm "${PREFIX}SKIP.txt" &>/dev/null ||:
touch "${PREFIX}ZOMBIE_VR.txt" "${PREFIX}SKIP.txt" "${PREFIX}FAIL.txt"

ofile () {
  echo "$2: $3" | tee -a "${PREFIX}${1}.txt"
}
skip () {
  ofile SKIP "$@" >/dev/null
}
fail () {
  ofile FAIL "$@" >&2
}
abort () {
  echo "$@" >&2
  exit 1
}

[[ -r "${PREFIX}ZOMBIE.txt" && -r "${PREFIX}ZOMBIE_VR.txt" && -r "${PREFIX}SKIP.txt" && -r "${PREFIX}FAIL.txt" ]] || abort "Files unreadable"

while read PKG; do
  # Skip already checked
  grep -q "^${PKG}$" "${PREFIX}ZOMBIE_VR.txt" && {
    skip "$PKG" 'ZOMBIE_VR.txt'
    continue
  }
  grep -q "^${PKG}: " "${PREFIX}FAIL.txt" && {
    skip "$PKG" 'FAIL.txt'
    continue
  }

  sleep "$WAIT"

  URL="${SRC_FPO_RPMS}${PKG}/raw/master/f/dead.package"
  # Double-Check for DEAD
  curl -fs "${URL}" &>/dev/null && {
    echo "$PKG" >> "${PREFIX}ZOMBIE_VR.txt"
    continue
    :
  } || R=$?
  [[ $R -eq 22 ]] || {
    skip "$PKG" "curl -f (DEAD)"
    sleep "$LONG_WAIT"
    continue
  }

  sleep "$WAIT"

  # $R = 22 could mean a lot of things
  DEAD="$( curl -sI "${URL}" )" || {
    skip "$PKG" "curl -I (DEAD)"
    sleep "$LONG_WAIT"
    continue
  }
  DEAD="$( echo "$DEAD" | head -1 )"
  [[ -z "$DEAD" ]] && {
    skip "$PKG" "\$DEAD = EMPTY"
    continue
  }

  echo "$DEAD" | grep -q ' 200 ' && {
    echo "$PKG" >> "${PREFIX}ZOMBIE_VR.txt"
    continue
  }

  echo "$DEAD" | grep -q ' 404 ' && {
    fail "$PKG" '$DEAD = NOPE'
    continue
  }

  skip "$PKG" "\$DEAD = $DEAD"
  sleep "$LONG_WAIT"
done < <( cut -d':' -f1 < "${PREFIX}ZOMBIE.txt" )

echo -e "\n==> DONE" >&2
