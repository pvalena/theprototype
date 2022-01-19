#!/bin/bash

set -xe
bash -n "$0"

myd="`readlink -e "$(dirname "$0")"`"
src="${myd}/sources.sh"

ls *.spec

V="$1"
P="`basename "$(pwd)"`"
M="Update to ${P} ${V}."

rpmdev-bumpspec -n "$V" -c "$M" -u "Pavel Valena <pvalena@redhat.com>" *.spec
nn *.spec

[[ -x "$src" ]] || echo "'$src' is not executable!" >&2
$src

gitiam "$M"
gith

