#!/bin/bash

RUNMODE="$1"

if [ -z "$RUNMODE" ]
then
	echo >&2 "Error: missing run mode parameter"
	exit 1
fi

if [ "$RUNMODE" != "domain" ] && [ "$RUNMODE" != "full" ] && [ "$RUNMODE" != "full_x2" ]
then
	echo >&2 "Error: invalid run mode parameter"
	exit 1
fi

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
fi

if [ "$RUNMODE" == "full" ]
then
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

if [ "$RUNMODE" == "full_x2" ]
then
cat << 'EOF'
C1901x2
C1902x2
C1903x2
C1904x2
C1905x2
C1906x2
C1908x2
EOF
fi

