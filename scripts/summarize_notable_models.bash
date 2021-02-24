#!/bin/bash

SCORENAME="$1"
RUNMODE="$2"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

if [ -z "$RUNMODE" ]
then
	echo >&2 "Error: missing run mode parameter"
	exit 1
fi

if [ "$RUNMODE" != "domain" ] && [ "$RUNMODE" != "full" ] && [ "$RUNMODE" != "full_x2" ]
then
	echo >&2 "Error: invalid run mode parameter"
	exit 1
fi

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

<a href='../index.html'>output</a> / <a href='index.html'>summaries_of_consensus__SCORENAME_</a> / notable_models_for__RUNMODE__targets

<h1>Notable models for _RUNMODE_ targets</h1>

<p>
Below are notable models for each of the analyzed _RUNMODE_ targets.
</p>

<p>
Each table row is extracted from the corresponding full QA-top-consensus table.
</p>

<p>
Links to full QA-top-consensus tables can be found <a href='index.html'>here</a>.
</p>

<p>
A model is called notable if it has the highest value in at least one of the columns of the corresponding QA-top-consensus table.
</p>



EOF

./scripts/list_targets.bash "$RUNMODE" \
| while read TARGETNAME
do
	echo '<hr>'
	echo "<h2>${TARGETNAME}</h2>"
	
	echo '<table class="sortable">'
	
	cat "./output/summaries_of_consensus_${SCORENAME}/${TARGETNAME}.txt" \
	| head -1 \
	| sed 's|^|<tr> |' \
	| sed 's|$| </tr>|' \
	| sed 's| \(\S\+\) | <th>\1\</th> |g'
	
	cat "./output/summaries_of_consensus_${SCORENAME}/${TARGETNAME}.txt" \
	| tail -n +2 \
	| grep "\[" \
	| sed 's|^|<tr> |' \
	| sed 's|$| </tr>|' \
	| sed "s| \(${TARGETNAME}\S\+\) | <a,href='https://predictioncenter.org/caspcommons/MODELS/${TARGETNAME}/\1'>\1</a> |" \
	| sed 's| \[\(\S\+\)\] | <mark>\1\</mark> |g' \
	| sed 's| \(\S\+\) | <td>\1\</td> |g' \
	| tr ',' ' '
	
	echo '</table>'
done

cat << 'EOF'
</body>
</html>
EOF
} \
| sed "s|_RUNMODE_|${RUNMODE}|" \
| sed "s|_SCORENAME_|${SCORENAME}|" \
> "./output/summaries_of_consensus_${SCORENAME}/notable_models_for_${RUNMODE}_targets.html"

