
#include <Arduino.h>

#include "io_platform.h"

#ifdef __SAMD21G18A__
#define Serial SerialUSB
#endif

int io_platform_read_term( void ) {
	yield();
	int rc;
	if ( Serial.available() >= 1 )
		rc = Serial.read();
	else
		rc = -1;
	if ( rc == 13 ) rc = 10;


	if ( rc == 27 ) {
		if ( Serial.available() < 2 ) delay(250);
		if ( Serial.available() >= 2 ) {
			if ( Serial.peek() == '[' ) {
				rc = ( ( Serial.read() & 255 ) << 8 ) | ( Serial.read() & 255 );
			}
		}
	}

	return rc;
}

void io_platform_write_term( char c ) {
	if ( c == 10 ) { Serial.write(13); }
	Serial.write(c);
}

#ifdef __SAMD51__

#include <unistd.h>

static int dummy_fd = -1;

#define FLASH_BASE		(1008*1024)
#define FLASH_SIZE		16*1024

static uint32_t			page_size;
static uint32_t*		block_buffer		=	NULL;

int io_platform_init( void ) {
	if ( block_buffer == NULL ) {
		page_size = 8 << NVMCTRL->PARAM.bit.PSZ;
		block_buffer = (uint32_t*)malloc( page_size*16 );
	}
	return ( block_buffer == NULL ) ? -1 : 0;
}

void io_platform_term( void ) {
	if ( block_buffer ) free( (void*)block_buffer );
}

int io_platform_block_fd( void ) {
	if ( dummy_fd == -1 ) dummy_fd = 2;
	return dummy_fd;
}

int io_platform_block_count( void ) {
	return (FLASH_SIZE)/1024;
}

ior_t io_platform_read_block( unsigned int number, void* where ) {
	unsigned int addr = FLASH_BASE + ( number * 1024 );
	memcpy( where, (uint8_t*)addr, 1024 );
	return IOR_OK;
}

static void waitDone( void ) {
	while ( NVMCTRL->INTFLAG.bit.DONE == 0 ) 
		;
}

static void waitReady( void ) {
	while ( NVMCTRL->STATUS.bit.READY == 0 )
		;
}

static void clearDone( void ) {
	NVMCTRL->INTFLAG.bit.DONE = 1;
}

static void toAddr( unsigned int addr ) {
	NVMCTRL->ADDR.reg = addr;
}

static void setCommand( unsigned int command ) {
	command |= NVMCTRL_CTRLB_CMDEX_KEY;
	NVMCTRL->CTRLB.reg = command;
}

static void eraseBlock( unsigned int addr ) {
	toAddr( addr );
	waitReady();
	clearDone();
	setCommand( NVMCTRL_CTRLB_CMD_EB_Val );
	waitDone();
}

static void pageWriteMode( void ) {
	NVMCTRL->CTRLA.reg |= 0x30;
}

static void writePage( uint32_t* dst, uint32_t* src ) {
	unsigned int i;
	pageWriteMode();
	waitReady();
	clearDone();
	setCommand( NVMCTRL_CTRLB_CMD_PBC_Val );
	waitDone();
	clearDone();
	for ( i = 0; i < page_size / 4; i++ ) {
		*dst++ = *src++;
	}
	waitDone();
}

static int allbits( uint32_t* ptr, unsigned int count ) {
	while ( count-- )
		if ( ptr[0] != 0xFFFFFFFF ) return 0;
  	return 1;
}

/* TODO - this needs to handle forth blocks crossing NVM block boundaries, atm this isn't an issue */
ior_t io_platform_write_block( unsigned int number, void* what ) {
	unsigned int dest_address = FLASH_BASE + ( number * 1024 );
	unsigned int block = ( dest_address / ( page_size * 16 ) ) * ( page_size * 16 );
	unsigned int block_offset = dest_address % ( page_size * 16 );
	unsigned int page = ( dest_address / page_size ) * page_size;
	unsigned int num_pages = 1024 / page_size;
	unsigned int i;
	uint32_t* src;
	uint32_t* dst;

	/* read block initial content */
	memcpy( block_buffer, (void*)(block), page_size * 16 );

	/* slot in new data */
	src = (uint32_t*)what;
	dst = block_buffer + (block_offset/4);

	if ( memcmp( dst, src, 1024 ) == 0 ) return IOR_OK;			

	if ( allbits( dst, 1024/4 ) == 0 )
		eraseBlock( block );

	memcpy( dst, what, 1024 );

	src = (uint32_t*)block_buffer;
	dst = (uint32_t*)block;
	for ( i = 0; i < 16; i++ ) {
		writePage( dst, src );
		src += (page_size/4);
		dst += (page_size/4);
	}

	return IOR_OK;
}

#else
int io_platform_init( void ) {
	return 0;
}

void io_platform_term( void ) {
}

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

