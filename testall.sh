#!/bin/sh
	make -f test.mak 2>&1 > test.log && rm -f test.log

