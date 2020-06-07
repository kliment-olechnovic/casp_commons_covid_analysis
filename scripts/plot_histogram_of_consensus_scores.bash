#!/bin/bash

SCORENAME="$1"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

find "./output/consensus_${SCORENAME}/" -type f -name 'top*' -not -empty \
| xargs cat \
| egrep '^C' \
> "$TMPLDIR/values"

cd "$TMPLDIR"

R --vanilla > /dev/null << 'EOF'
dt=read.table("values", header=FALSE, stringsAsFactors=FALSE);
png("plot.png", width=800, height=600, units="px");
hist(dt$V2, breaks=seq(0, 1, 0.025), xlab="consensus score", main="histogram of consensus scores");
dev.off();
EOF

cd - &> /dev/null

mv "$TMPLDIR/plot.png" "./output/summaries_of_consensus_${SCORENAME}/histogram.png"

