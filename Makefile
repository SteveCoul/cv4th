#SIZE_FLAGS?=-DVM_16BIT
ENDIAN_FLAGS?=-a 
DICTIONARY_SIZE?=-DDICTIONARY_SIZE=32*1024

CFLAGS=-Wall -Wpedantic -Werror -Os $(SIZE_FLAGS)
STRIP=strip

default: forth

clean:
	rm -f forth toC bootstrap kernel.img kernel.img.c *.o 

forth: runner.c kernel.img.c common.o machine.o io.o io_file.o io_platform.o 
	$(CC) $(DICTIONARY_SIZE) $(CFLAGS) -o $@ $^
	$(STRIP) $@

common.o: common.c common.h
	$(CC) $(CFLAGS) -c -o $@ common.c

io.o: common.h io.h io.c
	$(CC) $(CFLAGS) -c -o $@ io.c

io_platform.o: common.h io.h io_platform.h io_platform_nix.c
	$(CC) $(CFLAGS) -c -o $@ io_platform_nix.c

io_file.o: common.h io.h io_file.h io_file.c
	$(CC) $(CFLAGS) -c -o $@ io_file.c

machine.o: common.h io.h io_file.h opcode.h io_platform.h machine.h machine.c
	$(CC) $(CFLAGS) -c -o $@ machine.c

kernel.img.c: kernel.img toC
	echo "#include \"kernel_image.h\"" > $@
	cat kernel.img | ./toC >> $@

toC: toC.c
	$(CC) $(CFLAGS) -o $@ $^
	
kernel.img: bootstrap core.fth 
	./bootstrap $(ENDIAN_FLAGS) -f core.fth -p "internals ext-wordlist get-order 2 + set-order trim-dict ' bye ' save only forth definitions execute kernel.img execute"

bootstrap: bootstrap.c common.o machine.o io.o io_file.o io_platform.o
	$(CC) $(CFLAGS) $(DICTIONARY_SIZE) -o $@ $^


#ARDUINO_PLATFORM?="esp8266:esp8266:d1"
#ARDUINO_PORT?="/dev/cu.usbserial-20"

ARDUINO_PLATFORM?="SparkFun:samd:samd51_thing_plus"
ARDUINO_PORT?="/dev/cu.usbmodem201" 
ARDUINO_FLAGS?="-DDICTIONARY_SIZE=64*1024"

#ARDUINO_PLATFORM?="SparkFun:samd:samd21_dev"
#ARDUINO_PORT?="/dev/cu.usbmodem201" 
#ARDUINO_FLAGS?="-DDICTIONARY_SIZE=24*1024"

arduino_build_tree: kernel.img.c
	rm -rf arduino
	mkdir arduino
	ln -s ../kernel.img.c arduino/kernel.cpp
	ln -s ../kernel_image.h arduino/kernel_image.h
	ln -s ../common.h arduino/common.h
	ln -s ../common.c arduino/common.cpp
	ln -s ../machine.h arduino/machine.h
	ln -s ../machine.c arduino/machine.cpp
	ln -s ../io.h arduino/io.h
	ln -s ../io.c arduino/io.cpp
	ln -s ../io_file.h arduino/io_file.h
	ln -s ../io_file.c arduino/io_file.cpp
	ln -s ../io_platform.h arduino/io_platform.h
	ln -s ../opcode.h arduino/opcode.h
	ln -s ../io_platform_arduino.cpp arduino/io_platform_arduino.cpp
	echo "all:" > arduino/Makefile
	echo "\tarduino-cli compile --build-path=\"$$PWD/arduino/build\" -v -b $(ARDUINO_PLATFORM) --build-properties \"compiler.cpp.extra_flags=$(ARDUINO_FLAGS)\"" >> arduino/Makefile
	echo "\tarduino-cli upload -v -b $(ARDUINO_PLATFORM) -p $(ARDUINO_PORT)" >> arduino/Makefile
	ln -s ../runner.c arduino/arduino.ino

arduino: arduino_build_tree
	make -C arduino

