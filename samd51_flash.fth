
0 [if]

#define FLASH_BASE		(1008*1024)
#define FLASH_SIZE		16*1024

static uint32_t			page_size;
static uint32_t*		block_buffer		=	NULL;

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
[then]


ext-wordlist forth-wordlist internals 3 set-order definitions

1 cells 4 = 0= [IF] cr .( Driver assumes 32bit build ) abort [THEN]
S" /FLASH_BASE" environment? 0= [IF]  cr .( /FLASH_BASE not in environment ) abort [THEN] constant FLASH_BASE
S" /FLASH_SIZE" environment? 0= [IF]  cr .( /FLASH_SIZE not in environment ) abort [THEN] constant FLASH_SIZE
S" /FLASH_PAGE_SIZE" environment? 0= [IF]  cr .( /FLASH_PAGE_SIZE not in environment ) abort [THEN] constant FLASH_PAGE_SIZE

\ This chip can only erase 16 pages at a time
FLASH_PAGE_SIZE 16 * buffer: flash_block

: write_page		( flash-address source len -- )	
  cr ." Flash base " FLASH_BASE .
  cr ." Flash Write " over . ." :" dup . ."  -> " 2 pick .
  2drop drop 
;

: flash_write		( flash-address source len -- errorflag )
  begin
    dup FLASH_PAGE_SIZE min >r	( fa s l -- : R: todo -- )
    2 pick 2 pick r@
	write_page
	r@ - rot r@ + rot r> + rot	
	?dup 0=
  until
  2drop 1
;

: flash_read		( dest flash-address len -- errorflag )
  rot >r
  begin
    ?dup
  while
    over s>d d32@ 
	r@ !
	swap cell+ swap
	 r> cell+ >r
	1 cells -
  repeat
  r> drop
  drop
  0
;

only forth definitions

