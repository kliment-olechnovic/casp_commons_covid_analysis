#!/bin/bash

OUTDIR="./output/figures_and_tables_for_paper"

mkdir -p "$OUTDIR"

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

export LC_ALL=C

################################################################################

montage \
  "./output/summaries_of_consensus_cadscores/histogram.png" \
  "./output/summaries_of_consensus_lddts/histogram.png" \
  -tile 2x1 \
  -geometry +0+0 \
  "$OUTDIR/figure_histograms_of_consensus_scores.png"

montage \
  "./output/summaries_of_consensus_cadscores/C1901_scores.png" \
  "./output/summaries_of_consensus_cadscores/C1904_scores.png" \
  -tile 2x1 \
  -geometry +0+0 \
  "$OUTDIR/figure_examples_of_gradual_consensus.png"

montage \
  $(find ./output/summaries_of_consensus_cadscores/ -type f -name '*_scores.png' | tr '_' ' ' | sort | tr ' ' '_') \
  -tile 5x \
  -geometry +0+0 \
  "$OUTDIR/figure_all_gradual_consensus_plots_for_cadscores.png"

montage \
  $(find ./output/summaries_of_consensus_lddts/ -type f -name '*_scores.png' | tr '_' ' ' | sort | tr ' ' '_') \
  -tile 5x \
  -geometry +0+0 \
  "$OUTDIR/figure_all_gradual_consensus_plots_for_lddts.png"

################################################################################

{
cat << 'EOF'
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
  text-align: left;    
}
</style>
</head>
<body>
<table>
<tr>
<th>Names</th>
<th>Impact coefficients</th>
</tr>
EOF

cat "./output/qa_groups_info.txt" \
| tail -n +2 \
| awk '{print $2 " " $3}' \
> "$TMPLDIR/qa_groups_info"

{
prev_f_names=""
prev_f_redundancies=""
prev_f_redundancy=""
while read -r f_name f_redundancy
do
	if [ "$f_redundancy" == "1" ]
	then
		if [ -n "$prev_f_names" ]
		then
			echo "$prev_f_names $prev_f_redundancies"
			prev_f_names=""
			prev_f_redundancies=""
			prev_f_redundancy=""
		fi
		echo "$f_name $f_redundancy"
	else
		if [ -z "$prev_f_names" ]
		then
			prev_f_names="$f_name"
			prev_f_redundancies="$f_redundancy"
			prev_f_redundancy="$f_redundancy"
		else
			if [ "$f_redundancy" != "$prev_f_redundancy" ]
			then
				echo "$prev_f_names $prev_f_redundancies"
				prev_f_names="$f_name"
				prev_f_redundancies="$f_redundancy"
				prev_f_redundancy="$f_redundancy"
			else
				prev_f_names="${prev_f_names},${f_name}"
				prev_f_redundancies="${prev_f_redundancies},${f_redundancy}"
			fi
		fi
	fi
done < "$TMPLDIR/qa_groups_info"
if [ -n "$prev_f_names" ]
then
	echo "$prev_f_names $prev_f_redundancies"
fi
} \
> "$TMPLDIR/qa_groups_info_grouped"

while read -r f_name f_redundancy
do
	{
	echo "<tr>"
	echo "<td>$(echo ${f_name} | sed 's|,|, |g')</td>"
	echo "<td>$(echo ${f_redundancy} | sed 's|,|, |g')</td>"
	echo "</tr>"
	} \
	| tr '\n' ' '
	echo
done < "$TMPLDIR/qa_groups_info_grouped"

cat << 'EOF'
</table>
</body>
</html>
EOF
} \
> "$OUTDIR/table_qa_groups.html"

################################################################################

{
cat << 'EOF'
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
  text-align: left;    
}
</style>
</head>
<body>
<table>
<tr>
<th rowspan="2">Target</th>
<th rowspan="2">Unique models</th>
<th colspan="2">Max. consensus</th>
<th rowspan="2">Selected models</th>
<th rowspan="2">Level of agreement of QA rankings</th>
</tr>
<tr>
<th>CAD-score</th>
<th>lDDT</th>
</tr>
EOF

