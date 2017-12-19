#!/bin/bash
#

while [[ "$1" ]] ; do
g="$1" ; for a in '' --arch=src ; do for z in -$g "($g)"; do dnf repoquery -q --disablerepo='*' --enablerepo='rawhide-source' --enablerepo='rawhide' ${a} --whatrequires "rubygem${z}" ; done ; done | rev | cut -d'.' -f2- | rev | sort -u
shift
echo
done
