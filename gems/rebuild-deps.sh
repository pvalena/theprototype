#!/usr/bin/bash

set -e
bash -n "$0"

[[ "$1" == "-d" ]] && {
  set -x
  debug="set -x;"
  shift
  :
} || debug=

[[ "$1" == "-i" ]] && {
  ti="$2"
  shift 2
  :
} || ti=15

[[ "$1" == "-p" ]] && {
  pretend="echo"
  shift
  :
} || pretend=

[[ "$1" == "-t" ]] && {
  target="$2"
  shift 2
  :
} || target="rubygems"

[[ "${1:0:1}" == '-' ]] && exit 1

xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source --enablerepo='copr:copr.fedorainfracloud.org:pvalena:$target' --latest-limit=1"

checkfail="|| { echo '{}' >> `readlink -f failed.txt`; }"

myd="$(dirname "$(readlink -f "$0")")"
crb="$(readlink -f "${myd}/../pkgs/cr-build.sh")"

[[ -x "$crb" && -n "$crb" ]]

set +e

while [[ -n "$1" ]]; do
  p="$1"
  shift ||:

  echo ">>> Rebuilding dependencies of package: \"$p\""

  bash -c " set -x; { $xdnf --qf '%{name}' --whatrequires '$p' --arch=src ; $xdnf --qf '%{name}' --whatrequires '$p'; } | grep '^rubygem\-' | sort -u | xargs $xdnf --qf '%{source_name}' | grep -v '^(none)' | sort -uR | grep '^rubygem\-'" \
    | tee -a error.log \
    | xargs -i bash -c "[[ -d '{}' ]] || fedpkg co '{}'; cd '{}' $checkfail; echo; pwd; gitc rawhide; gitfo; gitt; giteo; fedpkg sources; gits; $debug $pretend $crb $target $checkfail; sleep $ti"
done
