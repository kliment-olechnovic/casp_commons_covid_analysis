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

{
cat "$INFILE" | head -1 |sed 's/ cs_top/ top_/g' | sed 's/$/ notable/'
cat "$INFILE" | tail -n +2 | grep "\[" | sed 's/$/ 1/'
cat "$INFILE" | tail -n +2 | grep -v "\[" | sed 's/$/ 0/'
} \
| tr -d '[' | tr -d ']' \
> "$TMPLDIR/data"

cd "$TMPLDIR"

{
cat << 'EOF'
dt=read.table("data", header=TRUE, stringsAsFactors=FALSE);
M=length(colnames(dt))-2;
valnames=colnames(dt)[2:(M+1)];
allvals=as.vector(as.matrix(dt[,valnames]));
allvals=allvals[which(allvals>0)];
valrange=c(min(allvals), max(allvals));
png("plot.png", width=7, height=4, units="in", res=200);
plot(x=1:M, y=((1:M)/M), ylim=valrange, type="n", xaxt="n", xlab="", ylab="Consensus score", main="_TITLE_");
axis(1, at=1:M, labels=FALSE);
text(x=1:M, y=(par()$usr[3]-0.07*(par()$usr[4]-par()$usr[3])), labels=sub("_", " ", valnames), srt=90, adj=1, xpd=TRUE);
for(category in c(0, 1))
{
	col="red";
	lwd=2;
	sdt=dt[which(dt$top_1==max(dt$top_1)),];
	if(category==0)
	{
		col="gray";
		lwd=1;
		sdt=dt[which(dt$top_1<max(dt$top_1)),];
	}
	N=nrow(sdt);
	for(i in 1:N)
	{
		x=1:M;
		y=as.vector(sdt[i, valnames]);
		sel=which(y>0);
		x=x[sel];
		y=y[sel];
		points(x, y, type="l", col=col, lwd=lwd);
	}
}
dev.off();
EOF
} \
| sed "s|_TITLE_|$(basename $INFILE .txt)|" \
| R --vanilla

cd - &> /dev/null

mv "$TMPLDIR/plot.png" "$OUTFILE"



