#!/bin/bash

QAGROUPSSET="$1"
TARGETNAME="$2"

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

CONSENSUSDIR="./output/consensus_cadscores/$QAGROUPSSET/$TARGETNAME"

if [ "$QAGROUPSSET" == "all" ]
then
	CONSENSUSDIR="./output/consensus_cadscores/$TARGETNAME"
fi

{
seq 1 10
seq 15 5 50
} \
| while read TOPNUM
do
	if [ ! -s "$CONSENSUSDIR/top${TOPNUM}" ]
	then
		scripts/calculate_consensus_scores_for_set_of_models.bash "$QAGROUPSSET" "$TARGETNAME" "$TOPNUM"
	fi
done

cd "$CONSENSUSDIR"

export LC_ALL=C

R --vanilla --args $(ls top* | sort -V) > /dev/null << 'EOF'

table_files=commandArgs(TRUE);

dt=c();

for(i in 1:length(table_files))
{
	dt_b=read.table(table_files[i], header=TRUE, stringsAsFactors=FALSE);
	
	if(length(dt)==0) {
		dt=dt_b;
	} else {
		dt=merge(dt, dt_b, all=TRUE);
	}
}

for(i in 2:ncol(dt))
{
	dt[which(!is.finite(dt[,i])), i]=0;
}

dt=dt[order(0-dt$cs_top1, 0-dt$cs_top2, 0-dt$cs_top3, 0-dt$cs_top4, 0-dt$cs_top5, 0-dt$cs_top6, 0-dt$cs_top7, 0-dt$cs_top8, 0-dt$cs_top9, 0-dt$cs_top10, 0-dt$cs_top15, 0-dt$cs_top20, 0-dt$cs_top25, 0-dt$cs_top30, 0-dt$cs_top35, 0-dt$cs_top40, 0-dt$cs_top45, 0-dt$cs_top50),];

dt=format(dt, digits=3);

for(i in 2:ncol(dt))
{
	sel_max=which(dt[,i]==max(dt[,i]));
	dt[sel_max, i]=paste0("[", dt[sel_max, i], "]");
}

write.table(dt, file="summary", quote=FALSE, row.names=FALSE);

EOF

cd - &> /dev/null

OUTDIR="./output/summaries_of_consensus_cadscores/$QAGROUPSSET"

if [ "$QAGROUPSSET" == "all" ]
then
	OUTDIR="./output/summaries_of_consensus_cadscores"
fi

mkdir -p "$OUTDIR"

cat "$CONSENSUSDIR/summary" \
| sed 's/ 0.000/ 0/g' \
| column -t \
> "${OUTDIR}/${TARGETNAME}.txt"


{
cat << 'EOF'
<html>

<head>

<script src="sorttable.js"></script>

<style>

table {
  border-collapse: collapse;
}

table, td, th {
  border: 1px solid black;
  padding: 5px;
  text-align: left;
}

tr:hover {background-color:#ccccff;}

</style>

</head>

<body>

<h2>_TARGET_</h2>

<p>
This table contains consensus scores for models that were ranked highly by QA methods.
</p>

<p>
For each 'cs_topN' column, top N models were selected using every of _all_ available QA rankings,
then all the selected models were bundled together (allowing model repetions if a model was selected by more than one QA method)
and a consensus CAD-score value (average of all pairwise comparisons)
was calculated for each model (zero values were assigned for models than were not selected).
Similar analysis can be done using lDDT and, considering that lDDT and CAD-score correlate well, results should be similar.
</p>

<p>
The table is sorted by 'cs_top1'. Highest column values are highlighted. Table can be resorted by clicking on a column header.
</p>

<table class="sortable">
EOF

cat "${OUTDIR}/${TARGETNAME}.txt" \
| head -1 \
| sed 's|^|<tr> |' \
| sed 's|$| </tr>|' \
| sed 's| \(\S\+\) | <th>\1\</th> |g'

cat "${OUTDIR}/${TARGETNAME}.txt" \
| tail -n +2 \
| sed 's|^|<tr> |' \
| sed 's|$| </tr>|' \
| sed "s| \(${TARGETNAME}\S\+\) | <a,href='https://predictioncenter.org/caspcommons/MODELS/${TARGETNAME}/\1'>\1</a> |" \
| sed 's| \[\(\S\+\)\] | <mark>\1\</mark> |g' \
| sed 's| \(\S\+\) | <td>\1\</td> |g' \
| tr ',' ' '

cat << 'EOF'
</table>
</body>
</html>
EOF
} \
| sed "s|_TARGET_|${TARGETNAME}|" \
| sed "s|_all_|${QAGROUPSSET}|" \
> "${OUTDIR}/${TARGETNAME}.html"


