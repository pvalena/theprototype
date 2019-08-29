#!/bin/bash

set -xe
bash -n "$0"

MYD="`readlink -e "$(dirname "$0")/.."`"
[[ -d "$MYD" ]]

rel='f32'

msr='-n --new-chroot --result=./result'
mar='--bootstrap-chroot'
# Fallback:
#msr='-n --old-chroot --result=./result'
#mar=''
mck () {
  a=""
  while [[ -n "$1" ]]; do a="$a '$1'" ; shift ; done

  bash -c "set -x ; mock $msr $mar $a"
  return $?
}

R=0
E=''
fail () {
  R=1
  E="$E\n$(echo "=> $@ Failed" | tee -a /dev/stderr)"
  return 0
}

me="pvalena"
mc="rubygems"
gp='rubygem-'

[[ "$1" == '-c' ]] && {
  CON="$1"
  shift
  :
} || CON=

[[ "$1" == '-r' ]] && {
  msr="${msr} -r $2"
  shift 2
  :
}

[[ "$1" == '-v' ]] && {
  mc="vagrant"
  gp="vagrant-"
  shift
  :
}

tb='copr'
rm='copr/master'

kl="$me@FEDORAPROJECT\.ORG"
( klist -a | grep -q "${kl}$" ) || {
  pgrep -x krenew || krenew -i -K 60 -L -b
  kinit "$kl" -l 30d
}

p="$1"
[[ -n "$p" ]] && {
  [[ -n "`grep "^$gp" <<< "$p"`" ]] && g="$p" || g="$gp$p"
  [[ -d "$g" ]] || fedpkg --user "$me" clone -a "$g"
  [[ -d "$g" ]]
  cd "$g"
  :
} || {
  g="`basename "$PWD"`"
  p="$(cut -d'-' -f2- <<< "$g")"
}

[[ -n "$p" && -n "$g" ]]
grep "^$gp" <<< "$g"

CINIT=
[[ -n "$CON" ]] || {
  git remote add "$tb" "https://copr-dist-git.fedorainfracloud.org/cgit/$me/$mc/$g.git" ||:
  #for x in {1..2}; do
  #
  #  git remote remove "$tb"
  #done
  gitf "$tb"

  #git remote add "$me" "ssh://$me@pkgs.fedoraproject.org/forks/$me/rpms/$g" ||:
  #gitf "$me"

  gitt
  gitc "$tb" \
   || gitcb "$tb" -t "$rm"

  [[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "$tb" ]]
  gitrh "$rm"
  gitb -u "$rm"

  gem fetch "$p"||:
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

mar=''
for c in "{x86_64,noarch}" {x86_64,noarch} ; do
  x="$(bash -c "ls result/*.${c}.rpm")" || continue

  mck -i $x && {
    [[ "$c" == "{x86_64,noarch}" ]] && break
    :
  } \
    || fail "Install $c"
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
grep -q ' 0 failures' result/build.log && {
  grep -q ' 0 errors' result/build.log && {
    grep -q ' 0 assertions' result/build.log \
      && TP="$TP no assertions" \
      || TP="$TP ok"
    :
  } || TP="$TP errors"
  :
} || TP="$TP failures"

TP="$TP\n  - Dependent packages:"
DEP="$( bash -c "$MYD/gems/whatrequires.sh -q '$p'" )" \
  && TP="$TP ok" || TP="$TP $DEP"

[[ $R -eq 0 ]] && {
  TP="$TP\n  - Smoke test(require):"
  for c in "rpm -q \"$g\"" "ruby -e \"require '\''$p'\''\"" 0 ; do
    [[ "$c" == '0' ]] && {
      TP="$TP ok"
      break
    }
    mck --unpriv --chroot "$c" \
      || TP="$TP failed"
  done
}||:

RPML="$( rpmlint result/*.rpm 2>/dev/null | sort -u )"

{ set +x ; } &>/dev/null

echo -e "\n\n$RPML"

[[ -z "$E" ]] \
  && echo -e "\n=> Success" \
  || echo -e "\n$E"

cat <<EOLX
_ _ _ _

To have latest $p gem in Fedora.


Up-to-date Koji scratch-build:
$( bash -c "$MYD/pkgs/kj-build.sh -q $rel" )

Up-to-date Copr build:
?

Checks:
$( echo -e "$TP" )
  - rpmlint: ?

EOLX

exit $R
