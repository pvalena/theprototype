#!/bin/bash
#
# ./pelc.sh [options] PKG [PKG [...]]
#
# Summary:
#     View package(s) licences and cryptography algorithms.
#
#     Uses various tools like licensecheck, oscryptocatcher,
#     licensee gem, gem(optional), primitive '.spec' file checks,
#     and print results thereof in a form of table.
#
# Requirements:
#     tools that are mentioned above
#     ruby or (rh-ruby24 for RHEL / CentOS)
#     rhpkg
#     kerberos ticket
#     checked-out package repositories
#
#     custom scripts:
#       ./download-builds.sh
#
#     Options need to be supplied in alphabetical order and standalone.
#
#     You need to set a type of package to analyze.
#
# Options:
#     -b  BRA   branch name(used only for c)
#     -c        do a git (clone+)checkout+pull+sources...
#     -d        include debuging output
#     -h        show this help
#     -g        package type: gem
#     -p        package type: ???                             # <<< [placeholder]
#     -r  RHL   rhel version
#     -w  WID   columnes width, starts \w #2, sep. by ','
#
# Defaults for options:
#     BRA   rhel-8.0
#     RHL   8
#     WID   30,30,40,30
#
# Mandatory args:
#     PKG   name of a package; can be specified multiple times
#
# Example:
#     ./pelc.sh -b stream-ruby-2.5 -c -g rubygem-mongo
#
# TODO:
#     - remove '.freeze' from gemspec output
#     - option to mute errors
#     - output in html
#     - dedup gemspec output
#     - check oscrypto
#
# Ideas:
#     - output csv format
#     - Use https://github.com/nexB/scancode-toolkit
#        ./scancode  --license --processes 2
#
# Author:
#     Pavel Valena <pvalena@redhat.com>
#
#

set -e
bash -n "$0"

stx () { [[ "$DEBUG" ]] || return 0 ; echo "set -x" ; }
err () { `stx` ; printf "!! $x: $1\n" >&2 ; }
die () { `stx` ; [[ -n "$2" ]] && { git status || : ; } || { usage n | cat ; } ; err "$1" ; exit 1 ; }
deb () { [[ "$DEBUG" ]] || return 0 ; echo -e " # $x : $@" ; }
nam () { x="`grep -q '^$pre' <<< "$1" && cut -d'-' -f2- <<< "$1" || echo "$1"`" ; }

OUT=''
w0=0
put () {
  echo "$OUT"
  OUT=''
  w0=0
}

