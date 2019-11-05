#!/bin/bash

# >&2
{
set -xe
bash -n "$0"

MYD="`readlink -e "$(dirname "$0")/.."`"
[[ -d "$MYD" ]]

rel='f32'

# mock changes it's verbosity if output is redirected
[[ -t 1 ]] && v='' || v="-v "
msr="${v}-n -r fedora-rubygems-x86_64 --new-chroot --result=./result"
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

[[ "$1" == '-c' ]] && {
  CON="$1"
  shift
  :
} || CON=

[[ "$1" == '-k' ]] && {
  KJ="$1"
  shift
  :
} || KJ=

[[ "$1" == '-r' ]] && {
  msr="${msr} -r $2"
  shift 2
}

[[ "$1" == '-v' ]] && {
  mc="vagrant"
  gp="vagrant-"
  shift
}

tb='copr'
rm='copr/master'

[[ -z "$KJ" ]] || {
  kl="$me@FEDORAPROJECT\.ORG"
  ( klist -a | grep -q "${kl}$" ) || {
    pgrep -x krenew || krenew -i -K 60 -L -b
    kinit "$kl" -l 30d
  }
}

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

CINIT=
[[ -n "$CON" ]] || {
  git remote add "$tb" "https://copr-dist-git.fedorainfracloud.org/cgit/$me/$mc/$p.git" ||:
  #for x in {1..2}; do
  #
  #  git remote remove "$tb"
  #done
  gitf "$tb"

  #git remote add "$me" "ssh://$me@pkgs.fedoraproject.org/forks/$me/rpms/$p" ||:
  #gitf "$me"

  gitt ||:
  gitc "$tb" \
   || gitcb "$tb" -t "$rm"

  [[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "$tb" ]]
  gitrh "$rm"
  gitb -u "$rm"

  gem fetch "$g" ||:
  CINIT="`echo --{clean,init}`"
}

rm *.src.rpm ||:
rm -rf result/ ||:
#fedpkg --release master sources
fedpkg --release $rel srpm

for c in $CINIT *.src.rpm; do
  mck $c
  sleep 0.1
done

E=''
mar=''
for c in "{x86_64,noarch}" {x86_64,noarch} ; do
  x="$(bash -c "ls result/*.${c}.rpm")" || continue

  mck -i $x && {
    [[ "$c" == "{x86_64,noarch}" ]] && break
    :
  } || E="Install $c Failed"
done


TP="  - Syntax check:"
mck --unpriv --shell '
  cd
  find -type f -name "*.rb" \
    | xargs -i bash -c \
      "{ ruby -c \"{}\" 2>&1 || exit 255 ; } | grep -v \"^Syntax OK$\""
  :
' && TP="$TP ok" || TP="$TP failed"


TP="$TP\n  - Tests:"
grep -q '^Executing(%check)'  result/build.log && {
grep -q ' 0 failures'         result/build.log && {
grep -q ' 0 errors'           result/build.log && {
grep -q ' 0 assertions'       result/build.log \
  && TP="$TP no assertions" \
  || TP="$TP ok"
:
} || TP="$TP errors"
:
} || TP="$TP failures"
:
} || TP="$TP nocheck"


TP="$TP\n  - Dependent packages:"
DEP="$( bash -c "$MYD/gems/whatrequires.sh -q '$g'" )" \
  && TP="$TP ok" \
  || TP="$TP $DEP"


[[ -n "$E" ]] || {
  TP="$TP\n  - Smoke test:"
  q="`sed -e '/minitest\-/ s/\-/\//' <<< "$g"`"
  q="`sed -e 's/^ruby//' <<< "$q"`"
  for c in "rpm -q \"$p\"" "ruby -e \"require '\''$q'\''\"" 0 ; do
    [[ "$c" == '0' ]] \
      && TP="$TP ok" \
      || {
        mck --unpriv --chroot "$c" || {
          TP="$TP failed('$c')"
          break
        }
      }
  done
}


set -o pipefail
TP="$TP\n  - rpmlint:"
RPML="$( rpmlint result/*.rpm 2>/dev/null | sort -u )" \
  && TP="$TP ok" \
  || TP="$TP failed"


# In case we dont do this from gup.sh
[[ -z "$KJ" ]] \
  && KJB="_TBD_" \
  || KJB="`bash -c "$MYD/pkgs/kj-build.sh -q -s"`"


{ set +x ; } &>/dev/null
R=0
[[ -n "$E" ]] && R=1 || E='Success'


echo -e "\n=> $E\n_ _ _ _\n\nrpmlint: $RPML\n"

} >&2

cat <<EOLX | tee -a /dev/stderr

_ _ _ _

To have latest $g gem in Fedora.


Up-to-date Koji scratch-build:
$KJB

Up-to-date Copr build:
_TBD_

Checks:

$( echo -e "$TP" )

EOLX

exit $R