cat "./output/combined_summary_of_consensus/top_model_selections.txt" \
| tail -n +2 \
| awk '{print $1 " " $2 " " $3 " " $4 " " $6 " " $9}' \
| while read -r f_target f_models f_max_cadscore f_max_lddt f_selection f_reliability
do
	{
	echo "<tr>"
	echo "<td>${f_target}</td>"
	echo "<td>${f_models}</td>"
	echo "<td>${f_max_cadscore}</td>"
	echo "<td>${f_max_lddt}</td>"
	echo "<td>$(echo ${f_selection} | sed "s/${f_target}TS//g" | sed 's/,/, /g')</td>"
	echo "<td>${f_reliability}</td>"
	echo "</tr>"
	} \
	| sed 's|<td>high</td>|<td style="background-color:#55ff55;">High</td>|' \
	| sed 's|<td>borderline</td>|<td style="background-color:#ffff55;">Borderline</td>|' \
	| sed 's|<td>low</td>|<td style="background-color:#ff5555;">Low</td>|' \
	| tr '\n' ' '
	echo
done

cat << 'EOF'
</table>
</body>
</html>
EOF
} \
> "$OUTDIR/table_top_model_selections.html"

################################################################################

{
cat << 'EOF'
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
  text-align: left;    
}
</style>
</head>
<body>
<table>
<tr>
<th>Target</th>
<th>Cluster representative</th>
<th>Other cluster members</th>
</tr>
EOF

cat "./output/sets_of_unique_models/all_big_clusters" \
| egrep '.' \
| sed 's/^\(\S\+\)TS/\1 \1TS/' \
| sort \
> "$TMPLDIR/all_big_clusters"

current_f_target=""
while read -r f_target f_rep f_others
do
	f_target_display=""
	if [ "$f_target" != "$current_f_target" ]
	then
		current_f_target="$f_target"
		f_target_display="$f_target"
	fi
	{
	echo "<tr>"
	echo "<td>${f_target_display}</td>"
	echo "<td>${f_rep}</td>"
	echo "<td>$(echo ${f_others} | sed 's/,/, /g')</td>"
	echo "</tr>"
	} \
	| tr '\n' ' '
	echo
done < "$TMPLDIR/all_big_clusters"

cat << 'EOF'
</table>
</body>
</html>
EOF
} \
> "$OUTDIR/table_model_cluster_representatives.html"

################################################################################

{
cat << 'EOF'
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
  text-align: left;    
}
</style>
</head>
<body>
<table>
<tr>
<th>Target</th>
<th>Number of QA methods that provided scores</th>
<th>Number of unique models in top 1</th>
<th>Number of unique models in top 3</th>
<th>Average Spearman correlation coef. between QA scores</th>
</tr>
EOF

cat "./output/differences_in_qa_rankings/summary_of_differences_in_qa_rankings.txt" \
| tail -n +2 \
| while read -r f_target f_n_qa f_n_top1 f_n_top3 f_cor
do
	{
	echo "<tr>"
	echo "<td>${f_target}</td>"
	echo "<td>${f_n_qa}</td>"
	echo "<td>${f_n_top1}</td>"
	echo "<td>${f_n_top3}</td>"
	echo "<td>$(echo "${f_cor}" | awk '{printf "%.2f", $1}')</td>"
	echo "</tr>"
	} \
	| tr '\n' ' '
	echo
done

cat << 'EOF'
</table>
</body>
</html>
EOF
} \
> "$OUTDIR/table_summary_of_differences_in_qa_rankings.html"

################################################################################

{
cat << 'EOF'
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
  text-align: left;    
}
</style>
</head>
<body>
<table>
<tr>
<th>Target</th>
<th>Number of QA methods that provided scores</th>
<th>Number of unique models in top 1</th>
<th>Number of unique models in top 3</th>
<th>Average Spearman correlation coef. between QA scores</th>
</tr>
EOF

cat "./output/differences_in_qa_rankings/summary_of_differences_in_reputable_qa_rankings.txt" \
| tail -n +2 \
| while read -r f_target f_n_qa f_n_top1 f_n_top3 f_cor
do
	{
	echo "<tr>"
	echo "<td>${f_target}</td>"
	echo "<td>${f_n_qa}</td>"
	echo "<td>${f_n_top1}</td>"
	echo "<td>${f_n_top3}</td>"
	echo "<td>$(echo "${f_cor}" | awk '{printf "%.2f", $1}')</td>"
	echo "</tr>"
	} \
	| tr '\n' ' '
	echo
done

cat << 'EOF'
</table>
</body>
</html>
EOF
} \
> "$OUTDIR/table_summary_of_differences_in_subset_of_qa_rankings.html"

################################################################################

