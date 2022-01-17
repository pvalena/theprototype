#!/bin/bash

 die () {
  echo -e "\n--> Error: $1"
  exit 0

 }

 clear

 mock --init || die INIT

 mock -n --pm-cmd group install "C Development Tools and Libraries" || die INST_1

 mock -n --pm-cmd install {ruby,libxml2,sqlite}-devel nodejs || die INST_2

 mock -n --unpriv --chroot 'gem install rails sqlite3 --no-doc' || die INST_3

 mock -n --unpriv --chroot 'export PATH="$PATH:`readlink -e ~/bin`" && cd && mkdir -p test && cd test && rails new app && cd app && rails --version && rails s && echo "-->OK"' || die CMD_1
