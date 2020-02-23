
# Cross compiling example
#> SIZE_FLAGS="-DVM_16BIT" CROSS_CFLAGS="-DNO_FILE -mmcu=avrxmega7 -Wl,--defsym=__heap_end=0" CROSS_CC=avr-gcc make cross-forth

#SIZE_FLAGS?=-DVM_16BIT
ENDIAN_FLAGS?=-be

CFLAGS=-Wall -Wpedantic -Werror -Os $(SIZE_FLAGS)

default: forth

clean:
	rm -f cross-forth forth toC bootstrap kernel.img kernel.img.c *.o

cross-forth: runner.c kernel.img.c common-target.o machine-target.o io-target.o io_file-target.o io_platform-target.o
	$(CROSS_CC) $(CFLAGS) $(CROSS_CFLAGS) -o $@ $^

forth: runner.c kernel.img.c common.o machine.o io.o io_file.o io_platform.o
	$(CC) $(CFLAGS) -o $@ $^

common-target.o: common.c common.h
	$(CROSS_CC) $(CFLAGS) $(CROSS_CFLAGS) -c -o $@ common.c

io-target.o: common.h io.h io.c
	$(CROSS_CC) $(CFLAGS) $(CROSS_CFLAGS) -c -o $@ io.c

io_platform-target.o: common.h io.h io_platform.h io_platform.c
	$(CROSS_CC) $(CFLAGS) $(CROSS_CFLAGS) -c -o $@ io_platform.c

io_file-target.o: common.h io.h io_file.h io_file.c
	$(CROSS_CC) $(CFLAGS) $(CROSS_CFLAGS) -c -o $@ io_file.c

machine-target.o: common.h io.h io_file.h io_platform.h opcode.h machine.h machine.c
	$(CROSS_CC) $(CFLAGS) $(CROSS_CFLAGS) -c -o $@ machine.c

common.o: common.c common.h
	$(CC) $(CFLAGS) -c -o $@ common.c

io.o: common.h io.h io.c
	$(CC) $(CFLAGS) -c -o $@ io.c

io_platform.o: common.h io.h io_platform.h io_platform.c
	$(CC) $(CFLAGS) -c -o $@ io_platform.c

io_file.o: common.h io.h io_file.h io_file.c
	$(CC) $(CFLAGS) -c -o $@ io_file.c

machine.o: common.h io.h io_file.h opcode.h io_platform.h machine.h machine.c
	$(CC) $(CFLAGS) -c -o $@ machine.c

kernel.img.c: kernel.img toC
	cat kernel.img | ./toC > $@

toC: toC.c
	$(CC) $(CFLAGS) -o $@ $^
	
kernel.img: bootstrap core.fth
	./bootstrap $(ENDIAN_FLAGS) -f core.fth -p "get-order internals swap 1+ set-order ' bye ' save only definitions execute kernel.img execute"

bootstrap: bootstrap.c common.o machine.o io.o io_file.o io_platform.o
	$(CC) $(CFLAGS) -o $@ $^

