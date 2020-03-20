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
#     #  ./download-builds.sh - currently not used or required
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
#     -i        ignore non-fatal errors
#     -p        package type: ???                             # <<< [placeholder]
#     -r  RHL   rhel version
#     -w  WID   columnes width, starts \w #2, sep. by ','
#
# Defaults for options:
#     BRA   rhel-8.0
#     RHL   8
#     WID   30,30,30,30,30
#
# Mandatory args:
#     PKG   name of a package; can be specified multiple times
#
# Example:
#     ./pelc.sh -b stream-ruby-2.5 -c -g rubygem-mongo
#
# Ideas:
#     - Use https://github.com/nexB/scancode-toolkit
#        ./scancode  --license --processes 2
#     - Type autodetection
#     - Auto-width all columns
#     - Check with pelc.eng.rh.c API
#     - Use generic approach:
#       $ rhpkg module-build-info 1044 | grep -E '^\s*NVR' | sort -u | tr -s ' ' | cut -d' ' -f3 | xargs -i brew download-build -q -a noarch -a x86_64 "{}"
#       $ ls *.rpm | rev | cut -d. -f2- | rev | xargs -i bash -c "echo -e \"\n>>>{}\" ; set -xe ; mkdir -p '{}' ; cd '{}' ; mv -vi '../{}.rpm' . "
#       $ ./list.sh -a -k 'rhel-8.0-candidate' 'rubygem-' | xargs -i brew download-build -q -a noarch -a x86_64 -a src "{}"
#       $ nano `find -type f | grep -vE '\.(ri|ttf|png|gif|gz)$'`
#       $ rpm --requires -qp rubygem-multi_json*.rpm | sort -u
#       $ grep -riE '(cryp|ssl)' | grep -iv ^spec | grep -iv ^CHANGEL | grep -v \.txt:
#     - Update oscryptocatcher(needs python3)
#
# Author:
#     Pavel Valena <pvalena@redhat.com>
#
#

trap 'kill 0 ; exit 0' SIGTERM
trap 'kill 0 ; exit 0' SIGINT
trap 'kill 0 ; exit 0' SIGABRT

set -e
bash -n "$0"

# globals
OUT=
w0=0
IGN=
DEB=

stx () { [[ -z "$DEB" ]] || echo "set -x" ; }
err () { `stx` ; [[ -n "$IGN" && -z "$2" ]] || printf "!! $x: $1\n" >&2 ; }
die () { `stx` ; [[ -z "$2" ]] && { git status || : ; } || { usage n | cat ; } ; err "$1" f ; exit 1 ; }
deb () { [[ -z "$DEB" ]] || echo -e " # $x : $@" ; }
nam () { x="`grep -q '^$pre' <<< "$1" && cut -d'-' -f2- <<< "$1" || echo "$1"`" ; }

out () {
  [[ "$1" ]] || out ' '

  while [[ "$1" ]]; do
    let 'w0 += 1'
    eval "w=\$w$w0"
    OUT="$OUT | `printf "%-${w}s" "$1"`"
    shift
  done
}

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

[[ "$1" == "--help" ]] && { usage ; } || :

[[ "$1" == "-b" ]] && { shift ; b="$1" ; shift ; } || b='rhel-8.0'
[[ "$1" == "-c" ]] && { shift ; c='yy' ; } || c=
[[ "$1" == "-d" ]] && { shift ; d='yy' ; } || d=
[[ "$1" == "-g" ]] && { shift ; g="yy" ; } || g=
[[ "$1" == "-h" ]] && { usage ; } || :
[[ "$1" == "-i" ]] && { shift ; i='yy' ; } || i=
[[ "$1" == "-p" ]] && { shift ; p="$1" ; } || p=
[[ "$1" == "-r" ]] && { shift ; r="$1" ; shift ; } || r=8
[[ "$1" == "-w" ]] && { shift ; w="$1" ; shift ; } || w=30,30,30,30,30

[[ "${1:0:1}" != '-' ]] || die "$LINENO: Unknown arg or invalid order: '$1'" n
[[ "$1" ]] || die "$LINENO: Please specify PKG" n

# Set Vars
fst="$c"
bra="$b"
TG="$g"
w="0,$w,0"
IGN="$i"
DEB="$d"
myd="$(readlink -e "`pwd`")"
#mydown="$(readlink -e "`dirname "$0"`/download-builds.sh")"

# Sanity checks.
#[[ -x "$mydown" ]] || die 'No download-builds.sh found: $mydown' n
[[ -n "$myd" && -d "$myd" ]] || die "$LINENO: Invalid working directory" n

# Determine packages type
T=
[[ -z "$TG" ]] || { T="gemspec" ; pre='rubygem-' ; }
[[ -z "$p" ]] || { T="" ; pre='???-' ; }          # <<< [placeholder]
[[ -n "$T" ]] || die 'No package type specified'

# Set w1,w2,w3...
for i in {1..100}; do
  eval "w$i='`cut -d',' -f$i <<< "$w"`'"
done

# Get list of packages.
lst=
nl="
"
while [[ -n "$1" ]] ; do
  lst="$lst$nl$1"
  shift
done
lst="`grep -v '^$' <<< "$lst"`"

# Width of first column
while read z; do
  x='unknown'
  nam "$z"
  wx="${#x}"
  [[ $wx -gt $w1 ]] && w1=$wx
done <<< "$lst"

x=
deb "\nlst >>>\n$lst\n<<<"
deb "bra = '$bra'"
deb "pre = '$pre'"
deb "fst = '$fst'"

