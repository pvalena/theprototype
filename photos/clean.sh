#!/usr/bin/bash

set -e
bash -n "$0"
cd "$(dirname "$0")/tmp"

ls *

read -n1 -p 'Are you sure to cleanup? ' Z

[[ "$Z" =~ Yy ]] || exit 1

echo rm *
