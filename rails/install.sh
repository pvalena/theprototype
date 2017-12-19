#!/bin/bash
#
# mock -q --clean
# mock -q --init

for s in {1..20}; do Err= ; while read z; do echo ; set -x ; mock -qni "$z" || Err=yes ; set +x ; done < <(ls */result/*.rpm | grep -v '\.src.rpm$' | grep -v '\-doc' ) ; [[ -z "$Err" ]] && break ; done
