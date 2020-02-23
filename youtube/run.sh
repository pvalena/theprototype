#!/bin/bash
#
# Upload a video using `upload_video.py`.
#
# Usage:
#   ./run.sh [options] VIDEO_FILE TITLE DESCRIPTION
#
# Options:
#   --pretend   output what would be run
#
# Environment variables:
#   KEYWORDS
#   PRIVACYSTATUS
#   CATEGORY
#
# Example:
#   ./run.sh --pretend video.mp4 TEST "`echo -e "Automatically uploaded.\nPlease contact pvalena@redhat.com in case of questions."`"
#
# Author:
#   pvalena@redhat.com
#

# Nothing should fail up until ARGS
set -e

## HELPERS ##
abort () {
  echo "Error:" "$@" >&2
  exit 1
}
usage () {
  which awk &>/dev/null || abort 'No awk'
  which sed &>/dev/null || abort 'No sed'

  awk '{if(NR>1)print;if(NF==0)exit(0)}' < "$0" | sed '
    s|^#[   ]||
    s|^#$||
  ' | ${PAGER-more}
  exit 0
}

## CHECKS ##
bash -n "$0" || abort 'Syntax'
python --version &>/dev/null || abort 'Python'

## VARS ##
KEYWORDS="${KEYWORDS:-devconf.cz}"
PRIVACYSTATUS="${PRIVACYSTATUS:-private}"
CATEGORY="${CATEGORY:-28}"

## INTERNAL ##
UPLOAD=y
FNAME=
TITLE=
DESC=

# Sanity reached
set +e

## ARGS ##
[[ "$1" == "--help" ]] && usage
[[ "$1" == "--pretend" ]] && { UPLOAD=''; shift; }

FNAME="$1"; shift
[[ -r "$FNAME" ]] || abort "File not readable: $FNAME"

TITLE="$1"; shift
[[ -n "$TITLE" ]] || abort "Empty Title"

DESC="$1"; shift
[[ -n "$DESC" ]] || abort "Empty Description"


## RUN ##
[[ -n "$UPLOAD" ]] && {
  python upload_video.py \
    --noauth_local_webserver \
    --file="$FNAME" \
    --title="$TITLE" \
    --description="$DESC" \
    --keywords="$KEYWORDS" \
    --privacyStatus="$PRIVACYSTATUS" \
    --category="$CATEGORY"
  exit $?
}

set -x
echo \
  python upload_video.py \
    --noauth_local_webserver \
    --file="$FNAME" \
    --title="$TITLE" \
    --description="$DESC" \
    --keywords="$KEYWORDS" \
    --privacyStatus="$PRIVACYSTATUS" \
    --category="$CATEGORY" &>/dev/null
