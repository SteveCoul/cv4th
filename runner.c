
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "machine.h"

int main( int argc, char** argv ) {
	machine_t machine;
	int fd;
	cell_t size;
	cell_t dstacksize;
	cell_t rstacksize;
	cell_t quit;
	cell_t head;

	fd = open( argv[1], O_RDONLY );
	if (fd <0 ) { printf("failed to open\n"); exit(0); }

	machine_init( &machine );

	machine_set_endian( &machine, ENDIAN_NATIVE );
	if ( read( fd, &head, CELL_SIZE ) != CELL_SIZE ) return 1;
	if ( read( fd, &size, CELL_SIZE ) != CELL_SIZE ) return 1;
	if ( read( fd, &dstacksize, CELL_SIZE ) != CELL_SIZE ) return 1;
	if ( read( fd, &rstacksize, CELL_SIZE ) != CELL_SIZE ) return 1;
	if ( read( fd, &quit, CELL_SIZE ) != CELL_SIZE ) return 1;

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

	if ( read( fd, machine.memory, size ) < 0 ) return 2;
	machine_execute( &machine, quit );
	return 0;
}

