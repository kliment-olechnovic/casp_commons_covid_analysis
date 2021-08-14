#!/bin/bash

#!/bin/bash

SCORENAME="$1"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

./scripts/list_targets.bash all | xargs -L 1 -P 12 ./scripts/draw_dendrogram.bash "$SCORENAME"

{
cat << 'EOF'
<html>

<head>

</head>

<body>

<a href='../../index.html'>output</a> / <a href='../index.html'>summaries_of_consensus__SCORENAME_</a> / dendrograms

<h2>Clustering dendrograms</h2>

EOF

for TARGETGROUP in full full_x2 domain
do
	echo '<ul>'
	./scripts/list_targets.bash "$TARGETGROUP" | while read TARGETNAME
	do
		echo "<li>${TARGETNAME}: "
		echo "<a href='${TARGETNAME}__${SCORENAME}_clustering_dendrogram.pdf'>clustering_dendrogram.pdf</a>, "
		echo "<a href='${TARGETNAME}__${SCORENAME}_clustering_heatmap.pdf'>clustering_heatmap.pdf</a>, "
		echo "<a href='${TARGETNAME}__${SCORENAME}_similarity_matrix.txt'>similarity_matrix.txt</a>."
		echo "</li>"
	done
	echo '</ul>'
	echo
done

cat << 'EOF'
</body>
</html>
EOF
} \
| sed "s|_SCORENAME_|${SCORENAME}|" \
> "./output/summaries_of_consensus_${SCORENAME}/dendrograms/index.html"
