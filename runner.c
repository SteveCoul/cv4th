#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "forth.h"
#include "machine.h"

extern const unsigned char image_data[];
extern const unsigned int image_data_len;

int main( int argc, char** argv ) {
	machine_t machine;
	cell_t* p = (cell_t*)image_data;

	cell_t head			=	p[0];
	cell_t size			=	p[1];
	cell_t dstacksize	=	p[2];
	cell_t rstacksize	=	p[3];
	cell_t quit			=	p[4];

	machine_init( &machine );
	machine_set_endian( &machine, ENDIAN_NATIVE );

	if ( head != HEADER_ID ) {
		machine_set_endian( &machine, ENDIAN_SWAP );
		size = machine.swapCELL( size );
		dstacksize = machine.swapCELL( dstacksize );
		rstacksize = machine.swapCELL( rstacksize );
		quit = machine.swapCELL( quit );
	}

	machine.memory = malloc( size );
	machine.datastack = malloc( dstacksize * CELL_SIZE );
	machine.returnstack = malloc( rstacksize * CELL_SIZE );

	memset( machine.memory, 0, size );
	memmove( machine.memory, image_data+(5*CELL_SIZE), image_data_len-(5*CELL_SIZE) );
	machine_execute( &machine, quit, A_THROW, 0 );
	return 0;
}

