#!/bin/bash

 . lpcsbclass

mar='--new-chroot --bootstrap-chroot'
mck () {
  local c=
  [[ -n "$cnf" ]] && c="-r $cnf"

  local a="$1"
  shift
  grep -qE '\S*\.src\.rpm$' <<< "$a" || a="-$a"

  while [[ -n "$1" ]]; do a="$a '$1'" ; shift ; done

  bash -c "set -x ; mock $mar -n --result=./result $c $a $@"
  return $?
}

[[ "$1" == "-v" ]] && {
  VER="$1"
  shift
} || VER=

[[ "$1" == "-g" ]] && {
  G2R="$1"
	shift
} || G2R=

[[ "$1" == "-f" ]] && {
  FAST="$1"
  shift
} || FAST=

[[ "$1" == "-k" ]] && {
  KEEP="$1"
  shift
} || KEEP=

[[ "$1" == "-e" ]] && {
  FED="f$1"
  shift
} || FED=master # <<<<<<<<<<<<<<<

[[ "$1" ]] || die "arg"

[[ "$1" == "-r" ]] && {
  REV="$1"
  shift
  [[ "$1" ]] || die "arg rev"
} || {
  mkdir -p "$1" || die "mkd"

  cd "$1" || die "cd"

  [[ "$KEEP" ]] || rm -rf *.spec *.rpm *.gem

  gem fetch "$1" || die "fetch"
  REV=
}

f="`ls *.gem`"
f="`basename -s ".gem" "$f"`"
[[ -r "$f.gem" ]] || die "fle"

gem unpack "$f.gem" || die "unpack"

[[ "$REV" ]] && s="$1" || s="rubygem-${f%-*}.spec"

gem2rpm -o "$s" "$f.gem" || die "spec"

[[ "$G2R" ]] || {
 	echo
 	echo "licensecheck:"
 	licensecheck -r "$f" | grep -vE "UNKNOWN$"
 	echo

	[[ "$REV" ]] || {
 		echo "Edit .spec now :)"
 		echo
 	}

 	mck -clean -q
 	mck -init -q

  echo
  echo "Now we'll be mocking RPM in loop (on failure)."
  echo "Press N to Quit"
  echo

set -x
  bask "Ready" || exit 1

 	SUCC=
 	while echo; do
		fedpkg --release $FED srpm || die "FedPkg"

		rm -rf result/

		mck *.src.rpm && {
			echo -e "\nRebuild ok"

			mar='--new-chroot'

			mck -remove "rubygem-$f"

			mck i `ls result/*.x86_64.rpm` `ls result/*.noarch.rpm` && {
				echo -e "\nInstall ok!"
				SUCC=y
				break
			}
		}

		echo
		bask "Again" || break
 	done
 	echo

 	[[ "$SUCC" ]] || {
		echo "Quit"
		exit 1
 	}

	[[ "$REV" ]] || {
 		mkdir -p orig || die "mk web"

 		pth="$(readlink -e "`dirname "$0"`/rev.sh")"

 		[[ -x "$pth" ]] || die "'$pth' missing or not executable"

		exec "$pth" -g
 	}
}

#[[ "$FAST" ]] || {
#	fedpkg --release $FED scratch-build --srpm || die "Scratch"
#}
