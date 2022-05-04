#!/usr/bin/bash

  echo ">> STATUS"
  ls -d rubygem-*/ \
    | cut -d'/' -f1 \
    | xargs -i bash -c "echo -ne '\n> '; cd '{}' && pwd && gitl -2 --oneline | cat || exit 255"
  echo
