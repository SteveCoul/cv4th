
#CFLAGS=-Wall -Wpedantic -Werror -Os

# #############################

ifeq ($(TARGET),host)
# need to stay under 64k for 16 bit builds
DICTIONARY_SIZE=128
FORTH_PLATFORM=platform/nix.fth
HOST_PLATFORM=y
else 
ifeq ($(TARGET),mini)
ARDUINO_PLATFORM?="esp8266:esp8266:d1"
ARDUINO_FLAGS?="-DXIP"
DICTIONARY_SIZE=40
ALIGNMENT_FLAGS=-a
ENDIAN_FLAGS=
PAD_IMAGE=y
FORTH_PLATFORM=platform/esp8266/mini.fth
else 
ifeq ($(TARGET),samd51)
ARDUINO_PLATFORM?="SparkFun:samd:samd51_thing_plus"
ARDUINO_KERNEL_IMAGE=atsamd51j20a_kernel.img.c
DICTIONARY_SIZE=150
ALIGNMENT_FLAGS=-a
ENDIAN_FLAGS=
PAD_IMAGE=n
FORTH_PLATFORM=platform/atsamd51/atsamd51j20a.fth
else 
ifeq ($(TARGET),samd21)
ARDUINO_PLATFORM?="SparkFun:samd:samd21_dev"
ARDUINO_KERNEL_IMAGE=atsamd21g18_kernel.img.c
DICTIONARY_SIZE=24
ALIGNMENT_FLAGS=-a
ENDIAN_FLAGS=
PAD_IMAGE=n
FORTH_PLATFORM=platform/atsamd21/atsamd21g18.fth
else
ifeq ($(TARGET),samd51bare)
DICTIONARY_SIZE=150
FORTH_PLATFORM=platform/atsamd51/atsamd51j20a_bare.fth
BARE_METAL_TARGET=src/platform_samd51.c
GCC_PREFIX=/Users/stevencoul/Library/Arduino15/packages/arduino/tools/arm-none-eabi-gcc/7-2017q4/
CC_GCC=$(GCC_PREFIX)/bin/arm-none-eabi-g++
CC_CFLAGS=$(CFLAGS)
CC_CFLAGS+=-mcpu=cortex-m4 
CC_CFLAGS+=-mthumb 
CC_CFLAGS+=-ffunction-sections -fdata-sections -fno-threadsafe-statics -nostdlib 
CC_CFLAGS+=--param max-inline-insns-single=500 -fno-rtti -fno-exceptions -MMD 
CC_CFLAGS+=-mfloat-abi=hard -mfpu=fpv4-sp-d16 
CC_CFLAGS+=-fpermissive
CC_LFLAGS=
CC_LFLAGS+=-Wl,--gc-sections 
CC_LFLAGS+=-save-temps
CC_LFLAGS+=-Tscripts/samd51j20_flash_16kbootloader.ld
CC_LFLAGS+=--specs=nano.specs --specs=nosys.specs 
CC_LFLAGS+=-mcpu=cortex-m4 
CC_LFLAGS+=-mthumb  
CC_LFLAGS+=-mfloat-abi=hard 
CC_LFLAGS+=-mfpu=fpv4-sp-d16  
CC_LFLAGS+=-Wl,--check-sections
CC_LFLAGS+=-Wl,--gc-sections 
CC_LFLAGS+=-Wl,--unresolved-symbols=report-all 
CC_LFLAGS+=-Wl,--warn-common 
CC_LFLAGS+=-Wl,--warn-section-align  
UPLOAD=~/Library/Arduino15/packages/arduino/tools/bossac/1.8.0-48-gb176eee/bossac -p /dev/cu.usbmodem201 --offset 0x4000 -e -w -v -R 
else
fail-target:
	@echo no TARGET set
endif
endif
endif 
endif
endif

# #############################
ALL_FORTH=platform/*.fth extra/*.fth kernel/*.fth platform/*/*.fth

# #############################

all::

