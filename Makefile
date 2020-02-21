
SIZE_FLAGS?=-DVM_16BIT
ENDIAN_FLAGS?=-be

CFLAGS=-Wall -Wpedantic -Werror -Os $(SIZE_FLAGS)

default: forth

clean:
	rm -f forth toC bootstrap kernel.img kernel.img.c *.o

forth: runner.c kernel.img.c common.o machine.o io.o io_file.o 
	$(CC) $(CFLAGS) -o $@ $^

common.o: common.c common.h
	$(CC) $(CFLAGS) -c -o $@ common.c

io.o: common.h io.h io.c
	$(CC) $(CFLAGS) -c -o $@ io.c

io_file.o: common.h io.h io_file.h io_file.c
	$(CC) $(CFLAGS) -c -o $@ io_file.c

machine.o: common.h io.h io_file.h opcode.h machine.h machine.c
	$(CC) $(CFLAGS) -c -o $@ machine.c

kernel.img.c: kernel.img toC
	cat kernel.img | ./toC > $@

toC: toC.c
	$(CC) $(CFLAGS) -o $@ $^
	
kernel.img: bootstrap core.fth
	./bootstrap $(ENDIAN_FLAGS) -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel.img execute"

bootstrap: bootstrap.c common.o machine.o io.o io_file.o
	$(CC) $(CFLAGS) -o $@ $^

