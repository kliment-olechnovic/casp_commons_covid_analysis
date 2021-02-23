#!/bin/bash

QAGROUPSSET="$1"
TARGETNAME="$2"
TOPNUM="$3"

if [ -z "$QAGROUPSSET" ]
then
	echo >&2 "Error: missing QA groups set name"
	exit 1
fi

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

QAGROUPSSETFILE="./input/qa_groups_sets/$QAGROUPSSET"

if [ ! -s "$QAGROUPSSETFILE" ]
then
	echo >&2 "Error: missing QA groups set file '$QAGROUPSSETFILE'"
	exit 1
fi

UNIQUEMODELSFILE="./output/sets_of_unique_models/${TARGETNAME}.txt"

if [ ! -s "$UNIQUEMODELSFILE" ]
then
	echo >&2 "Error: missing unique models set file '$UNIQUEMODELSFILE'"
	exit 1
fi

export LC_ALL=C

{
cat "$QAGROUPSSETFILE" \
| while read QAGROUPID REDUNDANCYCOEF
do
	TABLEFILE="./input/qa_submissions/${TARGETNAME}${QAGROUPID}_2"
	if [ -s "$TABLEFILE" ]
	then
		MCOUNT="$(cat "${TABLEFILE}" | egrep "^${TARGETNAME}" | wc -l)"
		if [ "$MCOUNT" -gt 20 ]
		then
			cat "${TABLEFILE}" \
			| egrep "^${TARGETNAME}" \
			| grep -f "$UNIQUEMODELSFILE" \
			| awk '{print $1 " " (0-$2)}' \
			| sort -n -k2,2 \
			| head -n "$TOPNUM" \
			| sed "s/^/${REDUNDANCYCOEF} /"
		fi
	fi
done
} \
| awk '{print $2 " " $1}' \
| sort

