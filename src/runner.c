
#include <stdlib.h>
#include <string.h>

#include "platform.h"
#include "machine.h"
#include "kernel_image.h"

#define DEBUG 0

static machine_t machine;

#ifdef ARDUINO
void setup() {
#else
int main( int argc, char** argv ) {
#endif

	cell_t* p = (cell_t*)image_data;

	cell_t head			=	p[ A_HEADER / CELL_SIZE ];
	cell_t size			=	p[ A_DICTIONARY_SIZE / CELL_SIZE ];
	cell_t dstacksize	=	p[ A_SIZE_DATASTACK / CELL_SIZE ];
	cell_t rstacksize	=	p[ A_SIZE_RETURNSTACK / CELL_SIZE ];
	
	cell_t setup		=	p[ (A_SETUP / CELL_SIZE) ];
	

	machine_init( &machine );
	machine_set_endian( &machine, ENDIAN_NATIVE, 1 );

	if ( DEBUG ) {
		platform_print_term("Cell size "); 
		platform_printN_term( (int)sizeof(cell_t) );
		platform_print_term(", Header ");
		platform_printHEX_term( head );
		platform_println_term( "" );
	}

	if ( head != HEADER_ID ) {
		machine_set_endian( &machine, ENDIAN_SWAP, 1 );
		size = machine.swapCell( size );
		dstacksize = machine.swapCell( dstacksize );
		rstacksize = machine.swapCell( rstacksize );
		setup = machine.swapCell( setup );
	}

#ifdef XIP
	machine.memory = (cell_t*)image_data;
#else
	machine.memory = (cell_t*)malloc( size );
#endif
	if ( DEBUG ) {
		platform_print_term("Dictionary size "); 
		platform_printN_term( size );
		platform_print_term(" bytes required by image) --> pointer = " );
		platform_printHEX_term( (unsigned long long )(machine.memory) );
		platform_println_term( "" );
	}

	if ( DEBUG ) {
		platform_print_term("SETUP ");
		platform_printHEX_term( setup );
		platform_println_term( "" );
	}

	if ( machine.memory ) {
#ifndef XIP
/*	Appears broken on my samd21 board, don't really need to do it anyhow. Let it lie for a bit
		if ( DEBUG ) platform_println_term( "Erase Dest Area" );
		memset( machine.memory, 0, size );
*/
		if ( DEBUG ) platform_println_term( "Copy data" );
		memmove( machine.memory, image_data, image_data_len );
#endif
		if ( DEBUG ) platform_println_term( "Set Size" );
		WRITE_CELL( &machine, A_DICTIONARY_SIZE, size );
	}

	if ( DEBUG ) platform_println_term( "Get Stacks" );
	machine.datastack = machine.memory + ( GET_CELL( &machine, A_DATASTACK ) / CELL_SIZE );
	machine.returnstack = machine.memory + ( GET_CELL( &machine, A_RETURNSTACK ) / CELL_SIZE );
	if ( DEBUG ) { 	platform_print_term( "Stacks " ); platform_printHEX_term( (uint64_t)machine.datastack );
					platform_print_term( " " ); platform_printHEX_term( (uint64_t)machine.returnstack );
					platform_println_term(""); }

	if ( setup ) {
		machine.IP = setup;
		if ( DEBUG ) platform_println_term( "Run setup" );
		machine_execute( &machine, A_THROW, 0 );
	}

	/* don't read 'quit' until after setup, because setup may change it
	   ( such as for multitasking bootstrap ), also read it from the
	   image not the source (except for XIP of course) */

	if ( DEBUG ) platform_println_term( "boot" );
	
	machine.IP = GET_CELL( &machine, A_QUIT );
	if ( DEBUG ) {
		platform_print_term("QUIT ");
		platform_printHEX_term( machine.IP );
		platform_println_term( "" );
	}
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

