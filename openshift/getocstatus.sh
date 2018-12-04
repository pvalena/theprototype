#!/bin/bash
#
# ./getocstatus.sh [interval]
#

i="${1:-10}"

main () {
  oc api-resources \
    | tr -s ' ' \
    | cut -d' ' -f1 \
    | sort -u \
    | grep -vE '^(all|podpreset|serviceaccounts|rolebindings|clusterroles|events|persistentvolumes|imagestreamtags|projects|secrets|projectrequests|imagestreammappings|bindings|userserror\:)$' \
    | while read n; do
      d="$(
        { oc get "$n" ; } 2>&1 \
          | grep -v '^No resources found.$' \
          | grep -v '^Error from server (Forbidden): ' \
          | grep -v '^Error from server (NotFound): ' \
          | grep -v "^error: the server doesn't have a resource type " \
          | grep -v "^The connection to the server " \
      )"
      [[ -z "$d" ]] && continue

      echo -e "\n >>> $n\n$d"
    done
}

P=
while X="`main`"; do
  [[ "$P" == "$X" ]] && continue

  clear
  echo "$X"

  P="$X"
  sleep $i
done
