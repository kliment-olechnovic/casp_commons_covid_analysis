#!/bin/bash

SCORENAME="$1"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

{
./scripts/list_targets.bash all \
| sort \
| while read TARGETNAME
do
	./scripts/plot_gradual_consensus.bash \
	  "./output/summaries_of_consensus_${SCORENAME}/${TARGETNAME}.txt" \
	  "./output/summaries_of_consensus_${SCORENAME}/${TARGETNAME}_scores.png"
done
} \
| awk '{if(NR==1 || $1!="target"){print $0}}' \
| column -t \
> "./output/summaries_of_consensus_${SCORENAME}/top_model_selections.txt"

./scripts/plot_top_model_selections.bash "./output/summaries_of_consensus_${SCORENAME}/top_model_selections.txt" "./output/summaries_of_consensus_${SCORENAME}/top_model_selections.png"

{
cat << 'EOF'
<html>
<head>
</head>
<body>
EOF

./scripts/list_targets.bash all \
| sort \
| while read TARGETNAME
do
	echo "<a href='${TARGETNAME}_scores.png'><img src='${TARGETNAME}_scores.png' width='300'></a>"
done

echo "<br><a href='top_model_selections.png'><img src='top_model_selections.png' width='300'></a>"

cat << 'EOF'
</body>
</html>
EOF
} \
> "./output/summaries_of_consensus_${SCORENAME}/plots.html"

