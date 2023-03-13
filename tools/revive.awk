#!/bin/awk
fname != FILENAME {
	fname = FILENAME;
	idx++
}

BEGIN {
	FS="\n"
}

idx == 1 {
	out[NR] = $0
}

idx == 2 {
	sub(/^$/, out[FNR], $0)
	print $0
}
