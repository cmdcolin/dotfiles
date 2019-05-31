#!/bin/bash

CMUS_HOME=${CMUS_HOME:-$HOME/.config/cmus}
LAST_TRACK_FILE=$CMUS_HOME/last_track.pl
RECENTLY_PLAYED_FILE=$CMUS_HOME/recently_played.pl

if ! cmus-remote -C >/dev/null 2>&1 ; then
    echo >&2 "cmus is not running"
    exit 1
fi

last_file=
if [ -r "$LAST_TRACK_FILE" ] ; then
    last_file=$(head -n1 "$LAST_TRACK_FILE")
fi

file=
while [ $# -gt 0 ] ; do
    case "$1" in
    file)
        shift
        file=$1
        shift
        ;;
    *)
        shift
        ;;
    esac
done

if [ "$last_file" != "$file" ] ; then
    cmus-remote -C "win-sel-cur"
    echo "$file" >"$LAST_TRACK_FILE"
    echo "$(echo $file; cat $RECENTLY_PLAYED_FILE|head -n 5000)" > $RECENTLY_PLAYED_FILE
fi

