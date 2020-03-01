
#include <Arduino.h>

#include "io_platform.h"

int io_platform_read_term( void ) {
	yield();
	int rc;
	if ( Serial.available() >= 1 )
		rc = Serial.read();
	else
		rc = -1;
	if ( rc == 13 ) rc = 10;
	return rc;
}

void io_platform_write_term( char c ) {
	if ( c == 10 ) { Serial.write(13); }
	Serial.write(c);
}

int io_platform_init( void ) {
	return 0;
}

void io_platform_term( void ) {
}

#ifdef __SAMD51__

#include <unistd.h>

static int dummy_fd = -1;

#define FLASH_BASE		(1020*1024)
#define FLASH_SIZE		4*1024

ior_t io_platform_read_block( unsigned int number, void* where ) {
	unsigned int addr = FLASH_BASE + ( number * 1024 );

	Serial.print("Read block "); Serial.print(number); Serial.print(" from address 0x"); Serial.println(addr);

	memcpy( where, (uint8_t*)addr, 1024 );
	return IOR_OK;
}

static void nvmReady() {
	while( ( NVMCTRL->STATUS.reg & NVMCTRL_STATUS_READY ) == 0 )
		;
};

static void nvmErasePage( unsigned int address ) {
	Serial.print("Erase page "); Serial.println(address, HEX );
	NVMCTRL->STATUS.reg |= NVMCTRL_STATUS_MASK;
	NVMCTRL->ADDR.reg = address;
	NVMCTRL->CTRLB.reg = 0xA500;
};

static void nvmWriteModePage() {
	NVMCTRL->CTRLA.reg |= 0x30;
}

static void nvmClearPageBuffer() {
	NVMCTRL->STATUS.reg |= NVMCTRL_STATUS_MASK;
    NVMCTRL->CTRLB.reg = 0xA515;
}

static void nvmWritePage( unsigned int address ) {
	NVMCTRL->STATUS.reg |= NVMCTRL_STATUS_MASK;
	NVMCTRL->ADDR.reg = address;
	NVMCTRL->CTRLB.reg = 0xA503;
}

ior_t io_platform_write_block( unsigned int number, void* what ) {
	unsigned int page = number * 2;
	uint32_t* source = (uint32_t*)what;
	uint32_t* dest = (uint32_t*)FLASH_BASE + ( page * 512/4 );
	int i;

	nvmReady();
	nvmErasePage( FLASH_BASE + ( page * 512 ) );
	nvmReady();

	nvmReady();
	nvmErasePage( FLASH_BASE + ( page * 512 ) + 512 );
	nvmReady();

	nvmWriteModePage();
	nvmReady();

	nvmClearPageBuffer();
	nvmReady();

	Serial.println("Copy data1");
	for ( i = 0; i < 128; i++ ) dest[i] = source[i];

	nvmWritePage( FLASH_BASE + ( page * 512 ) );
	nvmReady();

	nvmClearPageBuffer();
	nvmReady();

	Serial.println("Copy data2");
	for ( i = 0; i < 128; i++ ) dest[i+128] = source[i+128];

	nvmWritePage( FLASH_BASE + ( page * 512 ) + 512 );
	nvmReady();

	return IOR_OK;
}

int io_platform_block_fd( void ) {
	if ( dummy_fd == -1 ) dummy_fd = 2;
	return dummy_fd;
}

int io_platform_block_count( void ) {
	return 4;
}
#else
ior_t io_platform_read_block( unsigned int number, void* where ) {
	return IOR_UNKNOWN;
}

ior_t io_platform_write_block( unsigned int number, void* what ) {
	return IOR_UNKNOWN;
}

int io_platform_block_fd( void ) {
	return -1;
}

int io_platform_block_count( void ) {
	return 4;
}
#endif

