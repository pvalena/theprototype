#!/bin/bash
#
# 1] Set correct rawhide in railsbuild-common
# 2] Set VARIABLES
#
# Usage:
# ./upd.sh [-c][-n][-k][-c]
#	  -n	skip nobuild test
#	  -l	skip local builds
#	  -k	continue local build (do not clean data for local build, implies '-n')
#	  -c	continue real build (do not clean data, implies '-n' and '-l')
#

 RAILSBUILD_DIR="$(readlink -e "`dirname "$0"`/../../../../rails/railsbuild/")"

################################

  . lpcsbclass

 uxit () {
 	echo "User Quit" 2>&1
 	exit 1

 }

 CDIR="`pwd`"

 [[ -d "$RAILSBUILD_DIR" ]] || die "RailsBuild dir missing!"
 [[ -r "$RAILSBUILD_DIR/railsbuild" ]] || die "RailsBuild script missing!"

 NOB=Y
 LOC=Y
 KLEA=Y
 CLEA=Y

while [[ "${1:0:1}" == '-' && "${1:2:1}" == '' ]]; do
  case "${1:1:1}" in
    [nN]) NOB=
      ;;

    [lL]) LOC=
      ;;

    [kK]) KLEA=
          NOB=
      ;;

    [cC]) CLEA=
          NOB=
          LOC=
      ;;

    *) die "Unknown arg '$1'"
      ;;

  esac

  shift
done

 FROM_VERSION="${1:-5.1.2}"

 TO_VERSION="${2:-5.1.3}"

 UPDATE_WHERE="${3:-28}"

 [[ "$4" ]] && die "Redundant arg: '$4'"

 cd "$(dirname "`readlink -e "$0"`")" || die "Failed to cd"

 bask "Update rails in fedora $UPDATE_WHERE from v. $FROM_VERSION to v. $TO_VERSION" || uxit

 grep ^FEDORA_RAWHIDE $RAILSBUILD_DIR/railsbuild-common || die "No rawhide version found in railsbuild-common"
 bask "Does railsbuild-common contain correct rawhide version" || uxit

 [[ "$NOB" ]] && {
	rm -rf ~/.railsbuild

 	echo " >>> Running nobuild <<< "

 	$RAILSBUILD_DIR/railsbuild -n "$UPDATE_WHERE" "$FROM_VERSION" "$TO_VERSION" || die "Nobuild failed"

	X="`readlink -e $HOME/.railsbuild/f$UPDATE_WHERE`"

  [[ -d "$X" ]] || die 'railsbuild folder nonexistent'

  cd "$X" || die "cd '$X' failed"

	ls | while read x; do
	  cd "$X/$x" || die "cd '$X/$x' failed"
	  git diff

	done

  cd "$CDIR"

 	echo -e "\n\n >>> Nobuild successful <<< \n"

	CLEA=Y
	KLEA=

 }

 bask "Continue" || uxit

 [[ "$LOC" ]] && {
  [[ "$KLEA" ]] && rm -rf ~/.railsbuild

 	echo " >>> Running local build <<< "

 	$RAILSBUILD_DIR/railsbuild -l "$UPDATE_WHERE" "$FROM_VERSION" "$TO_VERSION" || die "Local build failed"

	X="`readlink -e $HOME/.railsbuild/f$UPDATE_WHERE`"

  [[ -d "$X" ]] || die 'railsbuild folder nonexistent'

  cd "$X" || die "cd '$X' failed"

	ls | while read x; do
	  cd "$X/$x" || die "cd '$X/$x' failed"
	  echo " > `pwd`"
	  git status

	done

  cd "$CDIR"

 	echo -e "\n\n >>> Local build finished <<< \n"

	CLEA=Y

 }

 bask "Run *REAL* build (this deletes '~/.railsbuild')!" || uxit

 echo " >>> Running build <<< "

 [[ "$CLEA" ]] && rm -rf ~/.railsbuild

 fst=y
 while :; do
	$RAILSBUILD_DIR/railsbuild "$UPDATE_WHERE" "$FROM_VERSION" "$TO_VERSION" && break

	[[ "$fst" ]] || die "Build failed"
	fst=

	echo -e "\n\n >>> Retrying build <<< \n"

 done

 echo -e "\n >>> Build successful <<< "
