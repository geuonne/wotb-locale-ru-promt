#!/bin/awk

fname != FILENAME {
	fname = FILENAME;
	idx++;
}

BEGIN {
	linebr_n = 0;
	linebr_k = 0;
}

idx == 1 {
	linebr[linebr_n] = $0;
	linebr_n++;
}


idx == 2 {
	outline = outline $0
}

idx == 2 && FNR % linebr[linebr_k] == 0 {
	sub("~", "", outline);
	print outline;
	outline = "";
	linebr_k++;
}
