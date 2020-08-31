#!/bin/bash

# >&2
{
set -e
bash -n "$0"

section () {
  l="##############################"
  echo "$l" "$@" "$l"
}

MYD="`readlink -e "$(dirname "$0")/.."`"
[[ -d "$MYD" ]]

rel='f34'

# mock changes it's verbosity if output is redirected
[[ -t 1 ]] && v='' || v="-v "
msr="${v}-n --isolation=nspawn --result=./result"
mar='--bootstrap-chroot'
mck () {
  a=""
  while [[ -n "$1" ]]; do a="$a '$1'" ; shift ; done

  bash -c "set -x ; mock $msr $mar $a"
  return $?
}

me="pvalena"
mc="rubygems"
gp='rubygem-'

COPR_URL="https://copr-be.cloud.fedoraproject.org/results/$me/"

[[ "$1" == '-b' ]] && {
  CR="$2"
  shift 2
  :
} || CR=

[[ "$1" == '-c' ]] && {
  CON="$1"
  shift
  :
} || CON=

[[ "$1" == '-f' ]] && {
  FAS="$1"
  shift
  :
} || FAS=

[[ "$1" == '-k' ]] && {
  KJ="$2"
  shift 2
  :
} || KJ=

[[ "$1" == '-n' ]] && {
  CINIT=
  shift
  :
} || CINIT="`echo --{clean,init}`"

[[ "$1" == '-p' ]] && {
  pr="$2"
  shift 2
  :
} || pr=

[[ "$1" == '-r' ]] && {
  mrr="$2"
  shift 2
  :
} || mrr="fedora-rubygems-x86_64"
msr="${msr} -r $mrr"

[[ "$1" == '-u' ]] && {
  UPD="$1"
  shift
  :
} || UPD=

[[ "$1" == '-v' ]] && {
  mc="vagrant"
  gp="vagrant-"
  shift
} ||:

tb='copr-dist'
rm="${tb}/master"
bl='result/build.log'

[[ -n "$KJ" ]] || {
  kl="$me@FEDORAPROJECT\.ORG"
  ( klist -a | grep -q "${kl}$" ) || {
    pgrep -x krenew &>/dev/null || krenew -i -K 60 -L -b
    kinit "$kl" -l 30d
  }
}

set -x

p="$1"
[[ -n "$p" ]] && {
  grep -q "^$gp" <<< "$p" || p="$gp$p"
  [[ -d "$p" ]] || fedpkg --user "$me" clone -a "$p"
  [[ -d "$p" ]]
  cd "$p"
  :
} || {
  p="`basename "$PWD"`"
}
g="$(cut -d'-' -f2- <<< "$p")"

[[ -n "$p" && -n "$g" ]]
grep "^$gp" <<< "$p" &>/dev/null

[[ -n "$CON" ]] || {
  gitt ||:

  [[ -n "$pr" ]] || {
    #for x in {1..2}; do
    #  git remote remove "$tb"
    #done

    git remote add "${tb}" "https://copr-dist-git.fedorainfracloud.org/cgit/$me/$mc/$p.git" ||:
    gitf "$tb"
    gitc "$tb" \
      || gitcb "$tb" -t "$rm"

    [[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "$tb" ]]
    gitrh "$rm"
    gitb -u "$rm"
  }

  #koji?
  #git remote add "$me" "ssh://$me@pkgs.fedoraproject.org/forks/$me/rpms/$p" ||:
  #gitf "$me"
  [[ -z "$CR" ]] || {
    u="${COPR_URL}${mc}/fedora-rawhide-x86_64/`printf "%08d" $CR`-${p}/"
    srpm="$(
      curl -Lksf "$u" \
        | tr -s '<' '\n' \
        | grep -E "^a href='.*\.src\.rpm'" \
        | cut -d"'" -f2
    )"
    [[ -n "$srpm" ]]
    rm *.src.rpm ||:

    curl -OLksf "$u/$srpm"
    [[ -r "$srpm" ]]

    rpm2cpio *.src.rpm \
      | cpio -uidmv --no-absolute-filenames
  }

  [[ -z "$pr" ]] || {
    gitc master
    gitb -D "pr$pr"
    git fetch origin "refs/pull/$pr/head:pr$pr"
    gitc "pr$pr"

    [[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "pr$pr" ]]
  }

  rm *.gem
  gem fetch "$g" ||:
}

