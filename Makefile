
CFLAGS=-Wall -Wpedantic -Werror -Os

all:	bootstrap runner kernel.img

bootstrap: bootstrap.o common.o machine.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^
	strip $@

runner: runner.o common.o machine.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^
	strip $@

kernel.img: bootstrap core.fth
	./bootstrap -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel.img execute"

common.o: common.c common.h
	$(CC) $(CFLAGS) -c -o $@ common.c

io.o: common.h io.h io.c
	$(CC) $(CFLAGS) -c -o $@ io.c

io_file.o: common.h io.h io_file.h io_file.c
	$(CC) $(CFLAGS) -c -o $@ io_file.c

machine.o: common.h io.h io_file.h opcode.h machine.h machine.c
	$(CC) $(CFLAGS) -c -o $@ machine.c

runner.o: machine.h runner.c
	$(CC) $(CFLAGS) -c -o $@ runner.c

bootstrap.o: opcode.h common.h machine.h bootstrap.c
	$(CC) $(CFLAGS) -c -o $@ bootstrap.c
