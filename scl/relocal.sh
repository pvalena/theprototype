#!/bin/bash
exit 1

r="scl-el7-x86_64"
date -I'ns' &> ~/Work/RH/tmp/fail.log
cd ~/Work/RH/tmp/
rm -rf */result/
mock -r $r -q --clean
sleep 0.5
mock -r $r -q --init
sleep 0.5
rm -f /home/vagrant/Work/RH/scl/rhel/ruby/ruby/result/*.src.rpm
mock -r $r -qn -i /home/vagrant/Work/RH/scl/rhel/ruby/ruby/result/*.rpm
cd ~/Work/RH/tmp/sclo-vagrant1/
centpkg-sclo srpm
mock -r $r --resultdir="`pwd`/result/" -qn *.src.rpm
sleep 0.5
mock -r $r -qn -i result/*-build-*.rpm result/*-runtime-*.rpm
sleep 0.5
for h in `seq 1 15` ; do
cd ~/Work/RH/tmp/
while read f; do
sort -u ~/Work/RH/tmp/fail.log | grep -v "^$" > ~/Work/RH/tmp/tmp.log
mv ~/Work/RH/tmp/{tmp,fail}.log
r="scl-el7-x86_64"
n="`rev <<< "$f" | cut -d'-' -f3- | rev`"
cd ~/Work/RH/tmp/$n || break
rm -rf result/
rm -f *.src.rpm
centpkg-sclo srpm || { echo "SRPM $n" &>>~/Work/RH/tmp/fail.log ; continue ; }
mock -r $r --resultdir="`pwd`/result/" -qn *.src.rpm || { echo "BYLD $n" &>>~/Work/RH/tmp/fail.log ; continue ; }
sleep 0.5
rm -f result/*.src.rpm
mock -r $r -qn -i result/*.rpm || { echo "INST $n" &>>~/Work/RH/tmp/fail.log ; continue ; }
sleep 0.5
sort -u ~/Work/RH/tmp/fail.log | grep -v " $n$" > ~/Work/RH/tmp/tmp.log
mv ~/Work/RH/tmp/{tmp,fail}.log
echo "OKOK $n" &>>~/Work/RH/tmp/fail.log
done < <( ls *.src.rpm | cut -d'-' -f3- | grep -vE "^[0-9]" )
done

######################################

r="scl-el7-x86_64"
date -I'ns' &> ~/Work/RH/tmp/fail.log
cd ~/Work/RH/tmp/
rm -f /home/vagrant/Work/RH/scl/rhel/ruby/ruby/result/*.src.rpm
mock -r $r -qn -i /home/vagrant/Work/RH/scl/rhel/ruby/ruby/result/*.rpm
cd ~/Work/RH/tmp/sclo-vagrant1/
centpkg-sclo srpm
mock -r $r --resultdir="`pwd`/result/" -qn *.src.rpm
sleep 0.5
mock -r $r -qn -i result/*-build-*.rpm result/*-runtime-*.rpm
sleep 0.5
for h in `seq 1 5` ; do
cd ~/Work/RH/tmp/
while read f; do
sort -u ~/Work/RH/tmp/fail.log | grep -v "^$" > ~/Work/RH/tmp/tmp.log
mv ~/Work/RH/tmp/{tmp,fail}.log
r="scl-el7-x86_64"
n="`rev <<< "$f" | cut -d'-' -f3- | rev`"
cd ~/Work/RH/tmp/$n || break
rm -rf result/
rm -f *.src.rpm
centpkg-sclo srpm || { echo "SRPM $n" &>>~/Work/RH/tmp/fail.log ; continue ; }
mock -r $r --resultdir="`pwd`/result/" -qn *.src.rpm || { echo "BYLD $n" &>>~/Work/RH/tmp/fail.log ; continue ; }
sleep 0.5
rm -f result/*.src.rpm
mock -r $r -qn -i result/*.rpm || { echo "INST $n" &>>~/Work/RH/tmp/fail.log ; continue ; }
sleep 0.5
sort -u ~/Work/RH/tmp/fail.log | grep -v " $n$" > ~/Work/RH/tmp/tmp.log
mv ~/Work/RH/tmp/{tmp,fail}.log
echo "OKOK $n" &>>~/Work/RH/tmp/fail.log
done < <( ls *.src.rpm | cut -d'-' -f3- | grep -vE "^[0-9]" )
done
