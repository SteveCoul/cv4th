
CFLAGS=-Wall -Wpedantic -Werror -Os

# #############################

DICTIONARY_SIZE=64*1024

#ARDUINO_PLATFORM?="esp8266:esp8266:d1"
#ARDUINO_PORT?="/dev/cu.usbserial-20"
#ARDUINO_FLAGS?="-DXIP"
#DICTIONARY_SIZE=24*1024
#ALIGNMENT_FLAGS=-a
#ENDIAN_FLAGS=
#PAD_IMAGE=y
#FORTH_PLATFORM=

ARDUINO_PLATFORM?="SparkFun:samd:samd51_thing_plus"
ARDUINO_PORT?="/dev/cu.usbmodem201" 
ARDUINO_KERNEL_IMAGE=atsamd51j20a_kernel.img.c
DICTIONARY_SIZE=64*1024
ALIGNMENT_FLAGS=-a
ENDIAN_FLAGS=
PAD_IMAGE=n
FORTH_PLATFORM=atsamd51j20a.fth

#ARDUINO_PLATFORM?="SparkFun:samd:samd21_dev"
#ARDUINO_PORT?="/dev/cu.usbmodem201" 
#ARDUINO_KERNEL_IMAGE=atsamd21g18_kernel.img.c
#DICTIONARY_SIZE=24*1024
#ALIGNMENT_FLAGS=-a
#ENDIAN_FLAGS=
#PAD_IMAGE=n
#FORTH_PLATFORM=atsamd21g18.fth

# #############################

all::

clean:
	rm -rf arduino
	rm -f *.o
	rm -f *.img
	rm -f *.img.c
	rm -f toC
	rm -f bootstrap
	rm -f forth_core

# #############################

host_%.o:%.c
	$(CC) $(CFLAGS) -Iinc -DDICTIONARY_SIZE=$(DICTIONARY_SIZE) -c -o $@ $^

%.img.c:%.img
	$(MAKE) toC
	rm -f $@
	echo "#include <kernel_image.h>" > $@
ifeq ($(PAD_IMAGE),y)
	./toC $(shell echo $$(($(DICTIONARY_SIZE)))) < $^ >> $@
else
	./toC < $^ >> $@
endif

# #############################

BOOTSTRAP_HEADERS=
BOOTSTRAP_HEADERS+=
BOOTSTRAP_HEADERS+=inc/io.h
BOOTSTRAP_HEADERS+=inc/io_file.h
BOOTSTRAP_HEADERS+=inc/io_platform.h
BOOTSTRAP_HEADERS+=inc/machine.h
BOOTSTRAP_HEADERS+=inc/opcode.h
BOOTSTRAP_HEADERS+=inc/common.h

BOOTSTRAP_SOURCES=
BOOTSTRAP_SOURCES+=bootstrap.c
BOOTSTRAP_SOURCES+=io.c
BOOTSTRAP_SOURCES+=io_file.c
BOOTSTRAP_SOURCES+=io_platform.c
BOOTSTRAP_SOURCES+=io_platform_nix.c
BOOTSTRAP_SOURCES+=machine.c
BOOTSTRAP_SOURCES+=common.c

BOOTSTRAP_OBJECTS=$(BOOTSTRAP_SOURCES:%.c=host_%.o)

bootstrap: $(BOOTSTRAP_OBJECTS) $(BOOTSTRAP_HEADERS)
	$(CC) $(CFLAGS) -Iinc -o $@ $(BOOTSTRAP_OBJECTS)

all:: bootstrap

# #############################

core.img: kernel/core.fth bootstrap
	./bootstrap $(ALIGNMENT_FLAGS) $(ENDIAN_FLAGS) -f kernel/core.fth -p "internals ext-wordlist get-order 2 + set-order  ' bye ' save only forth definitions execute core.img execute"

all:: core.img	

core.img.c: core.img

all:: core.img.c

# #############################

toC: toC.c
	$(CC) -o $@ $^

all:: toC

# #############################

FORTH_CORE_HEADERS=$(BOOTSTRAP_HEADERES)
FORTH_CORE_SOURCES=runner.c
FORTH_CORE_SOURCES+=io.c
FORTH_CORE_SOURCES+=io_file.c
FORTH_CORE_SOURCES+=io_platform.c
FORTH_CORE_SOURCES+=io_platform_nix.c
FORTH_CORE_SOURCES+=machine.c
FORTH_CORE_SOURCES+=common.c
FORTH_CORE_OBJECTS=$(FORTH_CORE_SOURCES:%.c=host_%.o)

forth_core: $(FORTH_CORE_OBJECTS) core.img.c
	$(CC) -Iinc -DDICTIONARY_SIZE=$(DICTIONARY_SIZE) $(CFLAGS) -o $@ $^

all:: forth_core

# #############################

ifeq ($(FORTH_PLATFORM),)
forth_platform.img: core.img
	cp $^ $@
else 
# I have no nice way of knowing what forth files are used by the platform :-(
forth_platform.img: $(FORTH_PLATFORM) *.fth forth_core
	rm -f $@
	echo "include $(FORTH_PLATFORM)\next-wordlist get-order 1+ set-order bye" | ./forth_core
endif

all:: forth_platform.img

forth_platform.img.c: forth_platform.img

all:: forth_platform.img.c

# #############################

ifneq ($(ARDUINO_PLATFORM),)

arduino_build_tree: forth_platform.img.c
	rm -rf arduino
	mkdir arduino
	ln -s ../forth_platform.img.c arduino/kernel.cpp
	ln -s ../inc/kernel_image.h arduino/kernel_image.h
	ln -s ../inc/common.h arduino/common.h
	ln -s ../common.c arduino/common.cpp
	ln -s ../inc/machine.h arduino/machine.h
	ln -s ../machine.c arduino/machine.cpp
	ln -s ../inc/io.h arduino/io.h
	ln -s ../io.c arduino/io.cpp
	ln -s ../inc/io_file.h arduino/io_file.h
	ln -s ../io_file.c arduino/io_file.cpp
	ln -s ../inc/io_platform.h arduino/io_platform.h
	ln -s ../inc/opcode.h arduino/opcode.h
	ln -s ../io_platform_arduino.cpp arduino/io_platform_arduino.cpp
	ln -s ../io_platform.c arduino/io_platform.cpp
	echo "all:" > arduino/Makefile
	echo "\tarduino-cli compile -v --build-path=\"$$PWD/arduino/build\" -b $(ARDUINO_PLATFORM) --build-properties \"compiler.cpp.extra_flags=$(ARDUINO_FLAGS) -I. -DDICTIONARY_SIZE=$(DICTIONARY_SIZE)\"" >> arduino/Makefile
	echo "\tarduino-cli upload -b $(ARDUINO_PLATFORM) -p $(ARDUINO_PORT)" >> arduino/Makefile
	ln -s ../runner.c arduino/arduino.ino

all:: arduino_build_tree
	make -C arduino

endif

# #############################

