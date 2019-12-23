#!/bin/bash

set -e
bash -n "$0"

SRC_FPO_RPMS='https://src.fedoraproject.org/api/0/rpms/'

[[ -r PKGS_NO_B.txt ]]
while read PKG; do
  R=0
  USERS="$(
    curl -s "${SRC_FPO_RPMS}${PKG}" \
      | jq -r '.access_users[][]'

  )" || R=1

  [[ $R -eq 0 && -n "$USERS" ]] || {
    echo "$PKG: curl failed" >&2
    continue
  }

  USERS="$(
    echo "$USERS" \
      | grep -v '^orphan$' \
      | sort -u \
      | xargs -i echo -n ",{}" | cut -d',' -f2-
  )"

  [[ -z "$USERS" ]] && {
    echo "${PKG}" >> PKGS_ORPHAN.txt
    :
  } || {
    echo "${PKG}: ${USERS}" | tee -a PKGS_ZOMBIE.txt
    :
  }
  sleep 0.01

done < PKGS_NO_B.txt

echo "==> DONE" >&2
