#!/bin/sh
	make -f scripts/test.mak 2>&1 > test.log && rm -f test.log

