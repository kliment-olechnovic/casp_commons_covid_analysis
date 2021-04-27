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

cat "$INFILE1" > "$TMPLDIR/data1"
cat "$INFILE2" > "$TMPLDIR/data2"

cd "$TMPLDIR"

{
cat << 'EOF'
dt1=read.table("data1", header=TRUE, stringsAsFactors=FALSE);
dt2=read.table("data2", header=TRUE, stringsAsFactors=FALSE);
targets=sort(intersect(dt1$target, dt2$target));
result=c();
for(target in targets)
{
	sdt1=dt1[which(dt1$target==target),];
	sdt2=dt2[which(dt2$target==target),];
	
	common_models=sort(intersect(
	  c(sdt1$model_max_max_top_1_to_1, sdt1$model_max_max_top_1_to_10, sdt1$model_max_mean_top_1_to_5),
	  c(sdt2$model_max_max_top_1_to_1, sdt2$model_max_max_top_1_to_10, sdt2$model_max_mean_top_1_to_5)));
	  
	common_models_str=paste(common_models, collapse=",");
	
	sresult=data.frame(
	  target=sdt1$target,
	  total_number_of_models=sdt1$number_of_models,
	  max_consensus_cadscore=sdt1$max_max_top_1_to_10,
	  max_consensus_lddt=sdt2$max_max_top_1_to_10,
	  number_of_selected_models=length(common_models),
	  selected_models=common_models_str,
	  max_total_consensus_cadscore=sdt1$max_complete,
	  max_total_consensus_lddt=sdt2$max_complete,
	  stringsAsFactors=FALSE);
	  
	if(length(result)==0) {
		result=sresult;
	} else {
		result=rbind(result, sresult);
	}
}
result$reliability="borderline";
result$reliability[which(result$max_consensus_cadscore>=0.60 & result$max_consensus_lddt>=0.60)]="high";
result$reliability[which(result$max_consensus_cadscore<=0.55 & result$max_consensus_lddt<=0.55)]="low";
write.table(result, file="summary.txt", quote=FALSE, row.names=FALSE);
EOF
} \
| R --vanilla > /dev/null

{
cat << 'EOF'
raw_dt=read.table("summary.txt", header=TRUE, stringsAsFactors=FALSE);
raw_dt=raw_dt[order(0-raw_dt$max_consensus_cadscore),];
dt=raw_dt[,c("max_consensus_cadscore", "max_consensus_lddt")];
rownames(dt)=raw_dt$target;
dt=t(as.matrix(dt));
png("plot1.png", width=7, height=10, units="in", res=150);
par(mar=c(5,6,1,1));
barplot(dt, beside=TRUE, horiz=TRUE, las=1, legend.text=c("CAD-score", "LDDT"), args.legend=list(x="topright"), xlab="Max. consensus score");
points(c(0.6, 0.6), c(0, nrow(raw_dt)*4+1), type="l");
dev.off();
EOF
} \
| R --vanilla > /dev/null

for SCORENAME in cadscore lddt
do
{
cat << 'EOF'
raw_dt=read.table("summary.txt", header=TRUE, stringsAsFactors=FALSE);
raw_dt$improvement_of_consensus_SCORENAME=(raw_dt$max_consensus_SCORENAME-raw_dt$max_total_consensus_SCORENAME);
raw_dt=raw_dt[order(0-raw_dt$max_consensus_cadscore),];
dt=raw_dt[,c("max_total_consensus_SCORENAME", "improvement_of_consensus_SCORENAME")];
rownames(dt)=raw_dt$target;
dt=t(as.matrix(dt));
png("plot2_SCORENAME.png", width=4, height=10, units="in", res=150);
par(mar=c(5,6,1,1));
barplot(dt, beside=FALSE, horiz=TRUE, las=1, args.legend=list(x="topright"), xlab="Max. consensus score");
points(c(0.6, 0.6), c(0, nrow(raw_dt)*4+1), type="l", lty=2);
dev.off();
EOF
} \
| sed "s/SCORENAME/${SCORENAME}/g" \
| R --vanilla > /dev/null
done

cd - &> /dev/null

OUTDIR="./output/combined_summary_of_consensus"

mkdir -p "$OUTDIR"

cat "$TMPLDIR/summary.txt" | column -t > "$OUTDIR/top_model_selections.txt"

mv "$TMPLDIR/plot1.png" "$OUTDIR/max_consensus_scores.png"
mv "$TMPLDIR/plot2_cadscore.png" "$OUTDIR/inmprovement_of_consensus_scores_cadscore.png"
mv "$TMPLDIR/plot2_lddt.png" "$OUTDIR/inmprovement_of_consensus_scores_lddt.png"

