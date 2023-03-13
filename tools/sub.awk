#!/bin/awk
fname != FILENAME {
	fname = FILENAME
	idx++
}

BEGIN {
	FS=""
}

# ${MOD_RES_PROMT}
idx == 1 {
	promt_str[FNR] = $0
}

# ${TARGET}
idx == 2 {
	FS="\": \""
	sub(".*", FS promt_str[FNR] "\"", $2)
	print $1 $2
}
