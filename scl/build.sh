#!/bin/bash

[[ "$1" ]] || exit 1
[[ "$2" ]] || X=centpkg-sclo

B="${1}-x86_64"

rm *.src.rpm
$X srpm
rm -rf result/
mock -n -q -r "$B" --resultdir=result *.src.rpm && echo build ok
rm -f result/*.src.rpm
mock -n -q -r "$B" -i result/*.rpm && echo install ok
