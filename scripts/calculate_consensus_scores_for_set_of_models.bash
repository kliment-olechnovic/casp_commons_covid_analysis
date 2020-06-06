#!/bin/bash

SCORENAME="$1"
QAGROUPSSET="$2"
TARGETNAME="$3"
TOPNUM="$4"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

if [ -z "$QAGROUPSSET" ]
then
	echo >&2 "Error: missing QA groups set name"
	exit 1
fi

if [ -z "$TARGETNAME" ]
then
	echo >&2 "Error: missing target name"
	exit 1
fi

if [ -z "$TOPNUM" ]
then
	echo >&2 "Error: missing top number"
	exit 1
fi

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

{
echo "model count"

./scripts/print_top_selected_models_for_target.bash "$QAGROUPSSET" "$TARGETNAME" "$TOPNUM" \
| sort \
| uniq -c \
| awk '{print $2 " " $1}'
} \
> "$TMPLDIR/models"

{
echo "model1 model2 score"

cat "./output/${SCORENAME}/all_${SCORENAME}" \
| egrep "^${TARGETNAME}TS"
} \
> "$TMPLDIR/scores"

cd "$TMPLDIR"

R --vanilla > /dev/null << 'EOF'

dt_models=read.table("models", header=TRUE, stringsAsFactors=FALSE);
dt_scores=read.table("scores", header=TRUE, stringsAsFactors=FALSE);

dt_scores=dt_scores[which(is.element(dt_scores$model1, dt_models$model) & is.element(dt_scores$model2, dt_models$model)),];

n_models=nrow(dt_models);
consensus_scores=rep(0, n_models);

for(i in 1:n_models)
{
	model=dt_models$model[i];
	
	sdt_scores1=dt_scores[which(dt_scores$model1==model),];
	sdt_scores1$model=sdt_scores1$model2;
	sdt_scores1=sdt_scores1[,c("model", "score")];
	sdt_scores1=sdt_scores1[order(sdt_scores1$model),];
	
	sdt_scores2=dt_scores[which(dt_scores$model2==model),];
	sdt_scores2$model=sdt_scores2$model1;
	sdt_scores2=sdt_scores2[,c("model", "score")];
	sdt_scores2=sdt_scores2[order(sdt_scores2$model),];
	
	sdt_scores=sdt_scores1;
	sdt_scores$score=(sdt_scores1$score+sdt_scores2$score)/2;
	
	sdt_scores_weighted=merge(sdt_scores, dt_models);
	
	self_sel=which(sdt_scores_weighted$model==model);
	sdt_scores_weighted$count[self_sel]=sdt_scores_weighted$count[self_sel]-1;
	
	consensus_scores[i]=sum(sdt_scores_weighted$score*sdt_scores_weighted$count)/sum(sdt_scores_weighted$count);
}

dt_models$consensus_score=consensus_scores;
dt_models=dt_models[order(0-dt_models$consensus_score),];

write.table(dt_models[,c("model", "consensus_score")], file="result", quote=FALSE, row.names=FALSE);

EOF

cd - &> /dev/null

OUTDIR="./output/consensus_${SCORENAME}/${QAGROUPSSET}/${TARGETNAME}"

if [ "$QAGROUPSSET" == "all" ]
then
	OUTDIR="./output/consensus_${SCORENAME}/$TARGETNAME"
fi

mkdir -p "$OUTDIR"

cat "$TMPLDIR/result" \
| sed "s/consensus_score/cs_top${TOPNUM}/" \
> "$OUTDIR/top${TOPNUM}"

