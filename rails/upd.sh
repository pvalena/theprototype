#!/bin/bash
#
# 1] Set correct rawhide in railsbuild-common
# 2] Set VARIABLES
#
# Usage:
# ./rup.sh [-c][-n]
#	-n	NO NOBUILD	skip the test
#	-c	CONTINUE	  do not clean data, implies '-n'
#

 UPDATE_WHERE=26

 FROM_VERSION="5.0.0"

 TO_VERSION="5.0.0.1"

################################

  . lpcsbclass

 uxit () {
 	echo "User Quit" 2>&1
 	exit 1

 }

 [[ "$1" == "-n" || "$2" == "-n" ]] && {
 	NOB=

 } || NOB=Y

 [[ "$1" == "-c" || "$2" == "-c" ]] && {
 	CLEA=
 	NOB=

 } || CLEA=Y

 cd "$(dirname "`readlink -e "$0"`")" || die "Failed to cd"

 bask "Update rails in fedora $UPDATE_WHERE from v. $FROM_VERSION to v. $TO_VERSION" || uxit

 grep ^FEDORA_RAWHIDE ../railsbuild/railsbuild-common || die "No rawhide version found in railsbuild-common"
 bask "Does railsbuild-common contain correct rawhide version" || uxit

 [[ "$NOB" ]] && {
	rm -rf ~/.railsbuild

 	echo " >>> Running nobuild <<< "

 	../railsbuild/railsbuild -n "$UPDATE_WHERE" "$FROM_VERSION" "$TO_VERSION" || die "Nobuild failed"

 	echo -e "\n\n >>> Nobuild successful <<< \n"

	CLEA=Y

 }

 bask "Run real build" || uxit

 echo " >>> Running build <<< "

 [[ "$CLEA" ]] && rm -rf ~/.railsbuild

 fst=y
 while :; do
	../railsbuild/railsbuild "$UPDATE_WHERE" "$FROM_VERSION" "$TO_VERSION" && break

	[[ "$fst" ]] || die "Build failed"
	fst=

	echo -e "\n\n >>> Retrying build <<< \n"

 done

 echo -e "\n >>> Build successful <<< "
