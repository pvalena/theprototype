#!/bin/bash

set -e
bash -n "$0"

abort () {
  echo "$@" >&2
  exit 1
}

SRC_FPO_API='https://src.fedoraproject.org/api/0'

myd="$(readlink -e "`dirname "$0"`")"
lst="${myd}/list_packages.sh"

[[ -x "$lst" ]] || abort 'cannot access list_packages'

u="$1"
[[ -n "$u" ]] || u="$USER"
[[ -n "$u" ]] || abort 'No username specified'

bash -c "${lst} '$u'" \
| while read pkg; do

  URL="${SRC_FPO_API}/rpms/$pkg"

  R="$(curl -s "$URL" | jq -r '.access_users.owner[]')" \
    || abort "Curl / jq failed for URL: '$URL'"

  [[ "$R" == "$u" ]] && echo "$pkg"
done

