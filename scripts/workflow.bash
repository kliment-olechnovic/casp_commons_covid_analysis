#!/bin/bash

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

cat > "$TMPLDIR/targets" << 'EOF'
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

for SCORENAME in cadscores lddts
do
	cat "$TMPLDIR/targets" \
	| xargs -L 1 ./scripts/collect_unique_models_for_target.bash
	
	cat "$TMPLDIR/targets" \
	| xargs -L 1 ./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all
	
	./scripts/summarize_notable_models.bash "$SCORENAME" domain
	./scripts/summarize_notable_models.bash "$SCORENAME" full
done

