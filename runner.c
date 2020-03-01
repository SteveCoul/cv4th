#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "forth.h"
#include "machine.h"
#include "kernel_image.h"

static machine_t machine;
static cell_t	quit;

#ifdef ARDUINO
void setup() {
	Serial.begin(115200);
#else
int main( int argc, char** argv ) {
#endif

	cell_t* p = (cell_t*)image_data;

	cell_t head			=	p[0];
	cell_t size			=	p[1];
	cell_t dstacksize	=	p[2];
	cell_t rstacksize	=	p[3];
	
	quit			=	p[4];

	printf("\nCell size %d, Head %x\n", sizeof(cell_t), head );

	machine_init( &machine );
	machine_set_endian( &machine, ENDIAN_NATIVE );

	if ( head != HEADER_ID ) {
		printf("Non=native endianness\n");
		machine_set_endian( &machine, ENDIAN_SWAP );
		size = machine.swapCELL( size );
		dstacksize = machine.swapCELL( dstacksize );
		rstacksize = machine.swapCELL( rstacksize );
		quit = machine.swapCELL( quit );
	}

	printf("Dictonary size: %d bytes\n", size );
	machine.memory = (cell_t*)malloc( size );
	printf("\tPointer %p", machine.memory );

	printf("Datastack : %d cells\n", dstacksize );
	machine.datastack = (cell_t*)malloc( dstacksize * CELL_SIZE );
	printf("\tPointer %p\n", machine.datastack );

	printf("Returnstack : %d cells\n", rstacksize );
	machine.returnstack = (cell_t*)malloc( rstacksize * CELL_SIZE );
	printf("\tPointer %p\n", machine.returnstack );

	printf("Copy data\n");
	memset( machine.memory, 0, size );
	memmove( machine.memory, image_data+(5*CELL_SIZE), image_data_len-(5*CELL_SIZE) );
	printf("Setup complete\n\n");
#ifdef ARDUINO
}

void loop() {
	if ( ( machine.memory == NULL ) || ( machine.datastack == NULL ) || ( machine.returnstack == NULL ) ) return;
	machine_execute( &machine, quit, A_THROW, 0 );
}
#else
	machine_execute( &machine, quit, A_THROW, 0 );
	return 0;
}
#endif

