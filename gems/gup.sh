#!/bin/bash

bash -n "$0" || exit 1

# const
CLEAN_EXT="tgz gem gz xz tar bz2 rpm"
ME=pvalena
REM=rebase
ORG=origin

# dynamic
CDF="`which colordiff`"
LOC="$(readlink -e "$0")"
LOC="`dirname "$(dirname "$LOC")"`"
CRB="${LOC}/pkgs/cr-build.sh"
KJB="${LOC}/pkgs/kj-build.sh"
TST="${LOC}/gems/test.sh"

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
  git reset --hard HEAD || die 'Failed to reset git(2)'
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

[[ "$1" == "-f" ]] && {
	REL="f$2"
	REM="${REM}-$REL"
	shift 2
	:
} || {
  REL='master'
}

[[ "$1" == "-m" ]] && {
	MOC="$1"
	shift
} || MOC=31

[[ "$1" == "-v" ]] && {
  shift
	ver="-v $1"
	shift
} || ver=

[[ "$1" == "-y" ]] && {
	YES="$1"
	shift
} || YES=

# sanity checks
[[ -n "$ME" ]] || die "ME shloud be defined"
[[ -n "$REM" ]] || die "REM shloud be defined"
[[ -n "$ORG" ]] || die "ORG shloud be defined"
[[ -n "$MOC" ]] || die "MOC shloud be defined"
[[ -n "$REL" ]] || die "REL shloud be defined"

# usability
[[ -x "$CDF" ]] || {
  warn "CDF shloud be defined and executable"
  CDF=cat
}
[[ -x "$CRB" ]] || warn "CRB shloud be defined and executable"
[[ -x "$KJB" ]] || warn "KJB shloud be defined and executable"


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

ask "Stash & reset the repository"

# reset
git stash || die 'Failed to stash git'

git checkout "$REM" || {
  git checkout -b "$REM" || warn "Failed to switch to branch '$REM'"
}
git push -u "$ME/$REM" || warn "Could not push to '$ME/$REM'"

git reset --hard "$ORG/$REL" || die 'Failed to reset git'

# spec
X="`readlink -e *.spec`" || die 'Spec file not found'

# old srpm
srpm old
sn="$(basename -s '.src.rpm' "`ls *.src.rpm`")"
rm *.src.rpm||:

# old version
ov="`rpmspec -q --qf '%{VERSION}\n' "$X" | head -1`"
[[ "$ov" && "$ov" == "$(rev <<< "$sn" | cut -d'-' -f2 | rev)" ]] || die "Old version inconsistency- should be: '$ov'"

nam="`rpmspec -q --qf '%{NAME}\n' "$X" | head -1`"
[[ "$nam" ]] || die 'Bad NAME in "$X"'
[[ "$nam" == "$(rev <<< "$sn" | cut -d'-' -f3- | rev)" ]] || die "Package name inconsistency- should be: '$nam'"
grep '^rubygem-' <<< "$nam" && nam="`cut -d'-' -f2- <<< "$nam"`"

# new
gem fetch "$nam" $ver || die "gem fetch failed"
f="$(basename -s '.gem' "`ls *.gem | tail -n -1`")"
[[ "$f" && -r "$f.gem" ]] || die "Invalid or missing gem file: '$f'"
[[ "$nam" == "`rev <<< "$f" | cut -d'-' -f2- | rev`" ]] || die "Failed gem name check of file: '$f'"

xv="`rev <<< "$f" | cut -d'-' -f1 | rev`"
[[ -n "$ver" ]] && ver="`cut -d' ' -f2 <<< "$ver"`" || ver="$xv"

[[ "$ver" == "$xv" ]] || die "Version check failed: '$ver' vs '$xv'"

[[ "$ver" == "$ov" ]] && die "Version '$ver' is current"

[[ -d "$nam/" ]] && {
  echo
  ls "$nam/" || die "Failed to list '$nam/'"
  ask 'Remove directory'
  rm -rf "$nam/" || die "Failed to remove '$nam/'"
}

# bump
M="Update to $nam ${ver}."
c="rpmdev-bumpspec -c '$M'"

