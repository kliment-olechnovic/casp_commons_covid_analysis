#!/bin/bash

INFILE="$1"
OUTFILE="$2"

if [ -z "$INFILE" ] || [ ! -s "$INFILE" ]
then
	echo >&2 "Error: missing input file"
	exit 1
fi

if [ -z "$OUTFILE" ]
then
	echo >&2 "Error: missing output file"
	exit 1
fi

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

cat "$INFILE" > "$TMPLDIR/data"

cd "$TMPLDIR"

{
cat << 'EOF'
raw_dt=read.table("data", header=TRUE, stringsAsFactors=FALSE);
raw_dt=raw_dt[order(0-raw_dt$max_top1),];
dt=raw_dt[,c("max_top1", "max_avg_top10")];
rownames(dt)=raw_dt$target;
dt=t(as.matrix(dt));
png("plot.png", width=7, height=14, units="in", res=150);
par(mar=c(5,6,1,1));
barplot(dt, beside=TRUE, horiz=TRUE, las=1, legend.text=c("max top 1", "max avg. top 1-10"), args.legend=list(x="topright"), xlab="Max. consensus score");
points(c(0.6, 0.6), c(0, nrow(raw_dt)*4+1), type="l");
dev.off();
EOF
} \
| R --vanilla > /dev/null

cd - &> /dev/null

mv "$TMPLDIR/plot.png" "$OUTFILE"

