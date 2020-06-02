#!/bin/bash

TDIR="$1"

if [ -z "$TDIR" ] || [ ! -d "$TDIR" ]
then
	echo >&2 "Error: no directory $TDIR"
	exit 1
fi

find "$TDIR" -type f -not -empty \
| sort \
| head -1 \
| xargs -L 1 -P 1 ./scripts/compare_model_with_all_other.bash

find "$TDIR" -type f -not -empty \
| sort \
| tail -n +2 \
| xargs -L 1 -P 12 ./scripts/compare_model_with_all_other.bash

echo "Finished with '$TDIR'"

