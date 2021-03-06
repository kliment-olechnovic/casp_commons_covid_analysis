#!/bin/bash

SCORENAME="$1"
QAGROUPSSET="$2"
TARGETNAME="$3"

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

CONSENSUSDIR="./output/consensus_${SCORENAME}/${QAGROUPSSET}/${TARGETNAME}"

if [ "$QAGROUPSSET" == "all" ]
then
	CONSENSUSDIR="./output/consensus_${SCORENAME}/${TARGETNAME}"
fi

{
seq 1 10
echo 999
} \
| while read TOPNUM
do
	if [ ! -s "$CONSENSUSDIR/top${TOPNUM}" ]
	then
		scripts/calculate_consensus_scores_for_set_of_models.bash "$SCORENAME" "$QAGROUPSSET" "$TARGETNAME" "$TOPNUM"
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

dt=dt[order(0-dt$cs_top1, 0-dt$cs_top2, 0-dt$cs_top3, 0-dt$cs_top4, 0-dt$cs_top5, 0-dt$cs_top6, 0-dt$cs_top7, 0-dt$cs_top8, 0-dt$cs_top9, 0-dt$cs_top10, 0-dt$cs_top999),];

dt=format(dt, digits=3);

for(i in 2:ncol(dt))
{
	sel_max=which(dt[,i]==max(dt[,i]));
	dt[sel_max, i]=paste0("[", dt[sel_max, i], "]");
}

write.table(dt, file="summary", quote=FALSE, row.names=FALSE);

EOF

cd - &> /dev/null

OUTDIR="./output/summaries_of_consensus_${SCORENAME}/${QAGROUPSSET}"

if [ "$QAGROUPSSET" == "all" ]
then
	OUTDIR="./output/summaries_of_consensus_${SCORENAME}"
fi

mkdir -p "$OUTDIR"

cat "$CONSENSUSDIR/summary" \
| sed 's/ 0.000/ 0/g' \
| sed 's/cs_top999/cs_all/' \
| column -t \
> "${OUTDIR}/${TARGETNAME}.txt"


{
cat << 'EOF'
<html>

<head>

<script src="../support/sorttable.js"></script>

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

<a href='../index.html'>output</a> / <a href='index.html'>summaries_of_consensus__SCORENAME_</a> / _TARGET_

<h2>_TARGET_</h2>

<p>
This table contains consensus scores for models that were ranked highly by QA methods.
</p>

<hr>

<p>
Before the analysis, duplicated models were removed based on the CAD-score threshold of 0.8.
This had a small effect on the final results.
</p>

<hr>

<p>
For each 'cs_topN' column the following computations were performed:
<ul>
<li>
  Top N models were selected using every of _all_ available QA rankings.
</li>
<li>
  All the selected models were bundled together.
  If a model was selected by more than one QA method, it is included multiple times: this way "popular" models gain more weight.
</li>
<li>
  A consensus similarity value (average of all pairwise comparisons)
  was calculated for every model from the bundle.
  Zero values were assigned to models that were not in the bundle.
</li>
</ul>
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
| sed "s|_SCORENAME_|${SCORENAME}|" \
| sed "s|_all_|${QAGROUPSSET}|" \
> "${OUTDIR}/${TARGETNAME}.html"


