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

dt$max_top_1_to_1=0;
for(i in 1:nrow(dt))
{
	dt$max_top_1_to_1[i]=max(as.numeric(as.vector(dt[i, valnames[1:1]])));
}

dt$max_top_1_to_10=0;
for(i in 1:nrow(dt))
{
	dt$max_top_1_to_10[i]=max(as.numeric(as.vector(dt[i, valnames[1:10]])));
}

dt$mean_top_1_to_5=0;
for(i in 1:nrow(dt))
{
	dt$mean_top_1_to_5[i]=mean(as.numeric(as.vector(dt[i, valnames[1:5]])));
}

sel_max_top_1_to_1=order(0-dt$max_top_1_to_1, 0-dt$max_top_1_to_10)[1];
sel_max_top_1_to_10=order(0-dt$max_top_1_to_10, 0-dt$max_top_1_to_1)[1];
sel_mean_top_1_to_5=order(0-dt$mean_top_1_to_5, 0-dt$max_top_1_to_10)[1];
sel_complete=order(0-dt$all, 0-dt$max_top_1_to_10, 0-dt$max_top_1_to_1)[1];

summary=data.frame(
  target="_TITLE_",
  number_of_models=nrow(dt),
  max_max_top_1_to_1=max(dt$max_top_1_to_1), model_max_max_top_1_to_1=dt$model[sel_max_top_1_to_1],
  max_max_top_1_to_10=max(dt$max_top_1_to_10), model_max_max_top_1_to_10=dt$model[sel_max_top_1_to_10],
  max_mean_top_1_to_5=max(dt$mean_top_1_to_5), model_max_mean_top_1_to_5=dt$model[sel_mean_top_1_to_5],
  max_complete=max(dt$all), model_max_complete=dt$model[sel_complete],
  same_sel=0,
  stringsAsFactors=FALSE);
if(summary$model_max_max_top_1_to_1==summary$model_max_max_top_1_to_10)
{
	summary$same_sel=1;
}
write.table(summary, file="summary.txt", quote=FALSE, row.names=FALSE);

global_ltys=c(1, 2, 3);
global_colors=c("red", "blue", "darkgreen");

legend_sels=c(sel_max_top_1_to_10);
legend_ltys=c(global_ltys[length(legend_sels)]);
legend_labels=c(dt$model[sel_max_top_1_to_10]);
legend_colors=c(global_colors[length(legend_sels)]);
if(sel_max_top_1_to_1!=sel_max_top_1_to_10)
{
	legend_sels=c(legend_sels, sel_max_top_1_to_1);
	legend_ltys=c(legend_ltys, global_ltys[length(legend_sels)]);
	legend_labels=c(legend_labels, dt$model[sel_max_top_1_to_1]);
	legend_colors=c(legend_colors, global_colors[length(legend_sels)]);
}
if(sel_mean_top_1_to_5!=sel_max_top_1_to_10 && sel_mean_top_1_to_5!=sel_max_top_1_to_1)
{
	legend_sels=c(legend_sels, sel_mean_top_1_to_5);
	legend_ltys=c(legend_ltys, global_ltys[length(legend_sels)]);
	legend_labels=c(legend_labels, dt$model[sel_mean_top_1_to_5]);
	legend_colors=c(legend_colors, global_colors[length(legend_sels)]);
}

png("plot.png", width=4, height=4, units="in", res=150);
plot(x=1:M, y=((1:M)/M), ylim=c(0, 1), type="n", xaxt="n", xlab="", ylab="Consensus score", main="_TITLE_");
axis(1, at=1:M, labels=FALSE);
text(x=1:M, y=(par()$usr[3]-0.07*(par()$usr[4]-par()$usr[3])), labels=sub("_", " ", valnames), srt=90, adj=1, xpd=TRUE);
points(c(-1000, 1000), c(0.6, 0.6), type="l");
for(category in c(0, 1:length(legend_sels)))
{
	allowed=TRUE;
	col="gray";
	lwd=1;
	lty=1;
	sdt=dt;
	
	if(category>0)
	{
		lwd=2;
		col=legend_colors[category];
		lty=legend_ltys[category];
		sdt=dt[legend_sels[category],];
	}
	
	for(i in 1:nrow(sdt))
	{
		x=1:M;
		y=as.vector(sdt[i, valnames]);
		sel=which(y>0);
		x=x[sel];
		y=y[sel];
		if(length(y)==1)
		{
			x=c(x-0.2, x);
			y=c(y, y);
		}
		points(x, y, type="l", col=col, lwd=lwd, lty=lty);
	}
}
legend("topright", legend=legend_labels, col=legend_colors, lty=legend_ltys, lwd=3, bty="n", ncol=1);
dev.off();
EOF
} \
| sed "s|_TITLE_|$(basename $INFILE .txt)|g" \
| R --vanilla > /dev/null

cd - &> /dev/null

mv "$TMPLDIR/plot.png" "$OUTFILE"

cat "$TMPLDIR/summary.txt"

