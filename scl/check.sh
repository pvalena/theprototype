#!/bin/bash

exit 1

r="scl-el7-x86_64"
while read p; do
mock -r $r -q --init
mock -r $r -n -v -i "$p" 2>&1 | grep ' ruby-libs ' && echo " ^^^ $p ^^^"
done < <( ls rubygem-*/result/*.rpm )