clean:
	rm -f *.log
	rm -rf arduino
	rm -f *.o
	rm -f *.elf
	rm -f *.bin
	rm -f *.s
	rm -f *.ii
	rm -f *.d
	rm -f *.img
	rm -f *.img.c
	rm -f toC
	rm -f bootstrap
	rm -f forth_core
	rm -f forth
	rm -f flashfile
	rm -rf generated

# #############################

all:: generated/opcodes.h generated/opcodes.fth

generated/opcodes.c generated/opcodes.h generated/opcodes.fth: data/opcodes.txt
	mkdir -p generated
	scripts/opcodegen.sh data/opcodes.txt generated/opcodes.h generated/opcodes.fth generated/opcodes.c

# #############################

host_%.o:src/%.c
	$(CC) $(CFLAGS) -Iinc -Igenerated -c -o $@ $^

%.img.c:%.img
	$(MAKE) toC
	rm -f $@
	echo "#include <kernel_image.h>" > $@
ifeq ($(PAD_IMAGE),y)
	./toC $(shell echo $$(($(DICTIONARY_SIZE)*1024))) < $^ >> $@
else
	./toC < $^ >> $@
endif

# #############################

BOOTSTRAP_HEADERS=
BOOTSTRAP_HEADERS+=
BOOTSTRAP_HEADERS+=inc/io.h
BOOTSTRAP_HEADERS+=inc/io_file.h
BOOTSTRAP_HEADERS+=inc/platform.h
BOOTSTRAP_HEADERS+=inc/machine.h
BOOTSTRAP_HEADERS+=generated/opcodes.h
BOOTSTRAP_HEADERS+=inc/common.h

BOOTSTRAP_SOURCES=
BOOTSTRAP_SOURCES+=src/bootstrap.c
BOOTSTRAP_SOURCES+=generated/opcodes.c
BOOTSTRAP_SOURCES+=src/io.c
BOOTSTRAP_SOURCES+=src/io_file.c
BOOTSTRAP_SOURCES+=src/platform.c
BOOTSTRAP_SOURCES+=src/platform_nix.c
BOOTSTRAP_SOURCES+=src/machine.c
BOOTSTRAP_SOURCES+=src/common.c

BOOTSTRAP_OBJECTS=$(BOOTSTRAP_SOURCES:src/%.c=host_%.o)

bootstrap: $(BOOTSTRAP_OBJECTS) $(BOOTSTRAP_HEADERS)
	$(CC) $(CFLAGS) -Iinc -Igenerated -o $@ $(BOOTSTRAP_OBJECTS)

all:: bootstrap

# #############################

core.img: kernel/core.fth bootstrap
	./bootstrap $(ALIGNMENT_FLAGS) $(ENDIAN_FLAGS) -ds $(DICTIONARY_SIZE) -f kernel/core.fth -p "internals ext-wordlist get-order 2 + set-order  ' bye ' save only forth definitions execute core.img execute"

all:: core.img	

core.img.c: core.img

all:: core.img.c

# #############################

toC: src/toC.c
	$(CC) -o $@ $^

all:: toC

# #############################

FORTH_CORE_HEADERS=$(BOOTSTRAP_HEADERS)
FORTH_CORE_SOURCES=src/runner.c
FORTH_CORE_SOURCES+=src/io.c
FORTH_CORE_SOURCES+=src/io_file.c
FORTH_CORE_SOURCES+=src/platform.c
FORTH_CORE_SOURCES+=src/platform_nix.c
FORTH_CORE_SOURCES+=src/machine.c
FORTH_CORE_SOURCES+=src/common.c
FORTH_CORE_OBJECTS=$(FORTH_CORE_SOURCES:src/%.c=host_%.o)

forth_core: $(FORTH_CORE_OBJECTS) core.img.c
	$(CC) -Iinc -Igenerated $(CFLAGS) -o $@ $^

all:: forth_core

# #############################

ifeq ($(FORTH_PLATFORM),)
forth_platform.img: core.img
	cp $^ $@
