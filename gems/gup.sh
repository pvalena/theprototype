#!/bin/bash

bash -n "$0" || exit 1

# const
CLEAN_EXT="tgz gem gz xz tar bz2 rpm"
ME='pvalena'
REM='rebase'
ORG='origin'
PRE='rubygem-'
NL='
'

# dynamic
CDF="`which colordiff`"
LOC="$(readlink -e "$0")"
LOC="`dirname "$(dirname "$LOC")"`"
CRB="${LOC}/pkgs/cr-build.sh"
KJB="${LOC}/pkgs/kj-build.sh"
TST="${LOC}/gems/test.sh"
GET="${LOC}/gems/sources.sh"
BUG="${LOC}/pkgs/bug.sh"
FRK="${LOC}/fedora/fork_package.sh"


# helpers
die () {
  echo
  warn "Error" "$1"
  exit 1
}

warn () {
  echo
  echo "--> $1: $2!" >&2
}

clean () {
  local e
  for e in $CLEAN_EXT; do
    rm -f *.$e
  done
}

# Note: everything should be commited before every srpm call
srpm () {
  E="`fedpkg --release $REL srpm`" || {
    warn "Failed to reate $1 srpm" "$E"
    warn 'Trying to remove' 'richdeps'

    sed -i 's/^Recommends: /Requires: /' *.spec
    sed -i '/^Suggests: / s/^/#/' *.spec

    E="`fedpkg --release $REL srpm`" || {
      die "Failed to create $1 srpm(2)" "$E"
    }
  }
  [[ -n "$CON" ]] || {
    git reset --hard HEAD || die 'Failed to reset git(2)'
  }
}

ask () {
  local r=
  local s=
  [[ "$1" == '-s' ]] && s="$1" && shift

  for x in {1..10}; do
    echo
    [[ -n "$YES" ]] && {
      echo ">> $@. "
      return 0
      :
    } || {
      read -n1 -p ">> $@? " r

      grep -qi '^y' <<< "${r}" && {
        clear
        return 0
        :
      }||:

      grep -qi '^n' <<< "${r}" && {
        break
        :
      }||:
    }
  done

  [[ -n "$s" ]] || die 'User quit'
  return 1
}

# args
[[ "$1" == "-b" ]] && {
  COP="$2"
	shift 2
	:
} || COP=rubygems

[[ "$1" == "-c" ]] && {
  CON="$1"
	shift
	:
} || CON=

[[ "$1" == "-d" ]] && {
	shift
  set -x
}

[[ "$1" == "-j" ]] && {
  KOJ=
	shift
	:
} || KOJ=y

[[ "$1" == "-f" ]] && {
	REL="f$2"
	REM="${REM}-$REL"
	shift 2
	:
} || {
  REL='master'
}

[[ "$1" == "-p" ]] && {
	PKG="$2"
	shift 2
	:
} || PKG="$(basename "$PWD")"

[[ "$1" == "-s" ]] && {
	SKI="$1"
	CON="$1"
	shift
	:
} || SKI=

[[ "$1" == "-u" ]] && {
	SIL="&>/dev/null"
	shift
	:
} || SIL=

[[ "$1" == "-v" ]] && {
	ver="-v $2"
	shift 2
} || ver=

[[ "$1" == "-x" ]] && {
	EXI="$1"
	shift
} || EXI=

[[ "$1" == "-y" ]] && {
	YES="$1"
	shift
} || YES=

[[ -z "$1" ]] || die "Unknown arg: '$1'"

# sanity checks
[[ -n "$ME" ]] || die "ME shloud be defined"
[[ -n "$REM" ]] || die "REM shloud be defined"
[[ -n "$ORG" ]] || die "ORG shloud be defined"
[[ -n "$COP" ]] || die "COP shloud be defined"
[[ -n "$REL" ]] || die "REL shloud be defined"

# usability
[[ -x "$CDF" ]] || {
  warn "CDF shloud be defined and executable"
  CDF=cat
}
[[ -x "$CRB" ]] || warn "CRB shloud be defined and executable"
[[ -x "$KJB" ]] || warn "KJB shloud be defined and executable"
[[ -x "$TST" ]] || warn "KJB shloud be defined and executable"
[[ -x "$FRK" ]] || warn "FRK shloud be defined and executable"
#[[ -x "$GET" ]] || die "GET needs to be defined and executable"

# kinit
[[ -z "$KOJ" ]] || {
  kl="$ME@FEDORAPROJECT\.ORG"
  ( klist -a | grep -q "${kl}$" ) || {
    pgrep -x krenew || krenew -i -K 60 -L -b
    kinit "$kl" -l 30d
  }
}

clean
grep -q "^$PRE" <<< "$PKG" || die "Couldn't autodetect package name: '$PKG'"

# set remote
git fetch "$ORG" || die 'Failed to git fetch $ORG'
git fetch "$ME" || {
  bash -c "$FRK '$PKG'"
  git remote -v | grep -q "^$ME" \
    || git remote add "$ME" "git+ssh://$ME@pkgs.fedoraproject.org/forks/$ME/rpms/${PKG}.git"
  git fetch "$ME" || warn "Failed to fetch '$ME'"
}

# status
[[ -n "$SIL" ]] || {
  git show | $CDF
  echo
  git diff | $CDF
  echo
  git status
}

[[ -n "$CON" ]] || {
  ask "Stash & reset the repository"

  {
    # reset
    git stash || die 'Failed to stash git'

    git checkout "$REM" || {
      git checkout -b "$REM" || warn "Failed to switch to branch '$REM'"
    }
    git push -u "$ME/$REM" || warn "Could not push to '$ME/$REM'"

    git reset --hard "$ORG/$REL" || die 'Failed to reset git'

  } | bash -c "cat $SIL"
}

