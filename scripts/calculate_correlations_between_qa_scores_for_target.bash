#!/bin/bash

QAGROUPSSET="$1"
TARGETNAME="$2"
MINCOVERAGE="$3"

if [ -z "$QAGROUPSSET" ]
then
	echo >&2 "Error: missing QA groups set name"
	exit 1
fi

if [ -z "$TARGETNAME" ]
then
	echo >&2 "Error: missing target name"
	exit 1
fi

if [ -z "$MINCOVERAGE" ]
then
	MINCOVERAGE="20"
fi

QAGROUPSSETFILE="./input/qa_groups_sets/$QAGROUPSSET"

if [ ! -s "$QAGROUPSSETFILE" ]
then
	echo >&2 "Error: missing QA groups set file '$QAGROUPSSETFILE'"
	exit 1
fi

UNIQUEMODELSFILE="./output/sets_of_unique_models/${TARGETNAME}.txt"

if [ ! -s "$UNIQUEMODELSFILE" ]
then
	echo >&2 "Error: missing unique models set file '$UNIQUEMODELSFILE'"
	exit 1
fi

export LC_ALL=C

readonly TMPLDIR=$(mktemp -d)
trap "rm -r $TMPLDIR" EXIT

cat "$QAGROUPSSETFILE" \
| while read QAGROUPID REDUNDANCYCOEF
do
	TABLEFILE="./input/qa_submissions/${TARGETNAME}${QAGROUPID}_2"
	if [ -s "$TABLEFILE" ]
	then
		MCOUNT="$(cat "${TABLEFILE}" | egrep "^${TARGETNAME}" | wc -l)"
		if [ "$MCOUNT" -gt "$MINCOVERAGE" ]
		then
			echo "${QAGROUPID}" >> "$TMPLDIR/qa_ids"
			{
				echo "model ${QAGROUPID}"
				cat "${TABLEFILE}" \
				| egrep "^${TARGETNAME}" \
				| grep -f "$UNIQUEMODELSFILE" \
				| awk '{print $1 " " $2}' \
				| sed 's/X$/0/'
			} > "${TMPLDIR}/${QAGROUPID}"
		fi
	fi
done

cd "$TMPLDIR"

{
cat << 'EOF'
qa_ids=read.table("qa_ids", header=FALSE, stringsAsFactors=FALSE)[[1]];
dt_all=c();
for(qa_id in qa_ids)
{
	dt=read.table(qa_id, header=TRUE, stringsAsFactors=FALSE);
	if(length(dt_all)==0) {
		dt_all=dt;
	} else {
		dt_all=merge(dt_all, dt);
	}
}
cor_pearson_values=c();
cor_spearman_values=c();
N=length(qa_ids);
for(i in 1:(N-1))
{
	for(j in (i+1):N)
	{
		a=as.numeric(dt_all[,qa_ids[i]]);
		b=as.numeric(dt_all[,qa_ids[j]]);
		cor_pearson_values=c(cor_pearson_values, cor(a, b, method="pearson"));
		cor_spearman_values=c(cor_spearman_values, cor(a, b, method="spearman"));
	}
}
result=data.frame(target="_TARGET_", mean_cor_pearson=mean(cor_pearson_values), min_cor_pearson=min(cor_pearson_values),
  mean_cor_spearman=mean(cor_spearman_values), min_cor_spearman=min(cor_spearman_values));

write.table(result, file="result.txt", quote=FALSE, row.names=FALSE);
EOF
} \
| sed "s/_TARGET_/${TARGETNAME}/g" \
| R --vanilla > /dev/null

cat result.txt

