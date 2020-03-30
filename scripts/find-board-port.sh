#!/bin/sh
ARDUINO_CLI=`which arduino-cli`

ARDUINO_PORT=`$ARDUINO_CLI board list | grep $1 | cut -d ' ' -f 1`

if [ "$ARDUINOPORT"x == "x" ]; then
	echo "Didn't find the board, pick a port : " >&2
	let i=0
	SUBLIST=""
	$ARDUINO_CLI board list | grep "^/" > tmp
	while read r 
	do
		SUBLIST[$i]=`echo $r | cut -d ' ' -f 1`
		let i=$i+1
	done < tmp

	let i=0
    while [ $i != ${#SUBLIST[@]} ] ; do
		echo "$i] ${SUBLIST[$i]}" >&2
		let i=$i+1
	done	

	read i

	PORT=${SUBLIST[$i]}

	echo "$PORT" 
fi

