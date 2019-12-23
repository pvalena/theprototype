#!/bin/bash

set -e
bash -n "$0"

PDC_PRODUCT_VERSIONS='https://pdc.fedoraproject.org/rest_api/v1/product-versions/'
SRC_FPO_PROJECTS='https://src.fedoraproject.org/api/0/projects'

# ACTIVE_FEDORAS => 29|30|31
# - get JSON from PDC
# - filter versions
# - filter out rawhide
# - join with |
ACTIVE_FEDORAS="$(
  curl -s "${PDC_PRODUCT_VERSIONS}?active=true&short=fedora&fields=version" \
    | jq -r '.results[].version' \
    | grep -v '^rawhide$' \
    | xargs -i echo -n "|{}" | cut -d'|' -f2-
)"
[[ -n "$ACTIVE_FEDORAS" ]]

[[ -r PKGS.txt ]]
while read PKG; do
  BRANCHES="$(
    curl -s "https://src.fedoraproject.org/api/0/rpms/${PKG}/git/branches" \
      | jq -r '.branches[]' \
      | cut -d'f' -f2- \
      | grep -E "^(${ACTIVE_FEDORAS})$" \
      | xargs -i echo -n ",{}" | cut -d',' -f2-
  )"

  [[ -z "$BRANCHES" ]] && {
    echo "$PKG" | tee -a PKGS_NO_B.txt
    :
  } || {
    echo "${PKG}: ${BRANCHES}" >> PKGS_B.txt
    :
  }

  sleep 0.01
done \
  < PKGS.txt

echo "==> DONE" >&2
