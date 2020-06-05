#!/bin/bash

RUNMODE="$1"

if [ -z "$RUNMODE" ]
then
	echo >&2 "Error: missing run mode parameter"
	exit 1
fi

if [ "$RUNMODE" != "domain" ] && [ "$RUNMODE" != "full" ]
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

{
if [ "$RUNMODE" == "domain" ]
then
cat << 'EOF'
C1901d1
C1901d2
C1901d3
C1902d1
C1902d2
C1902d3
C1903d1
C1903d2
C1904d1
C1904d2
C1904d3
C1905d1
C1905d2
C1906d1
C1906d2
EOF
else
cat << 'EOF'
C1901
C1902
C1903
C1904
C1905
C1906
C1907
C1908
C1909
C1910
EOF
fi
} \
| while read TARGETNAME
do
	echo '<hr>'
	echo "<h2>${TARGETNAME}</h2>"
	
	echo '<table class="sortable">'
	
	cat "./output/summaries_of_consensus_cadscores/${TARGETNAME}.txt" \
	| head -1 \
	| sed 's|^|<tr> |' \
	| sed 's|$| </tr>|' \
	| sed 's| \(\S\+\) | <th>\1\</th> |g'
	
	cat "./output/summaries_of_consensus_cadscores/${TARGETNAME}.txt" \
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
> "./output/summaries_of_consensus_cadscores/notable_models_for_${RUNMODE}_targets.html"

