#!/bin/bash

scl="rh-ror50"
pkg="rubygem-sprockets"
ver="3.7.1"
cnf="rhscl-3.1-$scl-rhel-7-x86_64"
lnk="http://download.eng.bos.redhat.com/brewroot/packages/$scl-$pkg/$ver/1.el7/noarch/$scl-$pkg-$ver-1.el7.noarch.rpm"

grep baseurl "/etc/mock/$cnf.cfg"

chr="--unpriv --chroot 'cd;"
cda="cd app;"
enb="timeout 5 scl enable $scl rh-nodejs6 --"
tes="$chr $cda $enb rails s ; sleep 1'"             # 'sleep' needed for graceful shutdown

for cmd in \
  "--clean" \
  "--init" \
  "-i $lnk                                          ;: 'Installed older version of $pkg.'" \
  "-i $scl rh-nodejs6" \
  "$chr $enb rails new app'                         ;: 'Created rails app.'" \
  "$tes                                             ;: 'For the first time, test passes.'" \
  "--pm-cmd update                                  ;: 'Updated to new version of $pkg.'" \
  "$tes                                             ;: 'Test fails now.'" \
  "$chr $cda rm Gemfile.lock'" \
  "$chr $cda $enb bundle install --local'           ;: 'Regenerated Gemfile.lock.'" \
  "$tes                                             ;: 'Test works now.'" \
;do
  bash -c "echo ; set -x ; mock -qnr $cnf $cmd"
done
