#!/bin/bash

set -e
bash -n "$0"

[[ -r PKGS_NO_B.txt && -r PKGS_ZOMBIE.txt ]]

while read PKG; do
  grep -q "^${PKG}$" PKGS_NO_B.txt && {
    echo "${PKG}"
    :
  }

done < PKGS_ZOMBIE.txt

echo "==> DONE" >&2
