#!/bin/bash

set -xe
bash -n "$0"
ls *.spec
rpmdev-bumpspec -c 'Update to ' -u "Pavel Valena <pvalena@redhat.com>" *.spec
nn *.spec
fastdown "`spectool -A *.spec | grep ^Source0 | cut -d' ' -f2`"

for x in `spectool -A *.spec | grep ^Source | rev | cut -d' ' -f1 | cut -d'/' -f1 | rev | grep -vE '^(binstub|macros\.vagrant|macros|rubygems\.)' | grep -vE '\.(rb|stp)$'` ; do echo "SHA512 ($x) = `sha512sum "$x" | cut -d' ' -f1`" ; done > sources
