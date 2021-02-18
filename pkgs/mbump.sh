#!/bin/bash

set -xe
bash -n "$0"

X="$(ls *.spec | head -1)"

mat="^\s*\(Release:\s*[0-9]*\)"

maf="${mat/\\\(/}"
Z="$(grep -E "${maf/\\\)/}" "$X")"
[[ -n "$Z" ]]

Z="$(sed -n '/[0-9]\.[0-9]/ {p;q}' <<< "$Z")"

[[ -z "$Z" ]] && exec sed -i "s/$mat/\1.1/" "$X"

Z="$(sed -e "s/$mat//" -e "s/\.\([0-9]*\).*/\1/" <<< "$Z")"
Z="$((Z += 1))"

sed -i "s/${mat}\.[0-9]*\(.*\)/\1\.${Z}\2/" "$X"

