#!/bin/bash
#
# ./whatrequires.sh [-v][-d] GEM1 GEM2 GEM3
#   Looks up dependencies using `dnf repoquery` in 'rawhide*' repos.
#   You need to have `rawhide` repos installed.
#   Auto-fills rubygem(GEM) or rubygem-GEM.
#   Does lookup for both Requires and BuildRequires(`--arch=src`).
#   Outputs only entries with upper bound contraint(`<`).
#
#   ! Run it as a same user you run dnf(f.e. with sudo) !
#
#   Options:
#     -v  verbose output (all constraints)
#     -d  debug output (all entries)
#

set -e
bash -n "$0"

xdnf="dnf -q --disablerepo='*' --enablerepo='rawhide*'"
D=requires
C=what$D

[[ "$1" == '-d' ]] && { DEBUG=y ; shift ; } ||:
[[ "$1" == '-v' ]] && { VERBO=y ; shift ; } ||:
[[ "${1:0:1}" != '-' ]] || { echo "Invalid arg: $1" ; exit 1 ; }

for g in "$@"; do
  echo -e "\n--> $g"

  for a in '' --arch=src ; do
    for z in -$g "($g)"; do
      bash -c "$xdnf repoquery ${a} --${C} 'rubygem${z}'"
    done
  done \
  | rev | cut -d'-' -f3- | rev | sort -u \
  | xargs -i bash -c "
    O=\"\$($xdnf repoquery --${D} '{}' | grep '${g}')\"

    [[ -z \"$DEBUG\" ]] && {
      # NOT Debug
      [[ -n \"$VERBO\" ]] && {
        O=\"\$(grep '[><=]' <<< \"\$O\")\"
        :
      } || O=\"\$(grep '<' <<< \"\$O\")\"

      [[ -z \"\$O\" ]] && exit
    }

    echo -e \"{}:\n\$O\n\"
  "
done
