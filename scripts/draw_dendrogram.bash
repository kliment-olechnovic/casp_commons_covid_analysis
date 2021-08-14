#!/bin/bash

SCORENAME="$1"
TARGETNAME="$2"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

if [ -z "$TARGETNAME" ]
then
	echo >&2 "Error: missing target name"
	exit 1
fi

TARGETNAME="$(basename $TARGETNAME)"

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

cat "./output/${SCORENAME}/all_${SCORENAME}" | egrep "^${TARGETNAME}TS" > "$TMPLDIR/pair_scores"

cd "$TMPLDIR"

MATRIX_DIM="$(cat ./pair_scores | awk '{print $1}' | uniq | egrep . | wc -l)"

{
cat ./pair_scores | awk '{print $1}' | uniq | egrep . | tr '\n' ' ' | sed 's| $|\n|'
cat ./pair_scores | awk -v matrixdim="$MATRIX_DIM" '{print $3; if(NR%matrixdim==0) {print "_" }}' | tr '\n' ' ' | tr '_' '\n' | sed 's|^ ||' | sed 's| $||'
} > ./matrix_table

{
cat << 'EOF'

dt=read.table("matrix_table", header=TRUE);
dt=1-dt;
dm=as.matrix(dt);
row.names(dm)=colnames(dt);
dm=(dm+t(dm))/2;

pdf("heatmap.pdf", height=22, width=20)
heatmap(dm, margins=c(7, 7), main="__SCORENAME__-based clustering heatmap for TARGETNAME");
dev.off()

dm=as.dist(dm, diag=TRUE);
hc=hclust(dm);

pdf("dendrogram.pdf", height=15, width=25)
plot(hc, main="__SCORENAME__-based clustering dendrogram for TARGETNAME", xlab="");
dev.off()

EOF
} \
| sed "s/SCORENAME/${SCORENAME}/g" | sed 's/__cadscores__/CAD-score/g' | sed 's/__lddts__/LDDT/g' \
| sed "s/TARGETNAME/${TARGETNAME}/g" \
| R --vanilla > /dev/null

cd - &> /dev/null

OUTDIR="./output/summaries_of_consensus_${SCORENAME}/dendrograms"

mkdir -p "$OUTDIR"

mv "$TMPLDIR/heatmap.pdf" "./$OUTDIR/${TARGETNAME}__${SCORENAME}_clustering_heatmap.pdf"
mv "$TMPLDIR/dendrogram.pdf" "./$OUTDIR/${TARGETNAME}__${SCORENAME}_clustering_dendrogram.pdf"
mv "$TMPLDIR/matrix_table" "./$OUTDIR/${TARGETNAME}__${SCORENAME}_similarity_matrix.txt"
