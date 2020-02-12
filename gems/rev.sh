#!/bin/bash

. lpcsbclass

baskc () {
  bask "Continue" || die "-->User Quit"
}

checkdebug "$1" && shift

[[ "$1" == "-g" ]] && {
  G2R="$1"
  shift
} || G2R=

[[ "$1" == "-s" ]] && {
  SIM="$1"
  shift
} || SIM=

[[ "$1" == "-v" ]] && {
  VER="$1"
  shift
} || VER=

rm -f *.gem

DIR="$(readlink -e "`dirname "$0"`")"
[[ -n "$DIR" && -d "$DIR" ]] || die "mydir"

[[ -d orig ]] && {
  mkdir -p bak || die 'bak dir'
  mv -v orig "bak/`date -Iseconds`"
}
mkdir -p orig || die 'orig dir'

os="`ls *.spec`" || die 'orig spec'
of="`ls *.src.rpm`" || die 'orig srpm'
[[ -r "$os" && -r "$of" ]] || die "orig"
cp -v "$os" orig/ || die 'cp spec'
cp -v "$of" orig/ || die 'cp srpm'

s="`ls orig/*.spec`"
f="`ls orig/*.src.rpm`"
[[ -r "$s" ]] || die "spec fle"
[[ -r "$f" ]] || die "src fle"

rpm2cpio "$f" | cpio -idmv --no-absolute-filenames
rpmlint -i "$f" "$s"

l="`basename "$s"`"
[[ -r "$l" ]] || die "spec rpm fle"
dff "$l" "$s" || die "dff spec"
baskc

[[ "$SIM" ]] && t="$l" || {
  mkdir -p test || die "mkd test"
  rm -rf test/*
  t="test/$l"

  pth="$DIR/g2r.sh"
  debug "pth = '$pth'"
  [[ -r "$pth" ]] || die "'$pth' missing"
  pth="$(escape "$pth")"

  debug "$pth $FAST $G2R $NOC $VER -r \"$t\""
  eval "$pth $FAST $G2R $NOC $VER -r \"$t\"" || die "g2r"
}

[[ "$t" && -r "$t" ]] || die "new spec fle: '$t'"

x="`ls *.gem`"
x="`basename -s ".gem" "$x"`"
[[ "$x" && -r "$x.gem" ]] || die 'Gem file missing #1'

# TODO: chroot this
# ruby -e "p(require '$x')"

[[ -n "$FAST$SIM" ]] || {
  dff "$t" "$l"

  ls result/*.rpm | while read p; do
    echo ">>> `cut -d'/' -f2- <<< "$p"`"
    set -xe
    rpm -qp "$p" --provides
    rpm -qp "$p" --requires
    rpm -qp "$p" --recommends
    rpm -qp "$p" --suggests
    rpm -qp "$p" --enhances
    rpm -qp "$p" --conflicts
    rpm -qlp "$p"
    { set +xe ; } &>/dev/null
    echo
  done 2>&1 | lss || die 'Failed to query rpm'
  baskc
}

 l="`basename -s ".spec" "$l"`"

 mv -v "$x.gem" "orig/"

 gem fetch "`sed -e 's/^rubygem-//' <<< "$l"`" || die 'Gem fetch failed'
 [[ "$x" && -r "$x.gem" ]] || die 'Gem file missing #2'

 cmp "$x.gem" "orig/$x.gem" || die 'Gem file is different'

 [[ -d "$x" ]] || die "src dir: '$x'"

[[ "$FAST" ]] || {
  find "$x" -type f -exec sh -c "file -i {} | grep -v binary >/dev/null" \; -print | while read e; do lss "$e"; done
  baskc
}

 echo -e "\nBinary:"
 find "$x" -type f -exec sh -c "file -i {} | grep binary >/dev/null" \; -print
 baskc

 echo -e "\nPkgDb-cli:"
 pkgdb-cli list --branch master "$l"
 baskc

[[ -d "$l" ]] && {
 	rm -rf "$l/" || die "failed to remove '$l/'"
}

[[ -n "$SIM" ]] || {
  fedora-review -r -n "$f" || die "fedora-review failed"
  y="$l/review.txt"
  [[ -f "$y" ]] || die "review.txt not found"
  set -xe
  exec nn "$y"
}
