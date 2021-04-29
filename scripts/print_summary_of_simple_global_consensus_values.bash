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

cd "$TMPLDIR"

{
cat << 'EOF'
dt=read.table("values", header=FALSE, stringsAsFactors=FALSE);
nrow(dt);
quantile(dt$V2, p=seq(0.95, 1, 0.01));
length(which(dt$V2<0.6))/nrow(dt);
length(which(dt$V2<0.55))/nrow(dt);
EOF
} \
| R --vanilla

cat "./values" | egrep -v '^C1910' | sponge "./values"

{
cat << 'EOF'
dt=read.table("values", header=FALSE, stringsAsFactors=FALSE);
nrow(dt);
quantile(dt$V2, p=seq(0.95, 1, 0.01));
length(which(dt$V2<0.6))/nrow(dt);
length(which(dt$V2<0.55))/nrow(dt);
EOF
} \
| R --vanilla