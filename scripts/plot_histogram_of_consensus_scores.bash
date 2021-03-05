#!/bin/bash

SCORENAME="$1"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

find "./output/consensus_${SCORENAME}/" -type f -name 'top999' -not -empty \
| xargs cat \
| egrep '^C' \
> "$TMPLDIR/values"

#cat "./output/${SCORENAME}/all_${SCORENAME}" | awk '{if($3<1){print $1 "__" $2 " " $3}}' > "$TMPLDIR/values"

cd "$TMPLDIR"

{
cat << 'EOF'
dt=read.table("values", header=FALSE, stringsAsFactors=FALSE);
png("plot.png", width=5, height=5, units="in", res=150);
hist(dt$V2, breaks=seq(0, 1, 0.02), xlab="Global consensus _SCORENAME_", main="_SCORENAME_");
dev.off();
EOF
} \
| sed "s/_SCORENAME_/__${SCORENAME}__/g" \
| sed 's/__cadscores__/CAD-score/g' \
| sed 's/__lddts__/lDDT/g' \
| R --vanilla > /dev/null

cd - &> /dev/null

mv "$TMPLDIR/plot.png" "./output/summaries_of_consensus_${SCORENAME}/histogram.png"

