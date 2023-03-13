#!/bin/sh

# Constants
readonly ENOARG=2

if [ $# -lt 2 ] ; then
	echo 1>&2 "Not enough args"
	exit ${ENOARG}
fi

trans_command="trans -brief -no-warn"

# Constructing and executing a pipeline is A LOT faster than r/w-ing files in a loop
# Arguments are language codes (en, ru, da, etc.)
while [ "$2" ] ; do
	trans_pipeline="${trans_pipeline} ${trans_command} $1:$2 |"
	shift
done
trans_pipeline="${trans_pipeline% |}"

eval "${trans_pipeline}"