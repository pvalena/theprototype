#!/usr/bin/bash

set -ex
bash -n "$0"

[[ "-n" == "$1" ]] && {
  NOBUILD="echo"
  shift
  :
} || NOBUILD=

[[ -n "$1" ]] || exit 1

xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source   --latest-limit=1"

#xdnf="dnf -q repoquery '--disablerepo=*' --enablerepo=rawhide --enablerepo=rawhide-source --enablerepo='copr:copr.fedorainfracloud.org:pvalena:ruby-testing' --enablerepo='copr:copr.fedorainfracloud.org:pvalena:rubygems-testing' --latest-limit=1"

fail="{ echo '{}' >> `readlink -f failed.txt`; exit 1; }"

mine="$(~/lpcsf-new/test/scripts/fedora/list_group_packages.sh ruby-packagers-sig)"

echo -e "packages:\n$mine\n"

l="################################################################3"

# \$1: libruby.so.3.0()(64bit)

while [[ -n "$1" ]]; do
  p="$1"
  shift ||:
  bash -c " set -x; { $xdnf --qf '%{name}' --whatrequires '$p' --arch=src ; $xdnf --qf '%{name}' --whatrequires '$p'; } | grep '^rubygem\-' | sort -u | xargs $xdnf --qf '%{source_name}' | grep -v '^(none)' | sort -u | grep '^rubygem\-'" \
    | xargs -i bash -c "grep '^{}$' <<< \"$mine\"" \
    | tee -a /dev/stderr \
    | sort -uR \
    | xargs -i bash -c "
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
        [[ -r ruby31.status ]] && exit ||:
        { set +x; } &>/dev/null
        echo wip > ruby31.status
        rpmdev-bumpspec -c 'Rebuilt for https://fedoraproject.org/wiki/Changes/Ruby_3.1' -u 'Pavel Valena <pvalena@redhat.com>' *.spec
        gitiam 'Rebuilt for https://fedoraproject.org/wiki/Changes/Ruby_3.1'
        echo prepared > ruby31.status
        echo '$l'
        gith | colordiff
        gitl -2 | colordiff
        echo '$l'
        [[ -z '${NOBUILD}' ]] && ~/lpcsf-new/test/scripts/pkgs/bld.sh
        [[ -z '${NOBUILD}' ]] && echo built > ruby31.status
      "
done
