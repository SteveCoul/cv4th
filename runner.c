
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "machine.h"

int main( int argc, char** argv ) {
	machine_t machine;
	int fd;
	uint32_t size;
	uint32_t dstacksize;
	uint32_t rstacksize;
	uint32_t quit;
	uint32_t head;

	fd = open( argv[1], O_RDONLY );
	if (fd <0 ) { printf("failed to open\n"); exit(0); }

	machine_init( &machine );

	machine_set_endian( &machine, ENDIAN_NATIVE );
	if ( read( fd, &head, 4 ) != 4 ) return 1;
	if ( read( fd, &size, 4 ) != 4 ) return 1;
	if ( read( fd, &dstacksize, 4 ) != 4 ) return 1;
	if ( read( fd, &rstacksize, 4 ) != 4 ) return 1;
	if ( read( fd, &quit, 4 ) != 4 ) return 1;

	if ( head != 0x11223344 ) {
		machine_set_endian( &machine, ENDIAN_SWAP );
		size = machine.swap32( size );
		dstacksize = machine.swap32( dstacksize );
		rstacksize = machine.swap32( rstacksize );
		quit = machine.swap32( quit );
	}

	machine.memory = malloc( size );
	machine.datastack = malloc( dstacksize * 4 );
	machine.returnstack = malloc( rstacksize * 4 );

	if ( read( fd, machine.memory, size ) < 0 ) return 2;
	machine_execute( &machine, quit );
	return 0;
}

