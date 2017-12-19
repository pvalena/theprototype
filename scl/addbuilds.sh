#!/bin/bash
# WIP

 EPOPUP=n

  . lpcsbclass

 checkdebug "$1" && shift

 [[ "$1" ]] || die "Arg Missing"

exit 1

r="rhscl-2.2-rh-ror41-rhel-6"
v="4.1.5-6"
E=24506
for SCL in rh-ror41 ; do for SV in 2 ; do for EL in 7 6 ; do
b="rhscl-2.${SV}-${SCL}-rhel-${EL}"
git c "$b" || { echo RRR ; break ; }
echo -e "\n --> $b"
brew wait-repo --timeout=3000 ${b}-build --build="${SCL}-`basename $PWD`-${v}.el${EL}
rhpkg errata --erratum $E add-builds 2>&1 | tr -s ',' '\n' | tr -s ' ' | grep -i rhscl | grep -i "^ rhel-${EL}" | grep -vi client$
while read p; do rhpkg errata --erratum $E add-builds --product $p & ; sleep 30 ; done
done ; done ; done ; echo

jobs | grep 'rhpkg errata --erratum $E add-builds --product $p' | cut -d']' -f1 | cut -d'[' -f2 | while read z; do kill -15 %$z ; done
