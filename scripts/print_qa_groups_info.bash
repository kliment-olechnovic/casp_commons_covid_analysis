#!/bin/bash

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

{
echo "ID name"
cat ./input/qa_groups_names.txt
} > "$TMPLDIR/groups_names"

{
echo "ID redundancy_weight"
cat ./input/qa_groups_sets/all
} > "$TMPLDIR/groups_redundancy"

cd "$TMPLDIR"

R --vanilla > /dev/null << 'EOF'
dt1=read.table("groups_names", header=TRUE, stringsAsFactors=FALSE);
dt2=read.table("groups_redundancy", header=TRUE, stringsAsFactors=FALSE);
dt=merge(dt1, dt2);
dt=dt[order(dt$name),];
dt$redundancy_weight=paste0("1/", round(1/dt$redundancy_weight));
dt$redundancy_weight[which(dt$redundancy_weight=="1/1")]="1";
write.table(dt, file="result", quote=FALSE, row.names=FALSE);
EOF

cat ./result | sed 's/^QA//' | column -t

