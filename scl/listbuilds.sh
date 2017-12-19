#!/bin/bash
# WIP

 EPOPUP=n

  . lpcsbclass

 checkdebug "$1" && shift

 [[ "$1" ]] || die "Arg Missing"

exit 1

for SCL in rh-ror4{1,2} ror40 ruby193; do for SV in 2 3; do for EL in 6 7; do
r="rhscl-2.${SV}-${SCL}-rhel-${EL}-build"
echo -e "\n --> $r"
~/Work/RH/my/scl/listpkgs.sh -k $r ${SCL}-rubygem- | grep -E "^acti(verecord|onpack|onview)-"
done ; done ; done
