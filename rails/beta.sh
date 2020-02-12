#!/bin/bash

set -xe
bash -n "$0"

[[ -n "$1" ]] || {
  find . -maxdepth 2 -type f -iname '*.spec' \
    | xargs -r "$0"

  exit "$?"
}

OLD_VERSION="${1:-6.0.0}"
VERSION="${2:-6.0.2}"
BETA="${3:-.rc1}"

GET="$(readlink -e "`dirname "$(readlink -e "$0")"`/../gems/get.sh")"
[[ -x "$GET" ]]


myd="`pwd`"
for sf in "$@"; do
  set -e
  f="$(basename "$sf")"
  d="$(dirname "$sf")"

  cd "$myd"
  [[ -d "$d" ]] && cd "$d" ||:
  [[ -r "$f" ]] || exit 2

  g="$(cut -d'-' -f2- <<< "$f" | cut -d'.' -f1)"

  # spec file edits
  [[ -z "$OLD_VERSION" ]] || {
    sed -i "s/${OLD_VERSION}/${VERSION}${BETA}/g" "$f"
  }

  sed -i "s/^\(Version:\).*$/\1 ${VERSION}/" "$f"
  sed -i "s/^\(Release:\).*$/\1 1%{?dist}/" "$f"

  sed -i 's/%{version}/%{version}%{?prerelease}/g' "$f"
  sed -i 's/%{?prerelease}%{?prerelease}/%{?prerelease}/g' "$f"
  sed -i '/^\s*BuildRequires:/ s/%{?prerelease}//g' "$f"
  sed -i '/^\s*Requires:/ s/%{?prerelease}//g' "$f"

  sed -i '/^\s*%global prerelease/ d' "$f"
  [[ -z "$BETA" ]] || {
    sed -i "/^%global gem_name/ a \
      `echo -e "\n"` \
      %global prerelease ${BETA}" "$f"
  }

  # use git archive and .txz
  sed -i "s/git checkout \(\S*\) && tar \S* \(\S*\)\.\S*/git archive -v -o \2.txz \1/" "$f"
  sed -i "s/&& git checkout \S*/--no-checkout/" "$f"
  sed -i "s/&& cd \S*/--no-checkout/" "$f"
  sed -i "s/--no-checkout --no-checkout/--no-checkout/" "$f"
  sed -i "s/tar \S* \(\S*\)\.\S*/git archive -v -o \1.txz v???/" "$f"
  sed -i 's/^\s*\(Source\S*\)\s*\(\S*\)\.t\S*/\1 \2.txz/' "$f"

  # done
  set +ex

  # cleanup
  { rm *.src.rpm ; rm *.gem ; rm *.tgz ; rm *.tar.gz ; } &>/dev/null

  # fetch the new gem version
  gem fetch --pre "$g"

  ## sources
  # run the command get ~magic~
  bash -c "$GET '$f' '$VERSION$BETA'" ||:

  grep -qE 'rails-\S*-tools' "$f" && cp -v ../rubygem-activesupport/rails-*-tools.txz .
done

exit 0
########## NAH ##########
  find -type f -iname '*~*.tgz' -or -iname '*~*.gem' \
    | xargs -i bash -c "f=\$(rev <<< '{}' | cut -d'~' -f2- | rev) ; a=\$(rev <<< '{}' | cut -d'~' -f1 | rev) ; mv -v '{}' \"\${f}.\${a}\" || exit 255"

  grep -A 10 ' git clone ' "$X" | grep -E "$gcom" \
    | xargs -i bash -c "O=\$(sed -e 's|/|\\\/|g' <<< '{}') ; set -x ; sed -i \"/^\$O/ s/${OLD_VERSION}/${VERSION}/g\" "$X""

