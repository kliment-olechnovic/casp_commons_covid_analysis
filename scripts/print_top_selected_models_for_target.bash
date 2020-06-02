#!/bin/bash

TARGETNAME="$1"
TOPNUM="$2"

if [ -z "$TARGETNAME" ]
then
	echo >&2 "Error: missing target name"
	exit 1
fi

if [ -z "$TOPNUM" ]
then
	echo >&2 "Error: missing top number"
	exit 1
fi

export LC_ALL=C

find ./input/qa_submissions/ -type f -not -empty \
| grep "/${TARGETNAME}QA" \
| while read TABLEFILE
do
	MCOUNT="$(cat "${TABLEFILE}" | egrep "^${TARGETNAME}" | wc -l)"
	if [ "$MCOUNT" -gt 30 ]
	then
		cat "${TABLEFILE}" \
		| egrep "^${TARGETNAME}" \
		| awk '{print $1 " " (0-$2)}' \
		| sort -n -k2,2 \
		| head -n "$TOPNUM"
	fi
done \
| awk '{print $1}' \
| sort


