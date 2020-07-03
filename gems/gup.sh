#!/bin/bash

bash -n "$0" || exit 1

# const
CLEAN_EXT="tgz gem gz xz tar bz2 rpm"
ME=pvalena
REM=rebase
ORG=origin
NL='
'

# dynamic
CDF="`which colordiff`"
LOC="$(readlink -e "$0")"
LOC="`dirname "$(dirname "$LOC")"`"
CRB="${LOC}/pkgs/cr-build.sh"
KJB="${LOC}/pkgs/kj-build.sh"
TST="${LOC}/gems/test.sh"
#GET="${LOC}/gems/get.sh"
BUG="${LOC}/pkgs/bug.sh"

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
    warn "Failed to recreate $1 srpm" "$E"
    warn 'Trying to remove' 'richdeps'

    sed -i 's/^Recommends: /Requires: /' *.spec
    sed -i '/^Suggests: / s/^/#/' *.spec

    E="`fedpkg --release $REL srpm`" || {
      die "Failed to recreate $1 srpm(2)" "$E"
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
[[ "$1" == "-d" ]] && {
	shift
  set -x
}

[[ "$1" == "-c" ]] && {
  COP="$2"
	shift 2
	:
} || COP=rubygems

[[ "$1" == "-d" ]] && {
	shift
  set -x
}

[[ "$1" == "-j" ]] && {
  KOJ=
	shift
	:
} || KOJ=y

[[ "$1" == "-k" ]] && {
  CON="$1"
	shift
	:
} || CON=

[[ "$1" == "-f" ]] && {
	REL="f$2"
	REM="${REM}-$REL"
	shift 2
	:
} || {
  REL='master'
}

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
#[[ -x "$GET" ]] || die "GET needs to be defined and executable"

# kinit
[[ -z "$KOJ" ]] || {
  kl="$ME@FEDORAPROJECT\.ORG"
  ( klist -a | grep -q "${kl}$" ) || {
    pgrep -x krenew || krenew -i -K 60 -L -b
    kinit "$kl" -l 30d
  }
}

# set remote
clean
git fetch "$ORG" || die 'Failed to git fetch $ORG'
git fetch "$ME" || {
  git remote -v | grep -q "^$ME" \
    || git remote add "$ME" "git+ssh://$ME@pkgs.fedoraproject.org/forks/$ME/rpms/`basename "$PWD"`.git"
  git fetch "$ME" || warn "Failed to fetch '$ME'"
}

# status
git show | $CDF
echo
git diff | $CDF
echo
git status

[[ -n "$CON" ]] || {
  ask "Stash & reset the repository"

  # reset
  git stash || die 'Failed to stash git'

  git checkout "$REM" || {
    git checkout -b "$REM" || warn "Failed to switch to branch '$REM'"
  }
  git push -u "$ME/$REM" || warn "Could not push to '$ME/$REM'"

  git reset --hard "$ORG/$REL" || die 'Failed to reset git'
}

# spec
X="`readlink -e *.spec`" || die 'Spec file not found'

# old srpm
srpm old
sn="$(basename -s '.src.rpm' "`ls *.src.rpm`")"
rm *.src.rpm||:

nam="`rpmspec -q --qf '%{NAME}\n' "$X" | head -1`"
nam2="$(rev <<< "$sn" | cut -d'-' -f3- | rev)"
[[ -n "$nam" ]] && {
  [[ "$nam" == "$nam2" ]] || die "name inconsistency- should be: '$nam'"
  :
} || nam="$nam2"
[[ -n "$nam" ]] || die "Bad NAME in '$sn' and '$X'"

# old version
ov="`rpmspec -q --qf '%{VERSION}\n' "$X" | head -1`"
ov2="$(rev <<< "$sn" | cut -d'-' -f2 | rev)"
[[ -n "$ov" ]] && {
  [[ "$ov" == "$ov2" ]] || die "Old version inconsistency- should be: '$ov'"
  :
} || ov="$ov2"
[[ -n "$ov" ]] || die "Bad version in '$sn' and '$X'"

grep '^rubygem-' <<< "$nam" && nam="`cut -d'-' -f2- <<< "$nam"`"

# new
rm *.gem||:
gem fetch "$nam" $ver || die "gem fetch failed"
f="$(basename -s '.gem' "`ls *.gem | tail -n -1`")"
[[ "$f" && -r "$f.gem" ]] || die "Invalid or missing gem file: '$f'"
[[ "$nam" == "`rev <<< "$f" | cut -d'-' -f2- | rev`" ]] || die "Failed gem name check of file: '$f'"

xv="`rev <<< "$f" | cut -d'-' -f1 | rev`"
[[ -n "$ver" ]] && ver="`cut -d' ' -f2 <<< "$ver"`" || ver="$xv"

[[ "$ver" == "$xv" ]] || die "Version check failed: '$ver' vs '$xv'"

[[ -n "$CON" ]] || {
  [[ "$ver" == "$ov" ]] && die "Version '$ver' is current"
}

# Bug search
B="$($BUG "rubygem-$nam")"
[[ -n "$B" ]] && {
  B="Resolves: rhbz#$B"
  R="${NL}  $B"
  :
} || B=

# bump
M="Update to $nam ${ver}.$NL$NL$B"
c="rpmdev-bumpspec -c '$M$R'"

bash -c "$c -n '$ver' '$X'" || {
  sed -i "s/^\(Version:\).*$/\1 $ver/" "$X"
  sed -i "s/^\(Release:\)\s*[0-9]*\(.*\)$/\1 0\2/" "$X"

  bash -c "$c '$X'" \
    || die "Failed to bump spec with message '$M'"
}

# additional sources
# newer version
grep -A 10 ' git clone ' "$X" | grep '^#' \
   | xargs -i bash -c "O=\$(sed -e 's|/|\\\/|g' <<< '{}') ; set -x ; sed -i \"/^\$O/ s/$ov/$ver/g\" "$X""

# run the command get ~magic~
# bash -c "$GET '$X' '$ver'" || die 'Failed to execute $GET'
find -mindepth 2 -type d -name .git -exec git fetch origin \;
gcom="git|cd|tar"
cmd=$(
    grep -A 10 '^# git clone ' "$X" | grep '^#' | cut -d'#' -f2- | grep -E "^\s*(${gcom})\s*" \
      | xargs -i echo -n "; {}" \
      | xargs -i echo "set -x{} && echo Ok || exit 1"
  )
[[ -z "$cmd" ]] || {
  echo
  echo "\$cmd: $cmd"
  ask 'execute $cmd'
  bash -c "$cmd" || die 'Failed to execute $cmd'
}
find -mindepth 2 -type f -name '*.txz' -o -name '*.tgz' | xargs -ri cp -v "{}" .

# commit
git commit -am "${M}$NL$NL${R}" || die "Failed to commit with message '$M'"

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
ask 'Continue with commit ammend'

git commit --amend -am "$M" || die "Failed to amend"

git show | $CDF
echo
git status

git push -u "$ME/$REM" || warn "Could not push to '$ME/$REM'"

# build
[[ -z "$KOJ" ]] || {
  ask -s 'Run koji build' && {
    bash -c "$KJB" ||:
  }||:
}

ask -s 'Run copr build' && {
  bash -c "$CRB $COP" ||:
}||:

[[ -z "$EXI" ]] || exit
#check dont currently work without mock
ask -s 'Run checks' && {
  bash -c "$TST -c"
}||:
