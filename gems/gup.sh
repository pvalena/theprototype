#!/bin/bash

bash -n "$0" || exit 1

# const
CLEAN_EXT="tgz txz gem gz xz tar bz2 rpm"
ME='pvalena'
REM='rebase'
ORG='origin'
PRE='rubygem-'
NL='
'
# dependencies
CDF="`which colordiff`"
LOC="$(readlink -e "$0")"
LOC="`dirname "$(dirname "$LOC")"`"
CRB="${LOC}/pkgs/cr-build.sh"
KJB="${LOC}/pkgs/kj-build.sh"
TST="${LOC}/gems/test.sh"
GET="${LOC}/pkgs/sources.sh"
BUG="${LOC}/pkgs/bug.sh"
FRK="${LOC}/fedora/fork_package.sh"

# helpers
die () {
  warn "Error" "$1"
  exit 1
}

warn () {
  echo -e "--> $1: $2!" >&2
}

clean () {
  local e
  for e in $CLEAN_EXT; do
    rm -f *.$e
  done
}

# Note: everything should be commited before every srpm call
srpm () {
  {
    rm -rf result/
    rm *.src.rpm
  } &>/dev/null

  E="`mock -n --result=./result -r fedora-${COP}-x86_64 --bootstrap-chroot --buildsrpm -v --spec *.spec --sources . 2>&1`" || {
    warn "Failed to create $1 srpm, using fallback.\n" "$E"

    E="`fedpkg --release $REL srpm 2>&1`" || {
      die "Failed to create $1 srpm(2)" "$E"
    }
  }

  mv -f result/*.src.rpm .
  ls *.src.rpm &>/dev/null || die "Failed to create $1 srpm(3)"

  [[ -n "$CON" ]] || {
    bash -c "git reset --hard HEAD $SIL" || die 'Failed to reset git(2)'
  }
}

ask () {
  local r=
  local s=
  [[ "$1" == '-s' ]] && s="$1" && shift

  for x in {1..10}; do
    [[ -n "$YES" ]] && {
      echo "> $@. "
      return 0
      :
    } || {
      read -n1 -p "> $@? " r
      echo

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
} || COP='rubygems'

MOD="-m"
[[ "$1" == "-c" ]] && {
  CON="$1"
  MOD=
	shift
	:
} || CON=

[[ "$1" == "-e" ]] && {
  PRF="--pre"
	shift
	:
} || PRF=

[[ "$1" == "-d" ]] && {
	shift
  set -x
}

[[ "$1" == "-f" ]] && {
	REL="f$2"
	REM="${REM}-$REL"
	shift 2
	:
} || {
  REL='rawhide'
}

[[ "$1" == "-j" ]] && {
  KOJ=
	shift
	:
} || KOJ=y

[[ "$1" == "-m" ]] && {
  MOD="$1"
  CON="-c"
	shift
	:
} || MOD="${MOD:-}"

[[ "$1" == "-p" ]] && {
	PKG="$2"
	shift 2
	:
} || PKG="$(basename "$PWD")"

[[ "$1" == "-r" ]] && {
  COB=
	shift
	:
} || COB=y

[[ "$1" == "-s" ]] && {
	SKI="$1"
	CON="-c"
	MOD=
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
  warn 'Warning' "CDF shloud be defined and executable"
  CDF=cat
}
[[ -x "$CRB" ]] || warn 'Warning' "CRB shloud be defined and executable"
[[ -x "$KJB" ]] || warn 'Warning' "KJB shloud be defined and executable"
[[ -x "$TST" ]] || warn 'Warning' "KJB shloud be defined and executable"
[[ -x "$FRK" ]] || warn 'Warning' "FRK shloud be defined and executable"
[[ -x "$GET" ]] || die "GET needs to be defined and executable"

# kinit
[[ -z "$KOJ" ]] || {
  kl="$ME@FEDORAPROJECT\.ORG"
  klist -A | grep -q ' krbtgt\/FEDORAPROJECT\.ORG@FEDORAPROJECT\.ORG$' || {
    kinit "$kl" -l 30d -r 30d -A
    pgrep -x krenew &>/dev/null || krenew -i -K 60 -L -b
  }
}

[[ -n "$CON" ]] || clean
grep -q "^$PRE" <<< "$PKG" || die "Couldn't autodetect package name: '$PKG'"

# set remote
[[ -z "$MOD" ]] || {
  bash -c "git fetch '$ORG' $SIL" || die "Failed to git fetch" "$ORG"
  bash -c "git fetch '$ME' $SIL" || {
    bash -c "$FRK '$PKG' $SIL"
    git remote -v | grep -q "^$ME" \
      || git remote add "$ME" "git+ssh://$ME@pkgs.fedoraproject.org/forks/$ME/rpms/${PKG}.git"
    bash -c "git fetch '$ME' $SIL" || warn "Failed to fetch" "$ME"
  }
}

# status
[[ -z "$SIL" ]] && {
  git show | $CDF
  echo
  git diff | $CDF
  echo
  git status
  echo
}

[[ -n "$CON" ]] || {
  [[ -n "$SIL" && -n "$YES" ]] || ask "Stash & reset the repository"

  {
    # reset
    git stash || die 'Failed to stash git'

    git checkout "$REM" || {
      git checkout -b "$REM" || warn "Failed to switch to branch" "$REM"
    }
    git push -u "$ME" "$REM" || warn "Could not push to" "$ME/$REM"

    git reset --hard "$ORG/$REL" || die 'Failed to reset git'

    echo
  } 2>&1 | eval "cat $SIL"
}

# spec
X="`readlink -e *.spec`" || die 'Spec file not found'
nam="`rpmspec -q --qf '%{NAME}\n' "$X" | head -1`"
[[ -n "$nam" ]] || die "Bad NAME in '$X'"
[[ "${nam}" == "${PKG}" ]] || die "Failed package name check: '$PKG' vs '$nam'"

nam="`cut -d'-' -f2- <<< "$nam"`"

[[ -z "$MOD" ]] || {
  # old srpm
  bash -c "fedpkg --release $REL sources $SIL"
  srpm old
  sn="$(basename -s '.src.rpm' "`ls *.src.rpm`")"
  rm *.src.rpm &>/dev/null ||:

  nam2="$(rev <<< "$sn" | cut -d'-' -f3- | rev)"
  [[ "$PKG" == "$nam2" ]] \
    || die "name inconsistency- srpm name should be: '$PKG' not '$nam2'"

  # old version
  ov="`rpmspec -q --qf '%{VERSION}\n' "$X" | head -1`"
  [[ -n "$ov" ]] || die "Bad version in '$sn' and '$X'"

  ov2="$(rev <<< "$sn" | cut -d'-' -f2 | rev)"
  [[ "$ov" == "$ov2" ]] || die "Old version inconsistency- should be: '$ov' not '$ov2'"

  [[ -z "$SIL" ]] && echo
}

# new
[[ -z "$MOD" ]] || rm *.gem ||:
bash -c "gem fetch $PRF '$nam' '$ver' $SIL" || die "gem fetch $prf failed"

f="$(basename -s '.gem' "`ls *.gem | tail -n -1`")"
[[ "$f" && -r "$f.gem" ]] || die "Invalid or missing gem file: '$f'"
[[ "$nam" == "`rev <<< "$f" | cut -d'-' -f2- | rev`" ]] \
  || die "Failed gem name check of file: '$f'"

xv="`rev <<< "$f" | cut -d'-' -f1 | rev`"
[[ -n "$ver" ]] && ver="`cut -d' ' -f2 <<< "$ver"`" || ver="$xv"

[[ "$ver" == "$xv" ]] || die "Version check failed: '$ver' vs '$xv'"

[[ -z "$MOD" ]] || {
  [[ "$ver" == "$ov" ]] && {
    warn "Version is current" "$ver"
    exit 2
  }
}

[[ -n "$PRF" ]] && {
  prever=".`rev <<< "$ver" | cut -d'.' -f1 | rev`"
  ver="`rev <<< "$ver" | cut -d'.' -f2- | rev`"

  [[ -z "$MOD" ]] || {
    grep -qE '^[#%]*%global prerelease' "$X" && {
      sed -i "s/^[#%]*\(%global prerelease\).*$/\1 $prever/" "$X"
      :
    } || {
      sed -i "/^\s*Name: / i %global prerelease $prever\n" "$X"
    }
  }

  [[ -z "$ver" || "$prever" == '.' ]] \
    && die "Version/Preversion could be resolved correctly: '$ver/$prever'"
  :
} || {
  prever=
  [[ -z "$MOD" ]] \
    || sed -i "s/^[#%]*\(%global prerelease\).*$/#%\1 /" "$X"
}
echo

# Bug search + commit
B="$($BUG "$PKG")"
[[ -n "$B" ]] && {
  B="Resolves: rhbz#$B"
  R="${NL}  $B"
  :
} || B=

M="Update to $nam ${ver}${prever}."
gcom="git|cd|tar|wget|curl"

[[ -z "$MOD" ]] || {
  c="rpmdev-bumpspec -D -c '$M$R'"

  bash -c "set -x; $c -n '$ver' '$X'" || {
    warn "Failed to use rpmdev-bumpspec bump version, using fallback."

    sed -i "s/^\s*\(Version:\).*$/\1 $ver/" "$X"
    sed -i "s/^\s*\(Release:\)\s*[0-9]*\(.*\)$/\1 0\2/" "$X"

    bash -c "$c '$X'" \
      || die "Failed to bump spec with message '$M'"
  }

  # additional sources
  # newer version
  grep -B 20 '^Source' "$X" | grep '^#' | grep -E "^#\s*(${gcom})\s*" \
     | xargs -i bash -c "O=\$(sed -e 's|/|\\\/|g' <<< '{}') ; set -x ; sed -i \"/^\$O/ s/$ov/$ver$prever/g\" \"$X\""
  echo
}


# run the command get sources and write sources file
[[ -n "$SKI" ]] || {
  bash -c "$GET '$X' '$gcom' '$YES'" || die 'Failed to execute $GET'
  echo

  # .gitignore entry
  # TODO: deduplicate with pkgs/sources.sh
  regex='(\.(rb|js|patch|1|sh|stp)|LICENSE|binstub|rubygems\..*|macros\..*)$'
  gi='.gitignore'

  mv "${gi}" "${gi}-backup"
  touch "$gi"
  for x in `spectool -S "$X" | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev | grep -vE "$regex"` ; do
    y="/$(sed -e "s/$ver/*/g" <<< "$x")"
    [[ "$y" == '/' ]] && continue

    echo "$y" >> "$gi"
  done
  wc -l "$gi" | grep '^0 ' && {
    warn "Failed to regenerate $gi file, restoring."
    mv "${gi}-backup" "${gi}"
    :
  }
}

# commit
M="${M}$NL$NL${B}"
[[ -n "$SKI" ]] || {
  git commit -am "${M}" || die "Failed to commit with message '$M'"
  echo
}

# new srpm
srpm new
echo
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
warn "Please check the gem compare output bellow"
[[ -n "$MOD" ]] && {
  gem compare -bk "$nam" "$ov" "$ver$prever"
  :
} || {
  gem compare -bk "$nam" \
    "`git show | grep -E '^\-Version\:\s*' | tr -s '\t' ' ' | cut -d' ' -f2`" _
}
echo

[[ -n "$SKI" ]] || {
  [[ -z "$SIL" ]] && git diff | $CDF

  ask 'Continue with commit ammend'
  git commit --amend -am "$M" || die "Failed to amend"
  echo
}

git show | $CDF
echo
[[ -z "$SIL" ]] || git status -uno

git push -u "$ME" "$REM" || warn "Could not push to" "$ME/$REM"

gitd --stat "${ME}/${REM}" \
    | grep -q '^ 1 file changed, 1 insertion(+), 1 deletion(-)$' \
  && gitd "${ME}/${REM}" \
    | grep -A 1 '^ %changelog' | tail -n +2 \
    | grep -q ' Pavel Valena ' \
  && git push -f -u "$ME" "$REM"

echo

# build
[[ -z "$KOJ" ]] || {
  ask -s 'Run koji build' && {
    bash -c "$KJB"
    echo
  }
}

[[ -z "$COB" ]] || {
  ask -s 'Run copr build' && {
    bash -c "set -x; $CRB -c -t 30m $COP $SIL"

    l="$(readlink -e "../copr-r8-${COP}/${PKG}.log")"
    [[ -r "$l" ]] || die "COPR log not found"

    B="$(grep '^Created builds: ' "$l" | sort -u)"
    [[ -z "$B" ]] && head -20 "$l"

    # Build has failed, but it might have been just EPEL one
    grep -A 10 '^Executing(%clean):' "$l" | grep -q '^Finish: ' \
      || die "Build failed: \n`tail -n 70 "$l"`"

    # This seems unreliable
    #grep -B 30 '^Executing(%clean):' "$l" | grep -q '^+ exit 0$' \

    echo
    echo "$B"
  }
}

[[ -z "$EXI" ]] || exit 0

ask -s 'Run checks' && {
  bash -c "$TST -c $SIL"
}

exit 0
