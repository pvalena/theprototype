#!/usr/bin/bash

set -e
bash -n "$0"
cd "$(dirname "$0")/tmp"

ls ${1:-*} | xargs -i bash -c "echo -n '{}: '; grep 'liked this photo' '{}' | sort -u | wc -l"

