#!/bin/bash

TARGETNAME="$1"

if [ -z "$TARGETNAME" ]
then
	echo >&2 "Error: missing target name"
	exit 1
fi

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

SCORENAME="cadscores"

{
echo "model1 model2 score"

cat "./output/${SCORENAME}/all_${SCORENAME}" \
| egrep "^${TARGETNAME}TS"
} \
> "$TMPLDIR/scores"

cd "$TMPLDIR"

R --vanilla > /dev/null << 'EOF'

dt_scores=read.table("scores", header=TRUE, stringsAsFactors=FALSE);

models=sort(union(dt_scores$model1, dt_scores$model2));
model_representatives=c();

for(model in models)
{
	sdt_scores1=dt_scores[which(dt_scores$model1==model),];
	sdt_scores1=sdt_scores1[which(sdt_scores1$score>0.80),];
	sdt_models1=sdt_scores1$model2;
	
	sdt_scores2=dt_scores[which(dt_scores$model2==model),];
	sdt_scores2=sdt_scores2[which(sdt_scores2$score>0.80),];
	sdt_models2=sdt_scores2$model1;
	
	model_representatives=c(model_representatives, sort(intersect(sdt_models1, sdt_models2))[1]);
}

unique_model_representatives=intersect(model_representatives, model_representatives);
write(unique_model_representatives, file="result", ncolumns=1);

big_clusters=c();
for(representative in unique_model_representatives)
{
	synonims=models[which(model_representatives==representative)];
	synonims=setdiff(synonims, unique_model_representatives);
	if(length(synonims)>0)
	{
		big_clusters=c(big_clusters, paste(representative, paste(synonims, collapse=","), sep=" "));
	}
}
if(length(big_clusters)>0)
{
	write(big_clusters, file="result_big_clusters", ncolumns=1);
}

EOF

cd - &> /dev/null

OUTDIR="./output/sets_of_unique_models"

mkdir -p "$OUTDIR"

cat "$TMPLDIR/result" > "${OUTDIR}/${TARGETNAME}.txt"

if [ -s "$TMPLDIR/result_big_clusters" ]
then
	cat "$TMPLDIR/result_big_clusters"
	echo
fi

