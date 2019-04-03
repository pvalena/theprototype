#!/bin/bash

false && {
find -type f -iname '*~*.tgz' -or -iname '*~*.gem' \
  | xargs -i bash -c "f=\$(rev <<< '{}' | cut -d'~' -f2- | rev) ; a=\$(rev <<< '{}' | cut -d'~' -f1 | rev) ; mv -v '{}' \"\${f}.\${a}\" || exit 255"

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^Version:/ s/.beta1//'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^%global gem_name/ a %global prerelease beta2'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i 's/%{version}/%{version}%{?prerelease}/g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i 's/%{?prerelease}%{?prerelease}/%{?prerelease}/g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^BuildRequires:/ s/%{?prerelease}//g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^Requires:/ s/%{?prerelease}//g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^%global gem_name/ a %global pre_name beta1'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^%global prerelease/ s/beta1/%{?pre_name}/g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i 's/%{?prerelease}%{?prerelease}/%{?prerelease}/g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^BuildRequires:/ s/%{?prerelease}/%{?pre_name}/g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i '/^Requires:/ s/%{?prerelease}/%{?pre_name}/g'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i 's/^Release: 1/Release: 0.1/'

find -type f -iname '*.spec' \
  | xargs -n1 sed -i 's/beta1/beta2/g'

find -type f -iname '*.spec' \
  | xargs -i bash -c "set -e ; d=\"\$(dirname '{}')\" ; [[ -n \"\$d\" ]] || exit 3 ; cd \"\$d\" ; g=\"\$(cut -d'-' -f2- <<< \"\$d\")\" ; set +e ; { rm *.src.rpm ; rm *.gem ; } &>/dev/null ; gem fetch --pre \"\${g}\" || exit 255"

find -type f -iname '*.spec' \
  | xargs -i bash -c "echo ; set -e ; d=\"\$(dirname '{}')\" ; [[ -n \"\$d\" ]] || exit 3 ; cd \"\$d\" ; t=\"\$(pwd)\" ; g=\"\$(cut -d'-' -f2- <<< \"\$d\")\" ; ls *.tgz ; set +e ; pwd ; ls *.tgz | xargs -I[] bash -c \"set -e ; s=\\\"\\\$(sed 's/tests/test/' <<< '[]' | rev | cut -d'.' -f2- | cut -d'-' -f1 | rev)\\\" ; x=\\\"\${t}/\\\$(sed 's/beta1/beta2/' <<< '[]')\\\" ; echo \\\"'\\\${s}' => '\\\${x}'\\\"; set -x ; cd \\\"../../upstream/rails/\$g/\\\" ; git fetch ; git checkout v6.0.0.beta2 || exit 255 ; tar czvf \\\"\\\${x}\\\" \\\"\\\${s}/\\\" || exit 255 ; rm -v '\${t}/[]'\" || exit 255"

}
