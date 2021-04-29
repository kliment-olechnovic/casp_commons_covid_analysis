#!/bin/bash

readonly INFILE1="./output/summaries_of_consensus_cadscores/top_model_selections.txt"
readonly INFILE2="./output/summaries_of_consensus_lddts/top_model_selections.txt"

if [ ! -s "$INFILE1" ] || [ ! -s "$INFILE2" ]
then
	echo >&2 "Error: missing input files"
	exit 1
fi

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

cat "$INFILE1" > "$TMPLDIR/data_cadscore"
cat "$INFILE2" > "$TMPLDIR/data_lddt"

cd "$TMPLDIR"

for SCORENAME in cadscore lddt
do

{
cat << 'EOF'
dt=read.table("data_SCORENAME", header=TRUE, stringsAsFactors=FALSE);
targets=sort(dt$target);
result=c();
for(target in targets)
{
	sdt=dt[which(dt$target==target),];
	
	selected_models=c(sdt$model_max_max_top_1_to_1, sdt$model_max_max_top_1_to_10, sdt$model_max_mean_top_1_to_5);
	selected_models=union(selected_models, selected_models);
	selected_models_str=paste(selected_models, collapse=",");
	
	sresult=data.frame(
	  target=sdt$target,
	  total_number_of_models=sdt$number_of_models,
	  max_consensus_score=sdt$max_max_top_1_to_10,
	  number_of_selected_models=length(selected_models),
	  selected_models=selected_models_str,
	  max_total_consensus_score=sdt$max_complete,
	  stringsAsFactors=FALSE);
	  
	if(length(result)==0) {
		result=sresult;
	} else {
		result=rbind(result, sresult);
	}
}
result$reliability="borderline";
result$reliability[which(result$max_consensus_score>=0.60)]="high";
result$reliability[which(result$max_consensus_score<=0.55)]="low";
write.table(result, file="summary_SCORENAME.txt", quote=FALSE, row.names=FALSE);
EOF
} \
| sed "s/SCORENAME/${SCORENAME}/g" \
| R --vanilla > /dev/null

{
cat << 'EOF'
raw_dt=read.table("summary_SCORENAME.txt", header=TRUE, stringsAsFactors=FALSE);
raw_dt=raw_dt[order(0-raw_dt$max_consensus_score),];
dt=raw_dt[,c("max_total_consensus_score", "max_consensus_score")];
rownames(dt)=raw_dt$target;
dt=t(as.matrix(dt));
png("plot2_SCORENAME.png", width=5, height=8, units="in", res=150);
par(mar=c(5,5,0,1), oma=c(0,0,0,0));
barplot(dt, beside=TRUE, horiz=TRUE, las=1, args.legend=list(x="topright"), xlab="", col=c("gray40", "gray90"));
points(c(0.6, 0.6), c(0, nrow(raw_dt)*3+0.5), type="l", lty=2);
legend(0, -9, legend=c("max. selection-dependent consensus score", "max. simple global consensus score"), bty="n", xpd=TRUE, pt.cex=2, pch=c(22, 22), col=c("black", "black"), pt.bg=c("gray90", "gray40"))
dev.off();
EOF
} \
| sed "s/SCORENAME/${SCORENAME}/g" \
| R --vanilla > /dev/null

done

cd - &> /dev/null

OUTDIR="./output/combined_summary_of_consensus"

mkdir -p "$OUTDIR"

cat "$TMPLDIR/summary_cadscore.txt" | column -t > "$OUTDIR/top_model_selections_cadscore.txt"
cat "$TMPLDIR/summary_lddt.txt" | column -t > "$OUTDIR/top_model_selections_lddt.txt"

mv "$TMPLDIR/plot2_cadscore.png" "$OUTDIR/inmprovement_of_consensus_scores_cadscore.png"
mv "$TMPLDIR/plot2_lddt.png" "$OUTDIR/inmprovement_of_consensus_scores_lddt.png"

