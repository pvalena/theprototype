#!/bin/bash

EXT="gz|tgz|xz|gem"

die () {
  echo "--> Error: $1!" 2>&1
  exit 1
}

clean () {
  for e in rpm `tr '|' ' ' <<< "$EXT"`; do
    rm -f *.$e
  done
}

ask () {
  echo
  read -n1 -p ">> $@? " x
  grep -qi '^y' <<< "${x}" || die 'User quit'
  clear
  return 0
}

[[ "$1" == "-f" ]] && {
  die 'NYI'
  shift
	FED="$1"
	shift

} || FED=29 # <<<<<<<<<<<<<<<

[[ "$1" == "-v" ]] && {
  shift
	ver="-v $1"
	shift

} || ver=

 clean
 git fetch || die 'Failed to fetch git'
 git diff
 git log -p
 echo
 git status
 ask 'Reset repository'

 git stash || die 'Failed to stash git'
 git reset --hard origin/master || die 'Failed to reset git'

 fedpkg srpm &>/dev/null || die 'Failed to recreate old srpm'
 sn="$(basename -s '.src.rpm' "`ls *.src.rpm`")"
 clean

 ov="`rpmspec -q --qf '%{VERSION}\n' *.spec | head -1`"
 [[ "$ov" && "$ov" == "$(rev <<< "$sn" | cut -d'-' -f2 | rev)" ]] || die "Old version inconsistency- should be: '$ov'"

 nam="`rpmspec -q --qf '%{NAME}\n' *.spec | head -1`"
 [[ "$nam" ]] || die 'Bad NAME in *.spec'
 [[ "$nam" == "$(rev <<< "$sn" | cut -d'-' -f3- | rev)" ]] || die "Package name inconsistency- should be: '$nam'"
 grep '^rubygem-' <<< "$nam" && nam="`cut -d'-' -f2- <<< "$nam"`"

 gem fetch "$nam" $ver || die "gem fetch failed"
 f="$(basename -s '.gem' "`ls *.gem`")"
 [[ "$f" && -r "$f.gem" ]] || die "Invalid or missing gem file: '$f'"
 [[ "$nam" == "`rev <<< "$f" | cut -d'-' -f2- | rev`" ]] || die "Failed gem name check of file: '$f'"

 xv="`rev <<< "$f" | cut -d'-' -f1 | rev`"
 [[ -z "$ver" ]] && ver="$xv"
 [[ "$ver" == "$xv" ]] || die "Version check failed: '$ver' vs '$xv'"

 [[ "$ver" == "$ov" ]] && die "Version '$ver' is current"

 ls | grep -E "\.($EXT)$" | xargs -i echo ">>> fedpkg new-sources {}"

 M="Update to $nam ${ver}."
 rpmdev-bumpspec -c "$M" -n "$ver" *.spec || die "Failed to bump spec with version '$ver' and message '$M'"
 git commit -am "$M" || die "Failed to commit with message '$M'"

 echo
 gem compare -bk "$nam" "$ov" "$ver"
 ask 'Continue'

 echo
 git status
 ask 'Continue'

 echo
 git show
 ask 'Run review'

 fedpkg srpm || die 'New fedpkg srpm failed'

 rev="$(readlink -f "`dirname "$0"`/rev.sh")"
 [[ -n "$rev" && -x "$rev" ]] || die "Invalid review script: '$rev'"

 clear
 exec "$rev" -f
