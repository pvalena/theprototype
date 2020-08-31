#!/bin/bash

BR="${1:-rebase}"

ls -d rubygem-*/ | cut -d'/' -f1 | xargs -i bash -c "set -e; cd '{}'; O=\"\$(gits | grep -v '^Changes no staged for commit' | grep -v '^nothing to commit' | grep -v '^On branch $BR' | grep -v '^Your branch is up to date with' | grep -v ^$ | grep -v 'use \"git push\" to publish your local commits')\"; [[ -z \"\O\" ]] && exit 0; echo; pwd; echo \"\$O\""

