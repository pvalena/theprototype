#!/bin/bash

set -xe
bash -n "$0"

# needs to verbose `-v` to be able to capture proper error messages
msr='-n --new-chroot --result=./result'
mar='--bootstrap-chroot'
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
tb='copr'
rm='copr/master'

#kl="$me@FEDORAPROJECT.ORG"
#klist -a | grep -q "$kl" || {
#  psg -k krenew ||:
#  kinit "$kl" -l 30d
#  psg krenew || krenew -i -K 60 -L -b
#}

p="$1"
[[ -n "$p" ]]
[[ -n "`grep "^$gp" <<< "$p"`" ]] && g="$p" || g="$gp$p"
[[ -d "$g" ]] || fedpkg --user "$me" clone -a "$g"

cd "$g"

git remote add "$tb" "https://copr-dist-git.fedorainfracloud.org/cgit/$me/$mc/$g.git" ||:
#for x in {1..2}; do
#
#  git remote remove "$tb"
#done
gitf "$tb"

#git remote add "$me" "ssh://$me@pkgs.fedoraproject.org/forks/$me/rpms/$g" ||:
#gitf "$me"

gitc "$tb" \
 || gitcb "$tb" -t "$rm"

[[ "`gitb | grep '^* ' | cut -d' ' -f2-`" == "$tb" ]]
gitrh "$rm"

rm *.src.rpm ||:
rm -rf result/ ||:
#fedpkg --release master sources
gem fetch "$p"
fedpkg --release master srpm

for c in --{clean,init} *.src.rpm; do
  mck $c
  sleep 1
done

mar=''
for c in "{x86_64,noarch}" {x86_64,noarch} ; do
  x="$(bash -c "ls result/*.${c}.rpm")"
  [[ -n "$x" ]] || continue

  mck -i $x && {
    [[ "$c" == "{x86_64,noarch}" ]] && break
    :
  } \
    || fail "Install $c"
done

for c in "rpm -q \"$g\"" "ruby -e \"require '\''$p'\''\"" ; do
  mck --unpriv --chroot "$c" \
    || fail "$c"
done

rpmlint result/*.rpm | sort -u

{ set +x ; } &>/dev/null
[[ -z "$E" ]] && {
  echo "=> Success"
  :
} || echo -e "\n$E"
exit $R
