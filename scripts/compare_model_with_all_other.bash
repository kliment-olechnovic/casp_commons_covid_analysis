#!/bin/bash

MFILE="$1"

if [ -z "$MFILE" ] || [ ! -s "$MFILE" ]
then
	echo >&2 "Error: no model file $MFILE"
	exit 1
fi

MNAME="$(basename "$MFILE")"
MDIR="$(dirname "$MFILE")"
TNAME="$(basename "$MDIR")"

OUTDIR="./output/cadscores/$TNAME"
mkdir -p "$OUTDIR"

find "$MDIR" -type f \
| sort \
| xargs -L 1 voronota-cadscore --input-filter-query '--rename-chains' --cache-dir "./tmp/$TNAME" -t "$MFILE" -m \
| sed "s|$MDIR/||g" \
> "${OUTDIR}/${MNAME}"
