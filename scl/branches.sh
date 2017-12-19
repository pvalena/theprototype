#!/bin/bash
# WIP

 EPOPUP=n

  . lpcsbclass

 checkdebug "$1" && shift

 [[ "$1" ]] || die "Arg Missing"

exit 1

clear ; echo
for PAC in acti{verecord,on{pack,view}}; do
cd ~/Work/RH/scl/rhel/ror/rubygem-${PAC} || break
pwd
for SCL in rh-ror4{1,2} ror40 ruby193; do
for SV in 2 3; do
r="origin/rhscl-2.${SV}-${SCL}-rhel-6"
b="origin/rhscl-2.${SV}-${SCL}-rhel-7"
[[ -z "`git d "$b" "$r"`" ]] || {
echo -e "$b: BRANCHES\n"
git d "$b" "$r"
read -q '?CoNtInUe! '
}
done
for EL in 6 7; do
r="origin/rhscl-2.2-${SCL}-rhel-${EL}"
b="origin/rhscl-2.3-${SCL}-rhel-${EL}"
[[ -z "`git d "$b" "$r"`" ]] || {
echo -e "$b: VERSIONS\n"
git d "$b" "$r"
read -q '?CoNtInUe! '
}
done ; done ; done ; echo
