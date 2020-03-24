#!/bin/sh

echo "/* machine generated */" > $2
echo "#ifndef __opcode_h__" >> $2
echo "#define __opcode_h__" >> $2
echo "enum {" >> $2

echo "\\ machine generated" > $3
echo "internals set-current" >> $3
echo "hex" >> $3

while read -r line; do 
	if ! [[ $line =~ ^# ]]; then
		if ! [ -z "$line" ]; then
			number=$(echo $line | cut -f 1 -d ' ')
			name=$(echo $line | cut -f 2 -d ' ' )

			echo "\top$name = 0x$number," >> $2
			echo "$number constant op$name" >> $3
		fi
	fi
done < $1

echo "\topENDOFLIST };" >> $2
echo "#endif" >> $2
echo " " >> $2

echo "decimal" >> $3
echo "only forth definitions" >> $3

