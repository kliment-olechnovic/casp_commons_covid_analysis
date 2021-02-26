#!/bin/bash

SCORENAME="$1"

if [ -z "$SCORENAME" ]
then
	echo >&2 "Error: missing score name"
	exit 1
fi

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
	./scripts/plot_gradual_consensus.bash \
	  "./output/summaries_of_consensus_${SCORENAME}/${TARGETNAME}.txt" \
	  "./output/summaries_of_consensus_${SCORENAME}/${TARGETNAME}_scores.png"
	
	echo "<a href='${TARGETNAME}_scores.png'><img src='${TARGETNAME}_scores.png' width='300'></a>"
done

cat << 'EOF'
</body>
</html>
EOF
} \
> "./output/summaries_of_consensus_${SCORENAME}/plots.html"

