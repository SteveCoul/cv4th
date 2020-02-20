
CFLAGS=-Wall -Wpedantic -Werror -Os 

default:	runner kernel.img

all:	runner32 kernel32be.img kernel32le.img runner16 kernel16be.img kernel16le.img

runner: runner32
	ln -s runner32 runner

bootstrap32: bootstrap32.o common.o machine32.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^
	strip $@

bootstrap16: bootstrap16.o common.o machine16.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^
	strip $@

runner32: runner32.o common.o machine32.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^
	strip $@

runner16: runner16.o common.o machine16.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^
	strip $@

kernel.img: bootstrap32 core.fth
	./bootstrap32 -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel.img execute"

kernel32be.img: bootstrap32 core.fth
	./bootstrap32 -be -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel32be.img execute"

kernel32le.img: bootstrap32 core.fth
	./bootstrap32 -le -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel32le.img execute"

kernel16be.img: bootstrap16 core.fth
	./bootstrap16 -be -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel16be.img execute"

kernel16le.img: bootstrap16 core.fth
	./bootstrap16 -le -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel16le.img execute"

common.o: common.c common.h Makefile
	$(CC) $(CFLAGS) -c -o $@ common.c

io.o: common.h io.h io.c Makefile
	$(CC) $(CFLAGS) -c -o $@ io.c

io_file.o: common.h io.h io_file.h io_file.c Makefile
	$(CC) $(CFLAGS) -c -o $@ io_file.c

machine32.o: common.h io.h io_file.h opcode.h machine.h machine.c Makefile
	$(CC) $(CFLAGS) -c -o $@ machine.c

runner32.o: machine.h runner.c Makefile
	$(CC) $(CFLAGS) -c -o $@ runner.c

bootstrap32.o: opcode.h common.h machine.h bootstrap.c Makefile
	$(CC) $(CFLAGS) -c -o $@ bootstrap.c

machine16.o: common.h io.h io_file.h opcode.h machine.h machine.c Makefile
	$(CC) $(CFLAGS) -DVM_16BIT -c -o $@ machine.c

runner16.o: machine.h runner.c Makefile
	$(CC) $(CFLAGS) -DVM_16BIT -c -o $@ runner.c

bootstrap16.o: opcode.h common.h machine.h bootstrap.c Makefile
	$(CC) $(CFLAGS) -DVM_16BIT -c -o $@ bootstrap.c

