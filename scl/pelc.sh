#!/bin/bash
#
# ./pelc.sh [-b VER] [-c] [-r RHL] [-w WID] SCL [SCL [...]]
#
#   Compare package licences in upstream.
#   Needs listpkgs.sh script in same directory.
#   Options need to supplied in alphabetical order
#
# Options:
#   -b  VER   version of RH software collections
#   -c        do a clone+pull+checkout+sources...
#   -d        debug output
#   -r  RHL   rhel version
#   -w  WID   columnes width, starts \w #2, sep. by ','
#
# Defaults:
#       VER   2.4
#       RHL   7
#       WID   30,30,40,30
#
# Mandatory:
#       SCL   name of collections; can be specified multiple times
#
#

 stx () { [[ "$DEBUG" ]] || return 0 ; echo "set -x" ; }
 err () { `stx` ; printf " ! $x : $1\n" >&2 ; }
 die () { `stx` ; err "$1" ; [[ "$2" ]] || git status ; exit 1 ; }
 deb () { [[ "$DEBUG" ]] || return 0 ; echo -e " # $x : $@" ; }
 nam () { x="`grep -q '^rubygem-' <<< "$1" && cut -d'-' -f2- <<< "$1" || echo "$1"`" ; }

 OUT=''
 w0=0
 put () {
  echo "$OUT"
  OUT=''
  w0=0

 }

 out () {
  [[ "$1" ]] || out ' '

  while [[ "$1" ]]; do
    let 'w0 += 1'
    eval "w=\$w$w0"
    OUT="$OUT | `printf "%-${w}s" "$1"`"

    shift

  done

 }

 [[ "$1" == "-b" ]] && { shift ; b="$1" ; shift ; } || b='2.4'
 [[ "$1" == "-c" ]] && { c='' ; shift ; } || c="yes"
 [[ "$1" == "-d" ]] && { DEBUG="$1" ; shift ; } || DEBUG=
 [[ "$1" == "-g" ]] && { shift ; g="$1" ; shift ; } || g=
 [[ "$1" == "-r" ]] && { shift ; r="$1" ; shift ; } || r=7
 [[ "$1" == "-w" ]] && { shift ; w="$1" ; shift ; } || w=30,30,40,30

 [[ "$1" ]] || die "Please specify SCL" nogit

 myd="$(readlink -e "`pwd`")"
 fst="$c" # runs `rhpkg co` checkout, git checkout etc. if set to nonempty
 w="0,$w,0"
 mylist="$(readlink -e "`dirname "$0"`/listpkgs.sh")"

 for i in {1..100}; do
  eval "w$i='`cut -d',' -f$i <<< "$w"`'"

 done

 [[ -x "$mylist" ]] || die 'No listpkgs.sh found: $mylist' nogit
 [[ -n "$myd" && -d "$myd" ]] || die "Invalid working directory" nogit

while [[ "$1" ]] ; do
  scl="$1"
  bra="rhscl-${b}-${scl}-rhel-${r}"
  x='unknown'

  deb "bra = '$bra'"

  lst="$($mylist ${bra}-build ${scl}- | grep '^rubygem-')"

  while read z; do
    nam "$z"
    wx="${#x}"
    [[ $wx -gt $w1 ]] && w1=$wx

  done <<< "$lst"

  deb "lst = >>>\n$lst\n<<<\n"

  out 'package' 'specfile' 'gemspec' 'licensecheck' 'licensee' 'oscrypto'
  put
  out '-------' '--------' '-------' '------------' '--------' '--------'
  put

  while read z; do
    nam "$z"
    OUT=
    w0=0
    out "$x"
    cd "$myd" || die "Failed to cd '$myd'" nogit

    [[ -z "$fst" || -d "$z" ]] || { rhpkg co "$z" &>/dev/null ; }
    [[ -d "$z" ]] || die "directory '$z' missing" nogit
    cd "$z" || die "failed to cd '$z'" nogit

    deb "`pwd`"

    [[ "$fst" ]] && {
      `stx`
      git fetch &>/dev/null || die "failed to fetch"
      git checkout "$bra" &>/dev/null || die "failed to checkout '$bra'"
      git pull &>/dev/null || die "failed to pull"
      rm *.gem &>/dev/null
      rm *.rpm &>/dev/null
      rhpkg sources &>/dev/null || die "failed to fetch sources"
      /home/vagrant/Work/RH/git/scripts/pkgs/download-builds.sh -b -x "${scl}-$z" "el$r" &>/dev/null || err "failed to download RPMs"

    }

    [[ "`git branch | grep '^*' | cut -d' ' -f2`" == "$bra" ]] || die "invalid branch"

    f="$z.spec"
    [[ -r "$f" ]] || die "spec file '$f' missing"
    SF="`tr -s '\t' ' ' < "$f" | grep '^License:' | cut -d' ' -f2-`" || die "spec file license failed"

    JSF=
    while read j; do JSF="$JSF & $j" ; done <<< "$SF"
    out "`cut -d' ' -f3- <<< "$JSF"`"

    g="`ls ${x}-*.gem 2>/dev/null`"
    [[ -n "$g" && -r "$g" ]] || { err "gem file '$g' missing(not a rubygem?)" ; continue ; }

    b="`basename -s '.gem' "$g"`"
    [[ "$b" ]] || die "invalid gem file '$g'"

    d="./$b/"
    rm -rf "$d" &>/dev/null
    gem unpack "$g" &>/dev/null || die "gem unpack failed"
    [[ -d "$d" ]] || die "sources dir '$d' missing"

    s="$d$b.gemspec"
    [[ -r "$s" ]] || {
      gem spec "$g" --ruby -l > "$s" || die "gem spec failed"

    }

  [[ -r "$s" ]] || die "gemspec file '$s' missing"

  ss="`ls ${d}*.gemspec 2>/dev/null`"
  [[ "$ss" ]] || die "gemspec files not found"

  JGS=
  while read s; do
    while read gs; do
      [[ "$gs" ]] && JGS="$JGS & $gs"

    done < <(grep '\.licenses = \[\"' < "$s" | tr -s '\t' ' ' | cut -d'"' -f2- | rev | cut -d'"' -f2- | rev | tr -s '"' ',' | tr -s ',' '\n')

  done <<< "$ss"
  out "`cut -d' ' -f3- <<< "$JGS"`"

  cd "$d" || die "failed to cd to sources dir '$d'"

  JSF=
  while read j; do JSF="$JSF & $j" ; done < <(
    licensecheck -c '.*' -i '' -l 200 -m -r * | tr -s '\t' ' ' | grep -vE ' (UNKNOWN|GENERATED FILE)$' \
      | xargs -n1 -i bash -c "c=0 ; while [[ \$c -lt 1000 ]]; do let 'c += 1' ; [[ -r \"\$(cut -d' ' -f-\${c} <<< '{}')\" ]] && { let 'c += 1' ; cut -d' ' -f\${c}- <<< '{}' ; exit 0 ; } ; done ; echo 'NOPE {}' >&2 ; exit 1" \
      | sort -u

    )
  out "`cut -d' ' -f3- <<< "$JSF"`"

  JSF=
  while read j; do JSF="$JSF & $j" ; done < <(
    scl enable rh-ruby23 -- licensee | grep '^License: ' | cut -d' ' -f2- | sort -u

    )
  out "`cut -d' ' -f3- <<< "$JSF"`"

  [[ "`oscryptocatcher . | grep content | grep -v '"content": \[\],'`" ]] && out "content" || out

  put

 done <<< "$lst"

 echo
 shift

done