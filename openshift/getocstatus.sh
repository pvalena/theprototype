#!/bin/bash
#
# ./getocstatus.sh [interval]
#

i="${1:-10}"

main () {
  {
    oc get
    echo " * templates"
  } 2>&1 | grep '^ *' | tr -s '\t' ' ' | cut -d' ' -f3 | sort -u \
    | grep -vE '^(all|podpreset|serviceaccounts|rolebindings|clusterroles|events|persistentvolumes|imagestreamtags|projects|secrets|userserror\:)$' \
    | while read n; do
      d="$(
        { oc get "$n" ; } 2>&1 \
          | grep -v '^No resources found.$' \
          | grep -v '^Error from server (Forbidden): ' \
          | grep -v '^Error from server (NotFound): ' \
          | grep -v "^error: the server doesn't have a resource type " \
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
