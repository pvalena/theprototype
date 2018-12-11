#!/usr/bin/bash

ls -d * | xargs -i bash -c "echo; set -x; cd '{}' && { gits -uno |grep -v ^$; }"

