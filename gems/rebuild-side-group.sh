#!/usr/bin/bash

set -e
bash -n "$0"

bask () {
  read -p "$1 " -n1 a
  echo

  [[ "$a" == "y" || "$a" == "yes" ]] || return 1
  return 0
}

[[ "-d" == "$1" ]] && {
  DEBUG="y"
  shift
  :
} || DEBUG=

[[ "-n" == "$1" ]] && {
  NOBUILD="y"
  shift
  :
} || NOBUILD=

[[ "-o" == "$1" ]] && {
  OWNED="y"
  shift
  :
} || OWNED=

[[ "-r" == "$1" ]] && {
  REPEAT="$2"
  shift 2
  [[ -n "$NOBUILD" ]] && { echo "NOBUILD(-n) does not make sense in combination with REPEAT(-r $REPEAT)" >&2 ; exit 3; }
  :
} || REPEAT=

[[ "-t" == "$1" ]] && {
  TARGET="-t $2"
  shift 2
  :
} || TARGET=

[[ -n "$1" ]] || exit 1


[[ -z "$NOBUILD" ]] && {
  bask "Really build?" || exit 2
}

SREPEAT="$REPEAT"
xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source   --latest-limit=1"
#xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source --enablerepo='copr:copr.fedorainfracloud.org:pvalena:ruby-testing' --enablerepo='copr:copr.fedorainfracloud.org:pvalena:rubygems-testing' --latest-limit=1"
fail="{ echo '{}' >> `readlink -f failed.txt`; exit 1; }"
l="################################################################"

[[ -n "$OWNED" ]] && {
  mine="$(
      ~/lpcsf-new/test/scripts/fedora/list_group_packages.sh ruby-packagers-sig
      ~/lpcsf-new/test/scripts/fedora/list_owned_packages.sh pvalena
    )"
  :
} || {
  mine="$(~/lpcsf-new/test/scripts/fedora/list_group_packages.sh ruby-packagers-sig)"
}

[[ -n "$DEBUG" ]] && {
  echo "$l"
  echo -e "All (unfiltered) packages:\n$mine\n"

} >&2

# \$1: libruby.so.3.0()

while [[ -n "$1" ]]; do
  p="$1"

  echo -e "\n${l}\nPackages selected for build:" >&2

  bash -c " [[ -n '$DEBUG' ]] && set -x; { $xdnf --qf '%{name}' --whatrequires '$p' --arch=src ; $xdnf --qf '%{name}' --whatrequires '$p'; } | grep '^rubygem\-' | sort -u | xargs -r $xdnf --qf '%{source_name}' | grep -v '^(none)' | sort -u | grep '^rubygem\-'" \
    | xargs -ri bash -c "grep '^{}$' <<< \"$mine\"" \
    | tee -a /dev/stderr \
    | sort -uR \
    | xargs -ri bash -c "
        echo; echo
        set -e
        [[ -d '{}' ]] || fedpkg co '{}'
        cd '{}' || $fail
        pwd
        set -x
        gitc rawhide
        gitfo
        gitrh origin/rawhide
        gitl --oneline -2 | grep 'Rebuilt for https://fedoraproject.org/wiki/Changes/Ruby_3\.1' && exit ||:
        gitl --oneline -2 | grep 'rebuild against ruby31' && exit ||:
        [[ -r ruby31.status ]] && { grep 'done' ruby31.status && exit ; } ||:
        { set +x; } &>/dev/null
        echo wip > ruby31.status
        rpmdev-bumpspec -c 'Rebuilt for https://fedoraproject.org/wiki/Changes/Ruby_3.1' -u 'Pavel Valena <pvalena@redhat.com>' *.spec
        gitiam 'Rebuilt for https://fedoraproject.org/wiki/Changes/Ruby_3.1'
        echo prepared > ruby31.status
        echo '$l'
        gith | colordiff
        gitl -2 | colordiff
        echo '$l'
        [[ -z '${NOBUILD}' ]] && ~/lpcsf-new/test/scripts/pkgs/bld.sh ${TARGET}
        [[ -z '${NOBUILD}' ]] && echo built > ruby31.status
      "

  [[ -n "$REPEAT" ]] && {
    let "REPEAT -= 1"
    [[ $REPEAT -gt 0 ]] && continue
  }
  REPEAT="$SREPEAT"
  shift ||:
done
