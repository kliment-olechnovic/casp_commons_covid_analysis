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
cat "$INFILE" | head -1 |sed 's/ cs_top/ top_/g' |sed 's/ cs_all/ all/g' | sed 's/$/ notable/'
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
valrange=c(min(c(allvals, 0.2)), max(c(allvals, 0.65)));

dt$auc_top5=0;
for(i in 1:nrow(dt))
{
	dt$auc_top5[i]=sum(as.vector(dt[i, valnames[1:5]]));
}

dt$auc_top10=0;
for(i in 1:nrow(dt))
{
	dt$auc_top10[i]=sum(as.vector(dt[i, valnames[1:10]]));
}

sel_top1=order(0-dt$top_1, 0-dt$auc_top5, 0-dt$auc_top10)[1];
sel_auc_top5=order(0-dt$auc_top5, 0-dt$top_1, 0-dt$auc_top10)[1];
sel_auc_top10=order(0-dt$auc_top10, 0-dt$top_1, 0-dt$auc_top5)[1];
sel_overall=order(0-dt$all, 0-dt$auc_top10)[1];

summary=data.frame(
  target="_TITLE_",
  max_top1=max(dt$top_1), model_max_top1=dt$model[sel_top1],
  max_avg_top5=max(dt$auc_top5)/5, model_max_avg_top5=dt$model[sel_auc_top5],
  max_avg_top10=max(dt$auc_top10)/10, model_max_avg_top10=dt$model[sel_auc_top10],
  max_overall=max(dt$all), model_max_overall=dt$model[sel_overall],
  stringsAsFactors=FALSE);
write.table(summary, file="summary.txt", quote=FALSE, row.names=FALSE);

png("plot.png", width=7, height=4, units="in", res=150);
plot(x=1:M, y=((1:M)/M), ylim=valrange, type="n", xaxt="n", xlab="", ylab="Consensus score", main="_TITLE_");
axis(1, at=1:M, labels=FALSE);
text(x=1:M, y=(par()$usr[3]-0.07*(par()$usr[4]-par()$usr[3])), labels=sub("_", " ", valnames), srt=90, adj=1, xpd=TRUE);
points(c(-1000, 1000), c(0.6, 0.6), type="l");
for(category in c(0, 2, 1))
{
	allowed=TRUE;
	col="gray";
	lwd=1;
	lty=1;
	sdt=dt;
	
	if(category==1)
	{
		col="red";
		lwd=2;
		lty=1;
		sdt=dt[sel_top1,];
	}
	
	if(category==2)
	{
		allowed=(sel_auc_top10!=sel_top1);
		col="blue";
		lwd=2;
		lty=3;
		sdt=dt[sel_auc_top10,];
	}
	
	if(allowed)
	{
		for(i in 1:nrow(sdt))
		{
			x=1:M;
			y=as.vector(sdt[i, valnames]);
			sel=which(y>0);
			x=x[sel];
			y=y[sel];
			points(x, y, type="l", col=col, lwd=lwd, lty=lty);
		}
	}
}
dev.off();
EOF
} \
| sed "s|_TITLE_|$(basename $INFILE .txt)|g" \
| R --vanilla > /dev/null

cd - &> /dev/null

mv "$TMPLDIR/plot.png" "$OUTFILE"

cat "$TMPLDIR/summary.txt"

