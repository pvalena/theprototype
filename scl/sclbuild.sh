#!/bin/bash

exit 1

r="scl-el7-x86_64"
cd ~/Work/RH/tmp && rm -f */result/*.src.rpm
mock -r $r -q --init
mock -r $r -q -n -i /home/vagrant/Work/RH/scl/rhel/ruby/ruby/result/*.rpm && echo fok
mock -r $r -q -n -i sclo-vagrant1/result/*-{build,runtime}-*.rpm && echo sok
mock -r $r -q -n -i `ls rubygem-*/result/*.rpm | grep -vE '^rubygem-(fog-core|fog-libvirt|fog-xml|net-scp|net-sftp|net-ssh|webmock)/' | tr -s '\n' ' '`
cd ~/Work/RH/tmp/rubygem-fog-core && {
        rm -f *.src.rpm
        rm -rf result/
        centpkg-sclo srpm
        mock -r $r --resultdir="`pwd`/result/" -n *.src.rpm
        rm -f result/*.src.rpm
        ls result/*.rpm && mock -r $r -n -i result/*.rpm
}


########################

r="scl-el7-x86_64"
while read d; do
 cd ~/Work/RH/tmp && rm -f */result/*.src.rpm
 mock -r $r -q --init
 mock -r $r -q -n -i /home/vagrant/Work/RH/scl/rhel/ruby/ruby/result/*.rpm && echo fok
 mock -r $r -q -n -i 'rh-ror42-scldevel' && echo rok
 mock -r $r -q -n -i sclo-vagrant1/result/*-{build,runtime}-*.rpm && echo sok
 mock -r $r -q -n -i `ls rubygem-*/result/*.rpm | grep -vE '^rubygem-(fog-core|fog-libvirt|fog-xml|net-scp|net-sftp|net-ssh|webmock)/' | tr -s '\n' ' '`
 cd ~/Work/RH/tmp/$d && {
        rm -f *.src.rpm
        rm -rf result/
        centpkg-sclo srpm
        mock -r $r --resultdir="`pwd`/result/" -n *.src.rpm
        rm -f result/*.src.rpm
        ls result/*.rpm && mock -r $r -n -i result/*.rpm
 }
done < <( echo rubygem-{net-ssh,webmock} | tr -s ' ' '\n' )
