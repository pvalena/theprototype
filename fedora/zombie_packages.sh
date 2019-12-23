#!/bin/bash

set -e
bash -n "$0"

PDC_PRODUCT_VERSIONS='https://pdc.fedoraproject.org/rest_api/v1/product-versions/'
SRC_FPO_PROJECTS='https://src.fedoraproject.org/api/0/projects'
SRC_FPO_RPMS_API='https://src.fedoraproject.org/api/0/rpms/'
SRC_FPO_RPMS_GIT='https://src.fedoraproject.org/rpms/'

WAIT='1'
LONG_WAIT='40'
R=0

RETRY=''
skip () {
  echo "F: $1 -- $2" >&2
  RETRY="${RETRY} $1"
  sleep "${3:-1}"
  :
}
abort () {
  echo "$@" >&2
  exit 1
}
DEBUG=
debug () {
  [[ -z "$DEBUG" ]] || {
    echo -e "$@" &>> DEBUG.log
  }
}

[[ "$1" == '-d' ]] && { DEBUG=y ; shift ; } ||:
[[ -z "$1" ]] || abort ''

# ACTIVE_FEDORAS => 29|30|31
# - get JSON from PDC
# - filter versions
ACTIVE_FEDORAS="$(
  curl -s "${PDC_PRODUCT_VERSIONS}?active=true&short=fedora&fields=version" \
    | jq -r '.results[].version'
)" || R=1
[[ $R -eq 0 ]] || abort '$ACTIVE_FEDORAS' 'curl / jq'
# - filter out rawhide
# - join with |
ACTIVE_FEDORAS="$(
  echo "$ACTIVE_FEDORAS" \
    | grep -v '^rawhide$' \
    | xargs -i echo -n "|{}" | cut -d'|' -f2-
)"
[[ -n "$ACTIVE_FEDORAS" ]] || abort '$ACTIVE_FEDORAS' 'missing'
debug "\$ACTIVE_FEDORAS = $ACTIVE_FEDORAS"

# ACTIVE_EPELS => 6|7|8
# - get JSON from PDC
# - filter versions
ACTIVE_EPELS="$(
  curl -s "${PDC_PRODUCT_VERSIONS}?active=true&short=epel&fields=version" \
    | jq -r '.results[].version'
)" || R=1
[[ $R -eq 0 ]] || abort '$ACTIVE_EPELS' 'curl / jq'
# - filter out rawhide
# - join with |
ACTIVE_EPELS="$(
  echo "$ACTIVE_EPELS" \
    | xargs -i echo -n "|{}" | cut -d'|' -f2-
)"
[[ -n "$ACTIVE_EPELS" ]] || abort '$ACTIVE_EPELS' 'missing'
debug "\$ACTIVE_EPELS = $ACTIVE_EPELS"

i=0
while i=$(( $i + 1 )); do
  PKGS="$(
    curl -s "${SRC_FPO_PROJECTS}?page=${i}&per_page=100&fork=null&short=1&namespace=rpms" \
      | jq -r '.projects[].name'
  )"
  debug "#PKGS = `wc -l <<< "$PKGS"`"
  [[ -n "$PKGS" ]] || {
    [[ -n "$RETRY" ]] || break

    PKGS="$( tr -s ' ' '\n' <<< "$RETRY" )"
    RETRY=''
  }

  #echo "$PKGS" | \
  while read PKG; do
    debug "\n\$PKG = '$PKG'"

    # Double-Check for DEAD
    URL="${SRC_FPO_RPMS_GIT}${PKG}/raw/master/f/dead.package"
    sleep "$WAIT"
    DEAD="$( curl -sI "${URL}" )" || {
      skip "$PKG" "curl -I (DEAD)" "$LONG_WAIT"
      continue
    }
    DEAD="$( head -1 <<< "$DEAD" )"
    [[ -z "$DEAD" ]] && {
      skip "$PKG" "\$DEAD = EMPTY"
      continue
    }
    debug "\$DEAD = '$DEAD'"

    grep -q ' 404 ' <<< "$DEAD" && continue ||:
    grep -q ' 200 ' <<< "$DEAD" || {
      skip "$PKG" "\$DEAD = $DEAD" "$LONG_WAIT"
      continue
    }

    sleep "$WAIT"
    curl -fs "${URL}" &>/dev/null || {
      skip "$PKG" "curl -f (DEAD)" "$LONG_WAIT"
      continue
    }

    # We're not interested in packages with active branches
    sleep "$WAIT"
    BRANCHES="$(
      curl -s "${SRC_FPO_RPMS_API}${PKG}/git/branches" \
        | jq -r '.branches[]'
    )" && R=0 || R=1
    [[ $R -eq 0 && -n "$BRANCHES" ]] || {
      skip "$PKG" "curl / jq(BRANCHES)" "$LONG_WAIT"
      continue
    }
    debug "\$BRANCHES = `tr -s '\n' ',' <<< "$BRANCHES"`"
    # Filter out Active Fedoras
    echo "$BRANCHES" \
      | grep -E '^f[0-9]*$' \
      | cut -d'f' -f2- \
      | grep -qE "^(${ACTIVE_FEDORAS})$" \
      && continue
    # Filter out active EPELs
    echo "$BRANCHES" \
      | grep -qE '^(ep)?el[0-9]*$' \
      | cut -d'l' -f2- \
      | grep -qE "^(${ACTIVE_EPELS})$" \
      && continue

    # We're no interested in orphaned packages
    sleep "$WAIT"
    USERS="$(
      curl -s "${SRC_FPO_RPMS_API}${PKG}" \
        | jq -r '.access_users[][]'
    )" || {
      skip "$PKG" "curl / jq(USERS)" "$LONG_WAIT"
      continue
    }
    debug "\$USERS = `tr -s '\n' ',' <<< "$USERS"`"
    [[ "$USERS" == 'orphan' ]] && continue

    # At this point it's dead, has no active branches, but has users
    echo "$PKG"

  done < <( echo "$PKGS" )
done

debug "\n==> DONE"