usage () {
  local mf="`readlink -e "$0"`"
  [[ -r "$mf" ]] || die "$LINENO: Invalid file "

  local N="`cat -n "$mf" | tr -s '\t' ' ' | grep -vE '^ [0-9]+ #' | head -n1 | cut -f2 -d' ' | grep -E '^[0-9]+$'`"

  [[ -n "$N" && $N -gt 2 ]] || die 'No help :('

  let 'N -= 1'

  head -n$N "$mf" | tail -n+2 | cut -d'#' -f2- | ${PAGER-more}
  [[ -n "$1" ]] || exit 0
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

[[ "$1" == "--help" ]] && { usage ; } || :

[[ "$1" == "-b" ]] && { shift ; b="$1" ; shift ; } || b='rhel-8.0'
[[ "$1" == "-c" ]] && { c='yes' ; shift ; } || c=
[[ "$1" == "-d" ]] && { DEBUG="$1" ; shift ; } || DEBUG=
[[ "$1" == "-g" ]] && { shift ; TG="$1" ; } || TG=
[[ "$1" == "-h" ]] && { usage ; } || :
[[ "$1" == "-p" ]] && { shift ; p="$1" ; } || p=
[[ "$1" == "-r" ]] && { shift ; r="$1" ; shift ; } || r=8
[[ "$1" == "-w" ]] && { shift ; w="$1" ; shift ; } || w=30,30,40,30

[[ "${1:0:1}" != '-' ]] || die "$LINENO: Unknown arg or invalid order: '$1'" n
[[ "$1" ]] || die "$LINENO: Please specify PKG" n

myd="$(readlink -e "`pwd`")"
fst="$c"                    # runs `rhpkg co` checkout, git checkout etc. if set to nonempty
w="0,$w,0"
mydown="$(readlink -e "`dirname "$0"`/download-builds.sh")"
bra="${b}"

licensee &>/dev/null && isrhel= || isrhel='scl enable rh-ruby24 --'

for i in {1..100}; do
  eval "w$i='`cut -d',' -f$i <<< "$w"`'"
done

[[ -x "$mydown" ]] || die 'No download-builds.sh found: $mydown' n
[[ -n "$myd" && -d "$myd" ]] || die "$LINENO: Invalid working directory" n

lst=
nl="
"

while [[ -n "$1" ]] ; do
  lst="$lst$nl$1"
  shift
done
lst="`grep -v '^$' <<< "$lst"`"

deb "lst = >>>\n$lst\n<<<\n"

T=
[[ -z "$TG" ]] || { T="gemspec" ; pre='rubygem-' ; }
[[ -z "$p" ]] || { T="" ; pre='???-' ; }          # <<< [placeholder]

[[ -n "$T" ]] || die 'No package type specified'

deb "bra = '$bra'"
deb "pre = '$pre'"

while read z; do
  x='unknown'
  nam "$z"
  wx="${#x}"
  [[ $wx -gt $w1 ]] && w1=$wx
done <<< "$lst"

# padding for T
Tp=$(printf "%-${#T}s" -)

out '-------' '--------' "${Tp// /-}" '------------' '--------' '--------' ; put
out 'package' 'specfile' "$T" 'licensecheck' 'licensee' 'oscrypto' ; put
out '-------' '--------' "${Tp// /-}" '------------' '--------' '--------' ; put

while read z; do
  x='unknown'
  nam "$z"
  OUT=
  w0=0
  out "$x"
  cd "$myd" || die "$LINENO: Failed to cd '$myd'" n

  [[ -z "$fst" || -d "$z" ]] || { rhpkg co "$z" &>/dev/null ; }
  [[ -d "$z" ]] || die "$LINENO: distgit directory '$z' not found" n
  cd "$z" || die "$LINENO: failed to cd '$z'" n

  deb "`pwd`"

  [[ "$fst" ]] && {
    `stx`
    git fetch &>/dev/null || die "$LINENO: failed to fetch"
    rhpkg switch-branch "$bra" &>/dev/null || {
      err "$LINENO: failed to rhpkg switch-branch '$bra'"
      continue
    }
    git checkout "$bra" &>/dev/null || die "$LINENO: failed to checkout '$bra'"
    [[ "`git branch | grep '^*' | cut -d' ' -f2`" == "$bra" ]] || die "$LINENO: not on branch: $bra"
    git pull &>/dev/null || die "$LINENO: failed to pull"
    rm *.gem &>/dev/null || :
    rm *.rpm &>/dev/null || :
                                                                        #//<<< INPUT: additional cleanup
    rhpkg sources &>/dev/null || die "$LINENO: failed to fetch sources"
    $mydown -b -x "$z" "el$r" &>/dev/null || err "$LINENO: failed to download RPMs"
    { set +x ; } &>/dev/null
  }

  f="$z.spec"
  [[ -r "$f" ]] || die "$LINENO: spec file '$f' missing"
  SF="`tr -s '\t' ' ' < "$f" | grep '^License:' | cut -d' ' -f2-`" || die "$LINENO: spec file license failed"

  JSF=
  while read j; do JSF="$JSF & $j" ; done <<< "$SF"
  out "`cut -d' ' -f3- <<< "$JSF"`"

  d=

  # type: gem
  [[ "$TG" ]] && {
    y="`cut -d'-' -f2- <<< "$x"`"
    g="`ls ${y}-*.gem 2>/dev/null`"
    [[ -n "$g" && -r "$g" ]] || { err "$LINENO: gem file '$g' missing(not a rubygem?)" ; continue ; }

    b="`basename -s '.gem' "$g"`"
    [[ "$b" ]] || die "$LINENO: invalid gem file '$g'"

    d="./$b/"
    rm -rf "$d" &>/dev/null
    gem unpack "$g" &>/dev/null || die "$LINENO: gem unpack failed"
    [[ -d "$d" ]] || die "$LINENO: sources dir '$d' missing"

    s="$d$b.gemspec"
    [[ -r "$s" ]] || {
      gem spec "$g" --ruby -l > "$s" || die "$LINENO: gem spec failed"
    }

    [[ -r "$s" ]] || die "$LINENO: gemspec file '$s' missing"

    ss="`ls ${d}*.gemspec 2>/dev/null`"
    [[ "$ss" ]] || die "$LINENO: gemspec files not found"

    # gemspec output
    JGS=
    while read s; do
      while read gs; do
        [[ "$gs" ]] && JGS="$JGS & $gs"
      done < <( grep '\.licenses = \[\"' < "$s" | tr -s '\t' ' ' | cut -d'"' -f2- | rev | cut -d'"' -f2- | rev | tr -s '"' ',' | tr -s ',' '\n' | sort -u | grep -v '^.freeze$' )
    done <<< "$ss"
    out "`cut -d' ' -f3- <<< "$JGS"`"
  }

  # type: ???                                 # <<< [placeholder] \
  [[ "$p" ]] && {
    die NYI
    p="`ls ${x}-*.??? 2>/dev/null`"
    [[ -n "$p" && -r "$p" ]] || { err "$LINENO: gem file '$p' missing(?)" ; continue ; }

    b="`basename -s '.gem' "$p"`"
    [[ "$b" ]] || die "$LINENO: invalid gem file '$p'"

    d="./$b/"
    rm -rf "$d" &>/dev/null
    gem unpack "$p" &>/dev/null || die "$LINENO: gem unpack failed"
    [[ -d "$d" ]] || die "$LINENO: sources dir '$d' missing"

    s="$d$b.gemspec"
    [[ -r "$s" ]] || {
      gem spec "$p" --ruby -l > "$s" || die "$LINENO: gem spec failed"
    }

    [[ -r "$s" ]] || die "$LINENO: gemspec file '$s' missing"

    ss="`ls ${d}*.gemspec 2>/dev/null`"
    [[ "$ss" ]] || die "$LINENO: gemspec files not found"

    JGS=
    while read s; do
      while read gs; do
        [[ "$gs" ]] && JGS="$JGS & $gs"
      done < <(grep '\.licenses = \[\"' < "$s" | tr -s '\t' ' ' | cut -d'"' -f2- | rev | cut -d'"' -f2- | rev | tr -s '"' ',' | tr -s ',' '\n')
    done <<< "$ss"
    out "`cut -d' ' -f3- <<< "$JGS"`"
  }

  [[ -z "$d" ]] && die "$LINENO: no sources dir set"
  cd "$d" || die "$LINENO: failed to cd to sources dir '$d'"

  JSF=
  while read j; do JSF="$JSF & $j" ; done < <(
    licensecheck -c '.*' -i '' -l 200 -m -r * | tr -s '\t' ' ' | grep -vE ' (UNKNOWN|GENERATED FILE)$' \
      | xargs -n1 -i bash -c "c=0 ; while [[ \$c -lt 1000 ]]; do let 'c += 1' ; [[ -r \"\$(cut -d' ' -f-\${c} <<< '{}')\" ]] && { let 'c += 1' ; cut -d' ' -f\${c}- <<< '{}' ; exit 0 ; } ; done ; echo 'NOPE {}' >&2 ; exit 1" \
      | sort -u

  )
  out "`cut -d' ' -f3- <<< "$JSF"`"

  JSF=
  while read j; do JSF="$JSF & $j" ; done < <(
    $isrhel licensee | grep '^License: ' | cut -d' ' -f2- | sort -u
  )
  out "`cut -d' ' -f3- <<< "$JSF"`"

#  [[ "`oscryptocatcher . | grep content | grep -v '"content": \[\],'`" ]] && out "content" || out
#  put

done <<< "$lst"
