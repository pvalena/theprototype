#!/usr/bin/bash

set -e
bash -n "$0"

./count.sh | ./reverse.sh | sort -nr | ./reverse.sh
