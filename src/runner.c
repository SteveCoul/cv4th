
#include <stdlib.h>
#include <string.h>

#include "platform.h"
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
	cell_t dstacksize	=	p[ A_SIZE_DATASTACK / CELL_SIZE ];
	cell_t rstacksize	=	p[ A_SIZE_RETURNSTACK / CELL_SIZE ];
	
	cell_t setup		=	p[ (A_SETUP / CELL_SIZE) ];
	

	machine_init( &machine );
	machine_set_endian( &machine, ENDIAN_NATIVE, 1 );

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

	if ( machine.memory ) {
#ifndef XIP
/*	Appears broken on my samd21 board, don't really need to do it anyhow. Let it lie for a bit
		memset( machine.memory, 0, size );
*/
		memmove( machine.memory, image_data, image_data_len );
#endif
		WRITE_CELL( &machine, A_DICTIONARY_SIZE, size );
	}

	machine.datastack = machine.memory + ( GET_CELL( &machine, A_DATASTACK ) / CELL_SIZE );
	machine.returnstack = machine.memory + ( GET_CELL( &machine, A_RETURNSTACK ) / CELL_SIZE );

	if ( setup ) {
		machine.IP = setup;
		machine_execute( &machine, A_THROW, 0 );
	}

	/* don't read 'quit' until after setup, because setup may change it
	   ( such as for multitasking bootstrap ), also read it from the
	   image not the source (except for XIP of course) */

	machine.IP = GET_CELL( &machine, A_QUIT );
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

