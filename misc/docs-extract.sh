#!/bin/bash
# ./docs-extract.sh https://access.redhat.com/documentation/en-US/Red_Hat_Software_Collections/2/html-single/2.{0,1,2,3,4}_Release_Notes/index.html


while read N ; do
  read C
  read V

  echo "$N|$C|$V"

  #grep -q '*' <<< "$C" && L='*' || L=
  #C="$(sed "s/\*//g" <<< "$C")"
  #V="$(sed "s/RHEL//g" <<< "$V")"
  #[[ -n "$v" ]] && echo ">$N|$C|$V<"
  #r="$(sed "s/\$name/$N/g" <<< "$O")"
  #r="$(sed "s/\$scl/$C/g" <<< "$r")"
  #r="$(sed "s/\$version/$V/g" <<< "$r")"
  #r="$(sed "s/\$eol/$L/g" <<< "$r")"
  #bash -c "$r"
done < <(
  while [[ "$1" ]] ; do
    curl -s "$1" | sed -e 's/<\/span> \*/\*<\/span>/g' | tr -s '>' '\n' \
      | grep -A 10000000 'All Available Software Collections' \
      | grep -B 10000000 'Changes in Red Hat Software Collections' \
      | grep -v '^<' \
      | grep -E "</(span|strong|td)$" \
      | cut -d'<' -f1 \
      | tail -n +2

    shift
  done
)
