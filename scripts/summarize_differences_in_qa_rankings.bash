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
C1901x2
C1902x2
C1903x2
C1904x2
C1905x2
C1906x2
C1908x2
EOF

mkdir -p "./output/differences_in_qa_rankings"

{
echo "Target Number_of_QA_methods Number_of_unique_models_in_top_1 Number_of_unique_models_in_top_3 Mean_Spearman_correlation"
cat "$TMPLDIR/targets" \
| while read TARGET
do
	./scripts/print_top_selected_models_for_target.bash all "$TARGET" 1 1 | awk '{print $1}' > "$TMPLDIR/all_top1"
	cat "$TMPLDIR/all_top1" | sort | uniq > "$TMPLDIR/unique_top1"
	
	./scripts/print_top_selected_models_for_target.bash all "$TARGET" 3 3 | awk '{print $1}' > "$TMPLDIR/all_top3"
	cat "$TMPLDIR/all_top3" | sort | uniq > "$TMPLDIR/unique_top3"
	
	echo "${TARGET}" "$(cat ${TMPLDIR}/all_top1 | wc -l)" \
	  "$(cat ${TMPLDIR}/unique_top1 | wc -l)" "$(cat ${TMPLDIR}/unique_top3 | wc -l)" \
	  "$(./scripts/calculate_correlations_between_qa_scores_for_target.bash $TARGET | tail -1 | awk '{print $4}')"
done
} \
| column -t \
> "./output/differences_in_qa_rankings/summary_of_differences_in_qa_rankings.txt"

