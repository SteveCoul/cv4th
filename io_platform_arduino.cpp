

/*



forth-wordlist internals 2 set-order

\ blocks 1 through 4
decimal
1008 1024 * constant	FLASH_BASE_ABS
1024 16 *	constant	FLASH_SIZE_ABS

hex 
: offset create , does> @ + ;

41004000 constant NVMCTRL 

 0 offset +CTRLA

8000 constant CACHEDIS1_MASK
4000 constant CACHEDIS0_MASK
2000 constant AHBNS1_MASK
1000 constant AHBNS0_MASK
0F00 constant RWS_MASK
00C0 constant PRM_MASK
0030 constant WMODE_MASK
0000 constant WMODE_MAN
0010 constant WMODE_ADW
0020 constant WMODE_AQW
0030 constant WMODE_AP	
0008 constant SUSPEN_MASK
0004 constant AUTOWS_MASK

 4 offset +CTRLB

FF00 constant CMD_EX_MASK
A500 constant CMD_EX
007F constant CMD_MASK
0000 constant CMD_EP			\ erase page
0001 constant CMD_EB			\ erase block
0003 constant CMD_WP			\ write page
0015 constant CMD_PBC

 8 offset +PARAM

80000000 constant SSE_MASK
00070000 constant PSZ_MASK
00000000 constant PSZ_8BYTES
00010000 constant PSZ_16BYTES
00020000 constant PSZ_32BYTES
00030000 constant PSZ_64BYTES
00040000 constant PSZ_128BYTES
00050000 constant PSZ_256BYTES
00060000 constant PSZ_512BYTES
00070000 constant PSZ_1024BYTES
0000FFFF constant NVMP_MASK

10 offset +INTFLAG

0001 constant DONE

12 offset +STATUS

0F00 constant BOOTPROT_MASK
0020 constant BPDIS_MASK
0010 constant AFIRST_MASK
0008 constant SUSP_MASK
0004 constant LOAD_MASK
0002 constant PRM_MASK
0001 constant READY_MASK

14 offset +ADDR

decimal

: ctrla>	NVMCTRL +CTRLA s>d d16@ ;
: >ctrla	NVMCTRL +CTRLA s>d d16! ;

: setWMODE 		ctrla> WMODE_MASK INVERT AND OR >ctrla ;

: manualWriteMode	WMODE_MAN setWMODE ;
: pageWriteMode		WMODE_AP setWMODE ;

: ctrlb>	NVMCTRL +CTRLB s>d d16@ ;
: >ctrlb	NVMCTRL +CTRLB s>d d16! ;

: param>	NVMCTRL +PARAM s>d d32@ ;			\ warning, returns 2 cells on 16bit VM

: pageSize param> PSZ_MASK AND 16 RSHIFT 8 swap LSHIFT ;
: numPages param> NVMP_MASK AND ;

: intflag>	NVMCTRL +INTFLAG s>d d16@ ;
: >intflag	NVMCTRL +INTFLAG s>d d16! ;

: setIntFlag  intflag> DONE OR >intflag ;
: done? intflag> DONE AND 0= 0= ;
: cleardone intflag> DONE or >intflag ;

: status> NVMCTRL +STATUS s>d d16@ ;
: ready? status> READY_MASK AND 0= 0= ;

\ status ready must be 1 when called, intflag done will be 1 on complete
: setCommand CMD_EX or cr ." Set command " dup base @ >r hex . r> base ! >ctrlb ;			

: >addr	\ warning needs 2 cells on 16bit VM
  cr ." Address set to " dup base @ >r hex . r> base !
  NVMCTRL +ADDR s>d d32! 
;			

: waitReady cr ." Waiting for ready" begin ready? until ;

: waitDone
  begin done? until
;

: eraseBlock		\ N --
  pageSize * 16 * flash_base_abs + >addr	
  waitReady
  cleardone
  CMD_EB setCommand
  waitDone
;

: localToAbsCopy	\ src dst N --
  cr ." Copy local data"
  0 ?do
    over @ over s>d d32!
    4 + swap 4 + swap
  loop
  2drop
;

: writePage		\ addr N --
  pageWriteMode
  waitReady
  cleardone
  CMD_PBC setCommand
  waitDone
  cleardone
  pageSize * flash_base_abs + 128 localToAbsCopy
  waitDone
;


decimal

512 buffer: fred

: setall 
  16 0 do
    fred 512 i i 16 * or fill
    fred i writePage
  loop
  
  16 0 do
    fred 512 i i 16 * 128 + or fill
    fred i 16 + writePage
  loop
;

*/


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

#define FLASH_BASE		(1008*1024)
#define FLASH_SIZE		16*1024

ior_t io_platform_read_block( unsigned int number, void* where ) {
	unsigned int addr = FLASH_BASE + ( number * 1024 );

	Serial.print("Read block "); Serial.print(number); Serial.print(" from address 0x"); Serial.println(addr, HEX);

	memcpy( where, (uint8_t*)addr, 1024 );
	return IOR_OK;
}

static void nvmClearDone() {
	NVMCTRL->INTENCLR.reg |= 1;
};

static void nvmDone() {
	while( ( NVMCTRL->INTENCLR.reg & 1 ) == 0 )
		;
};

static void nvmReady() {
	while( ( NVMCTRL->STATUS.reg & NVMCTRL_STATUS_READY ) == 0 )
		;
};

static void nvmErasePage( unsigned int address ) {
	Serial.print("Erase page "); Serial.println(address, HEX );
	nvmReady();
	NVMCTRL->STATUS.reg |= NVMCTRL_STATUS_MASK;
	NVMCTRL->ADDR.reg = address;
	NVMCTRL->CTRLB.reg = 0xA500;
};

static void nvmWriteModePage() {
	NVMCTRL->CTRLA.reg |= 0x30;
}

static void nvmClearPageBuffer() {
	nvmReady();
	nvmClearDone();
	NVMCTRL->STATUS.reg |= NVMCTRL_STATUS_MASK;
    NVMCTRL->CTRLB.reg = 0xA515;
	nvmDone();
}

static void nvmWritePage( unsigned int address ) {
	nvmReady();
	nvmClearDone();
	NVMCTRL->STATUS.reg |= NVMCTRL_STATUS_MASK;
	NVMCTRL->ADDR.reg = address;
	NVMCTRL->CTRLB.reg = 0xA503;
	nvmDone();
}

ior_t io_platform_write_block( unsigned int number, void* what ) {
	unsigned int page = number * 2;
	uint32_t* source = (uint32_t*)what;
	uint32_t* dest = (uint32_t*)FLASH_BASE + ( page * 512/4 );
	int i;

	nvmErasePage( FLASH_BASE + ( page * 512 ) );

	nvmErasePage( FLASH_BASE + ( page * 512 ) + 512 );

	nvmWriteModePage();

	nvmClearPageBuffer();

	Serial.println("Copy data1");
	nvmClearDone();
	for ( i = 0; i < 128; i++ ) dest[i] = source[i];
	nvmDone();

	nvmClearPageBuffer();

	Serial.println("Copy data2");
	nvmClearDone();
	for ( i = 0; i < 128; i++ ) dest[i+128] = source[i+128];
	nvmDone();

	return IOR_OK;
}

int io_platform_block_fd( void ) {
	if ( dummy_fd == -1 ) dummy_fd = 2;
	return dummy_fd;
}

int io_platform_block_count( void ) {
	return 16;
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

