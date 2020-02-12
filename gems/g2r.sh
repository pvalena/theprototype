#!/bin/bash

 . lpcsbclass

bash -n "$0" || exit 7

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
pre='rubygem-'

[[ "$1" == "-e" ]] && {
  FED="f$1"
  shift
} || FED=f32 # <<<<<<<<<<<<<<<

[[ "$1" == "-f" ]] && {
  FAST="$1"
  shift
} || FAST=

[[ "$1" == "-g" ]] && {
  G2R="$1"
	shift
} || G2R=

[[ "$1" == "-k" ]] && {
  KEEP="$1"
  shift
} || KEEP=

[[ "$1" == "-v" ]] && {
  VER="$1"
  shift
} || VER=

[[ "$1" ]] || die "arg"

[[ "$1" == "-r" ]] && {
  REV="$1"
  shift
  [[ "$1" ]] || die "arg rev"
  :
} || {
  mkdir -p "${pre}$1" || die "mkd"

  cd "${pre}$1" || die "cd"
}

[[ "$1" ]] || die "arg"
f="rubygem-$1"
s=

[[ -n "$REV" ]] \
  && s="$1" \
  || {
    s="rubygem-$1.spec"
    mkdir -p "$f" || die "mkd"

    cd "$f" || die "cd"

    [[ "$KEEP" ]] || rm -rf *.spec *.rpm *.gem
    # Fetch using gem2rpm instead
    #gem fetch "$1" || die "fetch"
    REV=
  }

gem2rpm --fetch -t fedora-27-rawhide -o "$s" "$f.gem" || die "spec"

[[ -r "$f.gem" ]] || die "fle"
gem unpack "$f.gem" || die "unpack"

git init || die 'init'

echo "${f}-*.gem" >> .gitignore || die 'ignore'

for x in `spectool -S *.spec | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev` ; do
  echo "SHA512 ($x) = `sha512sum "$x" | cut -d' ' -f1`"
done > sources || die 'sources'

git add .gitignore sources *.spec || die 'add'

git commit -am 'Initial commit.' || die 'commit'

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