bash -c "$c -n '$ver' '$X'" || {
  sed -i "s/^\(Version:\).*$/\1 $ver/" "$X"
  sed -i "s/^\(Release:\)\s*[0-9]*\(.*\)$/\1 0\2/" "$X"

  bash -c "$c '$X'" \
    || die "Failed to bump spec with message '$M'"
}

# sources
gcom=' (tar|git|cp|mv|cd) '
grep -A 5 ' git clone ' "$X" | grep '^#' |  grep -E "$gcom" \
  | xargs -i bash -c "O=\$(sed -e 's|/|\\\/|g' <<< '{}') ; set -x ; sed -i \"/^\$O/ s/$ov/$ver/g\" "$X""

cmd=$( grep -A 3 '^# git clone ' "$X" | grep '^#' |  grep -E "$gcom" | cut -d'#' -f2- | xargs -i echo -n "{} && " \
  | xargs -i echo "set -x ; {}echo Ok || exit 1" )

[[ -z "$cmd" ]] || {
  echo
  echo "\$cmd: $cmd"
  ask 'execute $cmd'
  bash -c "$cmd" || die 'Failed to execute $cmd'
}
## All output gets written into sources-new file here
for x in `spectool -A "$X" | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev` ; do
  { find -mindepth 2 -type f -name "$x" | xargs -n1 -i mv -v "{}" . ; } 1>&2

  [[ -r "$x" ]] && {
    echo "SHA512 ($x) = `sha512sum "$x" | cut -d' ' -f1`"
    :
  } || {
    warn "Source not found" "$x"
    warn 'Trying' 'original sources'

    i="`grep "^SHA512 ($x) = " sources`"

    [[ -n "$i" ]] && {
      echo "$i"
      :
    } || {
      warn "Source not found(2)" "$x"
      ask 'Continue anyway'
    }
  }

  # Add .gitignore entry, if missing
  g='.gitignore'
  e=
  grep -q "$ver" <<< "$x" && {
    e="`sed "s/$ver/\*/" <<< "$x"`"
    :
  } || {
    t="`rev <<< "$x" | cut -d'-' -f2- | rev`"
    sf=
    for s in `tr '|' ' ' <<< "$EXT"`; do
      grep -q "$s$" <<< "$x" && sf="$s"
    done

    [[ -n "$sf" && -n "$t" ]] && {
      e="${t}-*.${sf}"
    }
  }

  [[ -z "$e" ]] || {
    e="/$e"
    grep -q "^`printf "%q" "$e"`$" "$g" || echo "$e" >> "$g"
  }
done > sources-new
grep -v '^$' sources-new > sources
rm sources-new

# commit
git commit -am "$M" || die "Failed to commit with message '$M'"

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

git commit -a --amend || die "Failed to amend"

git show | $CDF
echo
git status


## TODO: push + PR

# build
ask -s 'Run koji build' && {
  bash -c "$KJB -s"
}||:

ask -s 'Run copr build' && {
  bash -c "$CRB rubygems"
}||:

ask -s 'Run checks' && {
  bash -c "$TST"
}||:

# TODO: port from rev.sh
exit
# unfinished; port
ask 'Run install'

rm /var/lib/mock/fedora-rawhide-x86_64/root/builddir/*.rpm

ls result/*.rpm | grep -E '\.(noarch|x86_64)\.rpm$' \
  | xargs sudo cp -vt /var/lib/mock/fedora-rawhide-x86_64/root/builddir \
  && sudo mock -n --old-chroot --bootstrap-chroot -r fedora-rawhide-x86_64 --chroot 'rpm -U /builddir/*.rpm ; rpm -v --reinstall /builddir/*.rpm' \
  || die "Failed to install resulting packages"

ask 'Clean'
mock -n --old-chroot --bootstrap-chroot -r fedora-rawhide-x86_64 --clean || warn "Failed to clean mock"

# unfinished; port
ask 'Run syntax check'

# syntax check
find -type f -name '*.rb' \
  | xargs -i bash -c "{
      set -x ; ruby -c '{}' 2>&1 || exit 255
    } | grep -v '^Syntax OK$' ;:"
