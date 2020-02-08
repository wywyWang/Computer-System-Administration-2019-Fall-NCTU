#!/bin/sh
ls -ARl | grep "^[-d]" | sort -k 5 -rn | awk 'BEGIN{file_size=0;file_count=0;dir_count=0} { if ($1 ~ /^-/) {file_size+=$5;file_count++;} } { if ($1 ~ /^d/) {dir_count++;} } { if (file_count<=5 && $1 ~ /^-/) {print file_count ":" $5,$9} } END{print "Dir num: " dir_count,"\nFile num:" file_count,"\nTotal: " file_size}'
