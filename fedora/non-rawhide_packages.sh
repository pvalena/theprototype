#!/bin/bash

set -e
bash -n "$0"

PDC_PRODUCT_VERSIONS='https://pdc.fedoraproject.org/rest_api/v1/product-versions/'
SRC_FPO_RPMS='https://src.fedoraproject.org/api/0/rpms/'
PREFIX='PKGS_'
WAIT='1'
LONG_WAIT='40'
R=0

rm "${PREFIX}SKIP.txt" &>/dev/null ||:
touch "${PREFIX}ZOMBIE_NR.txt" "${PREFIX}SKIP.txt" "${PREFIX}FAIL.txt"

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

# ACTIVE_FEDORAS => 29|30|31
# - get JSON from PDC
# - filter versions
ACTIVE_FEDORAS="$(
  curl -s "${PDC_PRODUCT_VERSIONS}?active=true&short=fedora&fields=version" \
    | jq -r '.results[].version'
)" || R=1
[[ $R -eq 0 ]] || abort '$ACTIVE_FEDORAS' "curl / jq"
[[ -n "$ACTIVE_FEDORAS" ]] || abort '$ACTIVE_FEDORAS'
# - filter out rawhide
# - join with |
ACTIVE_FEDORAS="$(
  echo "$ACTIVE_FEDORAS" \
    | grep -v '^rawhide$' \
    | xargs -i echo -n "|{}" | cut -d'|' -f2-
)"
[[ -n "$ACTIVE_FEDORAS" ]] || abort '$ACTIVE_FEDORAS(2)'

echo -e "\$ACTIVE_FEDORAS = $ACTIVE_FEDORAS\n" >&2

[[ -r "${PREFIX}ZOMBIE.txt" && -r "${PREFIX}ZOMBIE_NR.txt" && -r "${PREFIX}SKIP.txt" && -r "${PREFIX}FAIL.txt" ]] || abort "Files unreadable"

while read PKG; do
  # Skip already checked
  grep -q "^${PKG}$" "${PREFIX}ZOMBIE_NR.txt" && {
    skip "$PKG" 'ZOMBIE_NR.txt'
    continue
  }
  grep -q "^${PKG}: " "${PREFIX}FAIL.txt" && {
    skip "$PKG" 'FAIL.txt'
    continue
  }

  sleep "$WAIT"

  # Check for branches
  BRANCHES="$(
    curl -s "${SRC_FPO_RPMS}${PKG}/git/branches" \
      | jq -r '.branches[]'
  )" || R=1
  [[ $R -eq 0 ]] || {
    skip "$PKG" "curl / jq(BRANCHES)"
    sleep "$LONG_WAIT"
    continue
  }
  [[ -n "$BRANCHES" ]] || {
    fail "$PKG" '$BRANCHES'
    continue
  }
  BRANCHES="$(
    echo "$BRANCHES" \
      | grep -E '^f[0-9]*$' \
      | cut -d'f' -f2- \
      | grep -vE "^(${ACTIVE_FEDORAS})$" \
      | xargs -i echo -n ",{}" | cut -d',' -f2-
  )"
  [[ -z "$BRANCHES" ]] && {
    fail "$PKG" "\$BRANCHES = ACTIVE"
    continue
  }

  echo "$PKG" >> "${PREFIX}ZOMBIE_NR.txt"

done < <( sort -R "${PREFIX}ZOMBIE.txt" | cut -d':' -f1 )

echo -e "\n==> DONE" >&2
