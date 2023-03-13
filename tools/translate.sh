#!/bin/sh

# Input
src="$1"
# Output
res="promt_$1"

# Source vals
src_vals="src_vals.txt"

promted_vals="promt_${src_vals}"

main() {
set -x
set -e

## Switch to LF just in case
if [ "$(command -v dos2unix)" ] ; then
	dos2unix "${src}"
else
	echo 1>&2 "[W] dos2unix not found. You may want to convert ${orig} from CRLF to LF"
fi


### fix-yaml
# Fix some yaml syntax issues (thx WG):
# 1. Non-consistent amount of spaces after colon between key and value
# 2. Value absence ("key": )
# 3. Empty values ("key": "   ")
sed -E -i '
	s/: *(".*")?$/: \1/g;
	s/: *$/: "YAML_NO_VAL"/g;
	s/: " *"$/: "YAML_EMPTY_VAL"/g
' "${src}"

### filter-val
# We want to work with values only from here
grep -Po '(?<=: ").*(?=")' "${src}" > "${src_vals}"

### distinct-tags
# Let "tags" be the following constructs:
# %(...) <...>
pat_tag="\(\(%(\|<\)[^)>]*."
# , or \n \t \u#### \x##
pat_tag="${pat_tag}"'\|\\\([nt\"]\|u....\|x..\)'
# , or printf-like %ls, %d, %s etc
pat_tag="${pat_tag}\|%\([A-Za-z]\|ls\)\)"


# We certainly don't want to let the translate engine corrupt our "tags".
# Make "tags" literally distinctive from the rest of text at both sides.
# See 
# NOTE: it must be guaranteed that '@' and '^' are never used in the file.
if [ "$(grep -o "[@^]" "${src_vals}")" ] ; then
	echo 1>&2 "[E] '@' or '^' symbols are used in the source file"
	return 1
fi

sed -i "
	s/${pat_tag}/@\1^/g
" "${src_vals}"

### nuke-chinese
# Chinese characters are ... to awk and it loops forever in result
sed -i '
	s/^[^ -z~{}|«»А-Яа-яё]*$/PROBABLY_CHINESE/gi
' "${src_vals}"

### rescue-tags
# So, there is one awful elephant in the room of translate engines:
# they do not have an ability to explicitly ignore the arbitrary part of text.
# It's possible to achieve somewhat similar to this using
# character combinations which are *unlikely* to be translated.
# But moreover in our case - when we try to translate 10+ times,
# trust me - it's just completely impossible, or tends to be extreme circus trickstery.

# But! The only text which is not translated no matter what - is...
# blank line!
# In addition, translate-shell gives input line by line, therefore
# the count of input lines = the count of output lines.
# Using these facts, we can somehow rescue our tags.

# We will do that by separating tags from non-tags and placing them line by line. Example:
# a@~en^b@~et^@%(aaa)^c ->
# a
# @~en^
# b
# @~et^
# @%(aaa)^
# c

# 1. Surely, we want to join back lines later, so we must have literal indicators
# of actual end of line.
eol_symbol='~'
# NOTE: it must be guaranteed that '$' character is never used in the file.
# 2. Split lines. Here helps the literal distinction of tags!

# Write your translate pipeline.
translate_pipeline='ru en ht pt doi pl uk ja fy it ro ja fi ko pl yo ru'

sed '
	s/$/~/g;
	s/\([^@]\)@/\1\n@/g;
	s/\^\([^\n]\)/\^\n\1/g
' "${src_vals}" > "eol_${src_vals}"

## Make list of eol entry line numbers
grep -n "${eol_symbol}" "eol_${src_vals}" | cut -f1 -d':' > linebreaks.txt
	
# Clear all tags and finally, translate
## TODO: translation is too slow
sed 's/^@.*//g; s/'"${eol_symbol}"'//g' "eol_${src_vals}" | sh translate_pipe.sh ${translate_pipeline} >> tmp.txt


awk -f revive.awk "eol_${src_vals}" tmp.txt | awk -f join.awk linebreaks.txt tmp.txt > "${promted_vals}"

# translate-post-fix
# Translators can transform non-ASCII quotes to ASCII, so we need to fix that
sed -i '
	s/\([^\\]\)\"/ˮ/g
' "${promted_vals}"

# undinstinct-tags
# Now we don't need special characters
sed -i '
	s/[@^]//g;
' "${promted_vals}"

# Put translated values back to the corresponding keys
awk -f "sub.awk" "${promted_vals}" "${src}" > "${res}"

# Syntax check
if [ "$(command -v yamllint)" ] ; then
	yamllint -d '{extends: relaxed, rules: {line-length: {max: 9000}}}' "${res}"
else
	echo 1>&2 "[W] yamllint not found. You may want to check syntax of ${res}"
fi

return 0
}

main