# spec
X="`readlink -e *.spec`" || die 'Spec file not found'
nam="`rpmspec -q --qf '%{NAME}\n' "$X" | head -1`"
[[ -n "$nam" ]] || die "Bad NAME in '$X'"
[[ "${nam}" == "${PKG}" ]] || die "Failed package name check: '$PKG' vs '$nam'"

nam="`cut -d'-' -f2- <<< "$nam"`"

[[ -n "$SKI" ]] || {
  # old srpm
  srpm old
  sn="$(basename -s '.src.rpm' "`ls *.src.rpm`")"
  rm *.src.rpm||:

  nam2="$(rev <<< "$sn" | cut -d'-' -f3- | rev)"
  [[ "$PKG" == "$nam2" ]] \
    || die "name inconsistency- srpm name should be: '$PKG' not '$nam2'"

  # old version
  ov="`rpmspec -q --qf '%{VERSION}\n' "$X" | head -1`"
  [[ -n "$ov" ]] || die "Bad version in '$sn' and '$X'"

  ov2="$(rev <<< "$sn" | cut -d'-' -f2 | rev)"
  [[ "$ov" == "$ov2" ]] || die "Old version inconsistency- should be: '$ov' not '$ov2'"
}

# new
rm *.gem||:
gem fetch "$nam" $ver || die "gem fetch failed"

f="$(basename -s '.gem' "`ls *.gem | tail -n -1`")"
[[ "$f" && -r "$f.gem" ]] || die "Invalid or missing gem file: '$f'"
[[ "$nam" == "`rev <<< "$f" | cut -d'-' -f2- | rev`" ]] \
  || die "Failed gem name check of file: '$f'"

xv="`rev <<< "$f" | cut -d'-' -f1 | rev`"
[[ -n "$ver" ]] && ver="`cut -d' ' -f2 <<< "$ver"`" || ver="$xv"

[[ "$ver" == "$xv" ]] || die "Version check failed: '$ver' vs '$xv'"

[[ -n "$SKI" ]] || {
  [[ "$ver" == "$ov" ]] && die "Version '$ver' is current"
}

# Bug search
B="$($BUG "$PKG")"
[[ -n "$B" ]] && {
  B="Resolves: rhbz#$B"
  R="${NL}  $B"
  :
} || B=

# bump
M="Update to $nam ${ver}."
gcom="git|cd|tar"

[[ -n "$SKI" ]] || {
  c="rpmdev-bumpspec -c '$M$R'"

  bash -c "$c -n '$ver' '$X'" || {
    sed -i "s/^\(Version:\).*$/\1 $ver/" "$X"
    sed -i "s/^\(Release:\)\s*[0-9]*\(.*\)$/\1 0\2/" "$X"

    bash -c "$c '$X'" \
      || die "Failed to bump spec with message '$M'"
  }

  # additional sources
  # newer version
  grep -B 20 '^Source' "$X" | grep '^#' | grep -E "^#\s*(${gcom})\s*" \
     | xargs -i bash -c "O=\$(sed -e 's|/|\\\/|g' <<< '{}') ; set -x ; sed -i \"/^\$O/ s/$ov/$ver/g\" \"$X\""
}

# run the command get sources and write sources file
bash -c "$GET '$X' '$gcom' '$YES'" || die 'Failed to execute $GET'

# commit
M="${M}$NL$NL${B}"
[[ -n "$SKI" ]] || {
  git commit -am "${M}" || die "Failed to commit with message '$M'"
}

# new srpm
srpm new

# Not needed: Currently resetting
## save diff from srpm creation
#P=''
## TODO: Could be different; check
#git status -uno | grep -q '^nothing to commit ' || {
#   Let's remember the current spec modifications
#  git commit -am 'Rich deps fixup' || die "Failed to commit(2)"
#  P="`git format-patch HEAD^`"
#  git reset --soft HEAD^
#}
# Finished work on .spec file, revert temp/richdeps changes, if there are
#[[ -n "$P" && -r "$P" ]] && {
#  patch -p1 -R < "$P" || die "Failed to reverse-apply patch" "$P"
#  rm "$P"
#}

# compare
echo
gem compare -bk "$nam" "$ov" "$ver"

[[ -n "$SKI" ]] || {
  ask 'Continue with commit ammend'
  git commit --amend -am "$M" || die "Failed to amend"
}

git show | $CDF
echo
[[ -z "$SIL" ]] || git status -uno

git push -u "$ME" "$REM" || warn "Could not push to '$ME/$REM'"

# build
[[ -z "$KOJ" ]] || {
  ask -s 'Run koji build' && {
    bash -c "$KJB $SIL"
  }
}

ask -s 'Run copr build' && {
  bash -c "set -x; $CRB -c $COP $SIL"

  l="$(readlink -e "../copr-r8-${COP}/${PKG}.log")"
  [[ -r "$l" ]] || die "COPR log not found"

  B="$(grep '^Created builds: ' "$l" | sort -u)"
  [[ -z "$B" ]] && head -20 "$l"

  # Build has failed but it might have been just EPEL
  grep -B 15 '^Executing(%clean):' "$l" | grep -q '^+ exit 0$' \
    || die "Build failed: \n`cat "$l"`"

  echo "$B"
}

[[ -z "$EXI" ]] || exit 0

ask -s 'Run checks' && {
  bash -c "$TST -c $SIL"
}
