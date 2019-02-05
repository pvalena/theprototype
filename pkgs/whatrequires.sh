#!/bin/bash
#
# ./whatrequires.sh GEM1 GEM2 GEM3
#   Looks up dependencies using `dnf repoquery` in 'rawhide*' repos.
#   You need to have `rawhide` repos installed.
#   Auto-fills rubygem(GEM) or rubygem-GEM.
#   Does lookup for both Requires and BuildRequires(--arch=src).
#
#   Run it as a same user you run dnf(f.e. with sudo)
#

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
#   Output all - debug
#   "echo -e '{}:' ; $xdnf repoquery --${D} '{}' | grep '${g}'"

done
echo

