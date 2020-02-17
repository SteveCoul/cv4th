
all:	bootstrap runner kernel.img

bootstrap: opcode.h bootstrap.c common.h common.c machine.h io.h io.c io_file.h io_file.c machine.c
	cc -Wall -Wpedantic -Werror -Os -o bootstrap bootstrap.c common.c io.c io_file.c machine.c
	strip bootstrap

runner: opcode.h runner.c common.h common.c machine.h io.h io.c io_file.h io_file.c machine.c
	cc -Wall -Wpedantic -Werror -Os -o runner runner.c common.c io.c io_file.c machine.c
	strip runner

kernel.img: bootstrap core.fth
	./bootstrap core.fth "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel.img execute"

