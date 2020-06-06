#!/bin/bash

for SCORENAME in cadscores lddts
do
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1901
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1902
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1903
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1904
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1905
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1906
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1907
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1908
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1909
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1910
	
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1901d1
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1901d2
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1901d3
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1902d1
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1902d2
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1902d3
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1903d1
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1903d2
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1904d1
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1904d2
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1904d3
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1905d1
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1905d2
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1906d1
	./scripts/calculate_consensus_scores_for_target.bash "$SCORENAME" all C1906d2
	
	./scripts/summarize_notable_models.bash "$SCORENAME" domain
	./scripts/summarize_notable_models.bash "$SCORENAME" full
done

