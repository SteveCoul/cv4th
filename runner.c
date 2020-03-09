
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "io_platform.h"
#include "machine.h"
#include "kernel_image.h"

static machine_t machine;

#ifdef ARDUINO
void setup() {
#else
int main( int argc, char** argv ) {
#endif

	cell_t* p = (cell_t*)image_data;

	cell_t head			=	p[ A_HEADER / CELL_SIZE ];
	cell_t size			=	p[ A_DICTIONARY_SIZE / CELL_SIZE ];
	cell_t request_size;
	cell_t dstacksize	=	p[ A_SIZE_DATASTACK / CELL_SIZE ];
	cell_t rstacksize	=	p[ A_SIZE_RETURNSTACK / CELL_SIZE ];
	
	cell_t quit			=	p[ (A_QUIT / CELL_SIZE) ];
	cell_t setup		=	p[ (A_SETUP / CELL_SIZE) ];
	

	machine_init( &machine );
	machine_set_endian( &machine, ENDIAN_NATIVE, 1 );

	io_platform_print_term("Cell size "); 
	io_platform_printN_term( (int)sizeof(cell_t) );
	io_platform_print_term(", Header ");
	io_platform_printHEX_term( head );
	io_platform_println_term( "" );

	if ( head != HEADER_ID ) {
		machine_set_endian( &machine, ENDIAN_SWAP, 1 );
		size = machine.swapCell( size );
		dstacksize = machine.swapCell( dstacksize );
		rstacksize = machine.swapCell( rstacksize );
		quit = machine.swapCell( quit );
		setup = machine.swapCell( setup );
	}

#ifdef DICTIONARY_SIZE
	request_size = DICTIONARY_SIZE;
#else
	request_size = size;
#endif

#ifdef XIP
	machine.memory = (cell_t*)image_data;
#else
	machine.memory = (cell_t*)malloc( request_size );
#endif
	io_platform_print_term("Dictionary size "); io_platform_printN_term( request_size );
	io_platform_print_term(" bytes ( "); io_platform_printN_term( size );
	io_platform_print_term(" bytes required by image) --> pointer = " );
	io_platform_printHEX_term( (unsigned long long )(machine.memory) );
	io_platform_println_term( "" );

	machine.datastack = (cell_t*)malloc( dstacksize * CELL_SIZE );
	io_platform_print_term("Data stack ");
	io_platform_printN_term( dstacksize );
	io_platform_print_term( " cells --> pointer = " );
	io_platform_printHEX_term( (unsigned long long)(machine.datastack) );
	io_platform_println_term( "" );

	machine.returnstack = (cell_t*)malloc( rstacksize * CELL_SIZE );
	io_platform_print_term("Return stack ");
	io_platform_printN_term( rstacksize );
	io_platform_print_term( " cells --> pointer = " );
	io_platform_printHEX_term( (unsigned long long)(machine.returnstack) );
	io_platform_println_term( "" );

	io_platform_print_term("SETUP ");
	io_platform_printHEX_term( setup );
	io_platform_println_term( "" );

	io_platform_print_term("QUIT ");
	io_platform_printHEX_term( quit );
	io_platform_println_term( "" );

	io_platform_println_term( "Copy data" );
	if ( machine.memory ) {
#ifndef XIP
		memset( machine.memory, 0, request_size );
		memmove( machine.memory, image_data, image_data_len );
#endif
		WRITE_CELL( &machine, A_DICTIONARY_SIZE, request_size );
	}

	if ( setup ) {
		machine.IP = setup;
		io_platform_println_term( "Run setup" );
//		machine_execute( &machine, A_THROW, 0 );
	}
	io_platform_println_term( "boot" );
	machine.IP = quit;
#ifdef ARDUINO
}

void loop() {
	if ( ( machine.memory == NULL ) || ( machine.datastack == NULL ) || ( machine.returnstack == NULL ) ) return;
	machine_execute( &machine, A_THROW, 5000 );	/* pop out every N instructions */
}
#else
	machine_execute( &machine, A_THROW, -1 );	/* run forever */
	return 0;
}
#endif

