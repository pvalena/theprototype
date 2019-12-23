#!/bin/bash

set -e
bash -n "$0"

abort () {
  echo "$@" >&2
  exit 1
}

PREFIX='PKGS_'

SUF="$1"
[[ -n "$SUF" ]] && SUF="_${SUF}" || abort 'File suffix missing'

[[ -r "${PREFIX}ZOMBIE${SUF}.txt" &&  -r "${PREFIX}ZOMBIE.txt" ]]

while read PKG; do
  grep "^${PKG}: " "${PREFIX}ZOMBIE.txt" || abort "MISSING: $PKG"

done < "${PREFIX}ZOMBIE${SUF}.txt" > "${PREFIX}ZOMBIE${SUF}_U.txt"

echo "==> DONE" >&2