[[ -n "$FAS" ]] || {
  section 'SRPM'
  rm *.src.rpm ||:
  rm -rf result/ ||:
  #fedpkg --release master sources
  fedpkg --release $rel srpm

  section 'BUILD'
  for c in $CINIT *.src.rpm; do
    mck $c
    sleep 1
  done
}

section 'TESTS'
[[ -r "$bl" ]] || {
  [[ -r "${bl}.xz" ]] && unxz "${bl}.xz"
}
TP="$TP\n  - Tests:"
grep -q '^Executing(%check)'                            "$bl" && {
! grep ' failures' "$bl" || grep -E '(^|\s+)0 failures' "$bl" && {
! grep ' errors'   "$bl" || grep -E '(^|\s+)0 errors'   "$bl" && {

! grep -qE '(^|\s+)0 (assertions|examples)' "$bl" && \
  grep -qE ' (assertions|examples)' "$bl" \
  \
  && TP="$TP ok" \
  || TP="$TP failed (no assertions)"
:
} || TP="$TP failed (errors occured)"
:
} || TP="$TP failed (failures occured)"
:
} || TP="$TP failed (%check is missing)"

section 'INSTALL'
E=''
mar=''
for c in "{x86_64,noarch}" {x86_64,noarch} ; do
  x="$(bash -c "ls result/*.${c}.rpm")" || continue

  mck -i $x && {
    [[ "$c" == "{x86_64,noarch}" ]] && break
    :
  } || E="$c installation failed"
done

section 'SYNTAX'
TP="$TP\n  - Syntax check:"
mck --unpriv --shell '
  cd
  find -type f -name "*.rb" \
    | xargs -i bash -c \
      "{ ruby -c \"{}\" 2>&1 || exit 255 ; } | grep -v \"^Syntax OK$\""
  :
' && TP="$TP ok" || TP="$TP failed"


section 'DEPENDENCIES'
TP="$TP\n  - Dependent packages:"
DEP="$( bash -c "$MYD/gems/whatrequires.sh -q '$g'" )" \
  && TP="$TP ok" \
  || TP="$TP failed ($DEP)"


[[ -n "$E" ]] || {
  section 'SMOKE'
  TP="$TP\n  - Smoke test:"
  q="`sed -e 's/\-/\//' <<< "$g"`"
  q="`sed -e 's/^ruby//' <<< "$q"`"

  for c in "rpm -q \"$p\"" "ruby -e \"require '\''$g'\''\" || ruby -e \"require '\''$q'\''\"" 0 ; do
    [[ "$c" == '0' ]] \
      && TP="$TP ok" \
      || {
        mck --unpriv --chroot "$c" || {
          TP="$TP failed ($c)"
          break
        }
      }
  done
}

section 'RPMLINT'
set -o pipefail
TP="$TP\n  - rpmlint:"
RPML="$(
  rpmlint result/*.rpm *.spec 2>/dev/null \
    | grep -vE ' W: (no\-documentation)$' \
    | grep -vE ' W: (spelling\-error|zero\-length|devel\-file\-in\-non\-devel\-package) ' \
    | grep -vE ' W: (invalid-url Source)' \
    | sort -u
  )" \
  && TP="$TP ok" \
  || TP="$TP failed\n\n$RPML"


{ set +x ; } &>/dev/null


section 'SUMMARY'
# In case we dont do this from gup.sh
[[ -z "$KJ$E" ]] && {
  KJ="`bash -c "$MYD/pkgs/kj-build.sh -q -s"`"
  :
} || KJ="https://koji.fedoraproject.org/koji/taskinfo?taskID=$KJ" \

[[ -z "$CR" ]] \
  && CR="_TBD_" \
  || CR="https://copr.fedorainfracloud.org/coprs/build/$CR"


R=0
[[ -n "$E" ]] && {
  R=1
  TP="$TP\n  - Error: $E"
  :
} || E='Success'


echo -e "\n=> $E\n_ _ _ _\n\nrpmlint: $RPML\n"

} >&2

cat <<EOLX | tee -a /dev/stderr

_ _ _ _

To have latest $g gem in Fedora.


Up-to-date Koji scratch-build:
$KJ

Up-to-date Copr build:
$CR

Checks:
$( echo -e "$TP" )

EOLX

exit $R
