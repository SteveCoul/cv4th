#!/bin/bash

echo "/* machine generated */" > $2
echo "#ifndef __opcode_h__" >> $2
echo "#define __opcode_h__" >> $2
echo " " >> $2
echo "typedef struct {" >> $2
echo "    int value;" >> $2
echo "    const char* name;" >> $2
echo "} opcode_lookup_t;" >> $2
echo " " >> $2
echo "extern opcode_lookup_t opcode_names[];" >> $2
echo " " >> $2
echo "enum {" >> $2

echo "\\ machine generated" > $3
echo "ext-wordlist get-order 1+ set-order open-namespace core" >> $3
echo "wordlist dup constant wid-opcodes set-current" >> $3
echo "hex" >> $3

echo "/* machine generated */" > $4
echo "#include \"opcodes.h\"" >> $4
echo " " >> $4
echo "opcode_lookup_t opcode_names[] = {" >> $4

while read -r line; do 
	if ! [[ $line =~ ^# ]]; then
		if ! [ -z "$line" ]; then
			number=$(echo $line | cut -f 1 -d ' ')
			name=$(echo $line | cut -f 2 -d ' ' )

			echo "    op$name = 0x$number," >> $2
			echo "$number constant op$name" >> $3
			echo "    { 0x$number, \"op$name\"}," >> $4
		fi
	fi
done < $1

echo "    {-1,\"\"}};" >> $4
echo " " >> $4

echo "    opENDOFLIST };" >> $2
echo " " >> $2
echo "#endif" >> $2
echo " " >> $2

echo "decimal" >> $3
echo "only forth definitions" >> $3

