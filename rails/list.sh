#!/bin/bash

 [[ "$1" ]] || { echo 'Tag missing (fXX)' >&2 ; exit 1 ; }

 koji list-tagged --latest "$@" | tr -s ' ' \
  | grep -E '^rubygem-(acti(on(cable|mailer|pack|view)|ve(job|model|record|support))|rail(s|ties))-[0-9]' \
  | cut -d' ' -f1
