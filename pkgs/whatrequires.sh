#!/bin/bash

xdnf="dnf -q --disablerepo='*' --enablerepo='rawhide*'"
C=whatrequires
D=requires

for g in "$@"; do
  echo -e "\n\n--> $g"

  for a in '' --arch=src ; do
  for z in -$g "($g)"; do
      bash -c "$xdnf repoquery ${a} --${C} 'rubygem${z}'"
  done
  done \
  | rev | cut -d'-' -f3- | rev | sort -u \
  | xargs -i bash -c "
    O=\"\$($xdnf repoquery --${D} '{}' | grep '${g}' | grep '<')\"
    [[ \"\$O\" ]] && echo -e \"{}:\n\$O\n\"
  "

#   "echo -e '{}:' ; $xdnf repoquery --${D} '{}' | grep '${g}'"

done
echo

