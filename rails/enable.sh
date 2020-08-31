#!/bin/bash

ls -d rubygem-*/ | cut -d'/' -f1 | xargs -i bash -c "set -e; echo; cd '{}'; pwd; sed -i 's/^%bcond_without bootstrap/%bcond_with bootstrap/' *.spec; Q=\"\$(gitd HEAD^ | cat)\" ; [[ -z \"\$Q\" ]] && exit 0; M='Enable tests.'; rpmdev-bumpspec -c \"\$M\" -u 'Pavel Valena <pvalena@redhat.com>' *.spec; gitiam \"\$M\""
