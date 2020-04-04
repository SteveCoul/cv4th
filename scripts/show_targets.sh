#!/bin/sh
for file in `find ./platform -name "*.target"`; do
	read header < $file;
	NAME=`echo $header | cut -d ' ' -f 2`
	DESC=`echo $header | cut -d ' ' -f 3-`
	printf "\t% 16s\t%s\n" $NAME "$DESC"
done

