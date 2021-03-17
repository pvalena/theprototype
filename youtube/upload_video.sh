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
#   TAGS
#   PRIVACYSTATUS
#   CATEGORY
#
# Example:
#   ./run.sh --pretend video.mp4 TEST "`echo -e "Automatically uploaded.\nPlease contact pvalena@redhat.com in case of questions."`"
#
# Author:
#   pvalena@redhat.com
#
#

# Nothing should fail up until ARGS
set -e
PROG=youtube-upload/bin/youtube-upload

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
#python2 --version &>/dev/null || abort '`python2` needed'
[[ -x "$PROG" ]]

## VARS ##
TAGS="${TAGS:-devconf.cz}"
PRIVACYSTATUS="${PRIVACYSTATUS:-private}"
CATEGORY="${CATEGORY:-Science & Technology}"

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

LIST="$1"; shift
[[ -n "$LIST" ]] || abort "Empty Playlist"

## RUN ##
# Using the new app
[[ -n "$UPLOAD" ]] && {
  $PROG \
      --title="$TITLE" \
      --description="$DESC" \
      --tags="$TAGS" \
      --privacy="$PRIVACYSTATUS" \
      --client-secrets="client_secrets.json" \
      --credentials-file="credentials.json" \
      --playlist="$LIST" \
      --category="$CATEGORY" \
    "$FNAME"
  exit $?
}

set -x
echo $PROG \
      --title="$TITLE" \
      --description="$DESC" \
      --tags="$TAGS" \
      --privacy="$PRIVACYSTATUS" \
      --client-secrets="client_secrets.json" \
      --credentials-file="credentials.json" \
      --playlist="$LIST" \
      --category="$CATEGORY" \
    "$FNAME"

exit 0

# Obsolete script
[[ -n "$UPLOAD" ]] && {
  python2 upload_video.py \
    --noauth_local_webserver \
    --title="$TITLE" \
    --file="$FNAME" \
    --description="$DESC" \
    --keywords="$KEYWORDS" \
    --privacyStatus="$PRIVACYSTATUS" \
    --category="$CATEGORY"
  exit $?
}

set -x
echo \
  python2 upload_video.py \
    --noauth_local_webserver \
    --file="$FNAME" \
    --title="$TITLE" \
    --description="$DESC" \
    --keywords="$KEYWORDS" \
    --privacyStatus="$PRIVACYSTATUS" \
    --category="$CATEGORY" &>/dev/null