# Padding for T
Tp=$(printf "%-${#T}s" -)

out 'package' 'specfile' "$T"         'licensee' 'cucos license check' 'licensecheck' 'oscryptocatcher' ; put
out '-------' '--------' "${Tp// /-}" '--------' '-------------------' '------------' '---------------' ; put

# For every package...
while read z; do
  x='unknown'
  nam "$z"
  OUT=
  w0=0
  out "$x"
  cd "$myd" || die "$LINENO: Failed to cd '$myd'" n

  [[ -d "$z" ]] || {
    [[ -z "$fst" ]] && {
      die "$LINENO: distgit directory '$z' not found" n
    } || {
      rhpkg co "$z" &>/dev/null || die "$LINENO: failed to rhpkg co '$z'" n
    }
  }
  cd "$z" || die "$LINENO: failed to cd '$z'" n

  deb "`pwd`"

  # Prepare git and sources and rpms
  [[ -z "$fst" ]] || {
    `stx`
    git fetch &>/dev/null || die "$LINENO: failed to fetch"
    rhpkg switch-branch "$bra" &>/dev/null || {
      err "$LINENO: failed to rhpkg switch-branch '$bra'"
      continue
    }
    git checkout "$bra" &>/dev/null || die "$LINENO: failed to checkout '$bra'"
    [[ "`git branch | grep '^*' | cut -d' ' -f2`" == "$bra" ]] || die "$LINENO: not on branch: $bra"
    git pull &>/dev/null || die "$LINENO: failed to pull"

    # Cleanup
    rm *.gem &>/dev/null || :
    rm *.rpm &>/dev/null || :

    rhpkg sources &>/dev/null || die "$LINENO: failed to fetch sources"
    #rpm packages currently not used
    #$mydown -b -x "$z" "el$r" &>/dev/null || err "$LINENO: failed to download RPMs"
    { set +x ; } &>/dev/null
  }

  # Really verbose output for DEBUG
  `stx`

  # Spec file check
  f="$z.spec"
  [[ -r "$f" ]] || die "$LINENO: spec file '$f' missing"
  SF="`tr -s '\t' ' ' < "$f" | grep '^License:' | cut -d' ' -f2-`" || die "$LINENO: spec file license failed"

  JSF=
  while read j; do JSF="$JSF, $j" ; done <<< "$SF"
  out "`cut -d' ' -f2- <<< "$JSF"`"

  d=
  # Type: Gem
  [[ -z "$TG" ]] || {
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

    # Output: Gemspec
    JGS=
    while read s; do
      while read gs; do
        [[ "$gs" ]] && JGS="$JGS, $gs"
      done < <( grep '\.licenses = \[\"' < "$s" | tr -s '\t' ' ' | cut -d'"' -f2- | rev | cut -d'"' -f2- | rev | tr -s '"' ',' | tr -s ',' '\n' | sort -u | grep -v '^.freeze$' )
    done <<< "$ss"
    out "`cut -d' ' -f2- <<< "$JGS"`"
  }

  # type: ???                                 # <<< [placeholder] \
  [[ "$p" ]] && {
    # YOU need to implement this
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
        [[ "$gs" ]] && JGS="$JGS, $gs"
      done < <(grep '\.licenses = \[\"' < "$s" | tr -s '\t' ' ' | cut -d'"' -f2- | rev | cut -d'"' -f2- | rev | tr -s '"' ',' | tr -s ',' '\n')
    done <<< "$ss"
    out "`cut -d' ' -f2- <<< "$JGS"`"
  }

  [[ -z "$d" ]] && die "$LINENO: no sources dir set"
  cd "$d" || die "$LINENO: failed to cd to sources dir '$d'"

  # Output: licensee
  JSF=
  while read j; do JSF="$JSF, $j" ; done < <(
    licensee | grep '^License: ' | cut -d' ' -f2- | sort -u
  )
  out "`cut -d' ' -f2- <<< "$JSF"`"

  # Output: cucos_license_check
  # https://copr.devel.redhat.com/coprs/hhorak/cucos-license-check/
  JSF=
  while read j; do JSF="$JSF, $j" ; done < <(
      cucos_license_check.py --only-license . | sort -u
  )
  out "`cut -d' ' -f2- <<< "$JSF"`"

  # Output: licensecheck
  JSF=
  while read j; do JSF="$JSF, $j" ; done < <(
    licensecheck -c '.*' -i '' -l 200 -m -r * | tr -s '\t' ' ' | grep -vE ' (UNKNOWN|GENERATED FILE)$' \
      | xargs -n1 -i bash -c "c=0 ; while [[ \$c -lt 1000 ]]; do let 'c += 1' ; [[ -r \"\$(cut -d' ' -f-\${c} <<< '{}')\" ]] && { let 'c += 1' ; cut -d' ' -f\${c}- <<< '{}' ; exit 0 ; } ; done ; echo 'NOPE {}' >&2 ; exit 1" \
      | sort -u
  )
  out "`cut -d' ' -f2- <<< "$JSF"`"

  # Output: oscryptocatcher
  # https://copr.devel.redhat.com/coprs/hhorak/oscryptocatcher/
  JSF=
  while read j; do JSF="$JSF, $j" ; done < <(
    oscryptocatcher . | grep '"crypto": ' | cut -d'"' -f4 | sort -u
  )
  out "`cut -d' ' -f2- <<< "$JSF"`"

  put
done <<< "$lst"