else 
# I have no nice way of knowing what forth files are used by the platform :-(
forth_platform.img: $(FORTH_PLATFORM) forth_core $(ALL_FORTH)
	rm -f $@
	echo "include $(FORTH_PLATFORM)\next-wordlist get-order 1+ set-order bye" | ./forth_core
endif

all:: forth_platform.img

forth_platform.img.c: forth_platform.img

all:: forth_platform.img.c

# #############################

ifneq ($(ARDUINO_PLATFORM),)

ARDUINO_CLI=$(shell which arduino-cli)
ARDUINO_PORT=$(shell $(ARDUINO_CLI) board list | grep $(ARDUINO_PLATFORM) | cut -d ' ' -f 1)

arduino_build_tree: forth_platform.img.c
	rm -rf arduino
	mkdir arduino
	ln -s ../forth_platform.img.c arduino/kernel.cpp
	ln -s ../inc/kernel_image.h arduino/kernel_image.h
	ln -s ../inc/common.h arduino/common.h
	ln -s ../src/common.c arduino/common.cpp
	ln -s ../inc/machine.h arduino/machine.h
	ln -s ../src/machine.c arduino/machine.cpp
	ln -s ../inc/io.h arduino/io.h
	ln -s ../src/io.c arduino/io.cpp
	ln -s ../inc/io_file.h arduino/io_file.h
	ln -s ../src/io_file.c arduino/io_file.cpp
	ln -s ../inc/platform.h arduino/platform.h
	ln -s ../generated/opcodes.h arduino/opcodes.h
	ln -s ../src/platform_arduino.cpp arduino/platform_arduino.cpp
	ln -s ../src/platform.c arduino/platform.cpp
	echo "all:" >> arduino/Makefile
	echo "\t$(ARDUINO_CLI) compile -v --build-path=\"$$PWD/arduino/build\" -b $(ARDUINO_PLATFORM) --build-properties \"compiler.cpp.extra_flags=$(ARDUINO_FLAGS) -I. \"" >> arduino/Makefile
ifeq ($(NO_UPLOAD),)
	echo "\t$(ARDUINO_CLI) upload -b $(ARDUINO_PLATFORM) -p $(ARDUINO_PORT)" >> arduino/Makefile
endif
	ln -s ../src/runner.c arduino/arduino.ino

all:: arduino_build_tree
	PATH=~/Applications/Arduino.app/$$PATH make -C arduino

endif

# #############################

ifeq ($(HOST_PLATFORM),y)

forth: forth_platform.img.c $(FORTH_CORE_OBJECTS)
	$(CC) -Iinc $(CFLAGS) -o $@ $^

all:: forth

endif

# #############################

ifneq ($(BARE_METAL_TARGET),)

BARE_METAL_HEADERS=$(BOOTSTRAP_HEADERS)
BARE_METAL_SOURCES=src/runner.c
BARE_METAL_SOURCES+=src/io.c
BARE_METAL_SOURCES+=src/io_file.c
BARE_METAL_SOURCES+=$(BARE_METAL_TARGET)
BARE_METAL_SOURCES+=src/platform.c
BARE_METAL_SOURCES+=src/machine.c
BARE_METAL_SOURCES+=src/common.c
BARE_METAL_OBJECTS=$(BARE_METAL_SOURCES:src/%.c=%.o)

%.o:src/%.c
	$(CC_GCC) $(CC_CFLAGS) -Iinc -Igenerated -c -o $@ $^

forth.elf:	$(BARE_METAL_OBJECTS) forth_platform.img.c
	$(CC_GCC) $(CC_LFLAGS) -Iinc -o $@ $(BARE_METAL_OBJECTS) forth_platform.img.c

forth.bin: forth.elf
	$(GCC_PREFIX)/bin/arm-none-eabi-objcopy -O binary $^ $@

all:: forth.bin
ifeq ($(NO_UPLOAD),)
	$(UPLOAD) $^
endif

endif

