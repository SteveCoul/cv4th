
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

	printf("\nCell size %d, Head %x\n", (int)sizeof(cell_t), head );

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

	printf("Dictonary size: %d bytes ( %d in image)\n", request_size, size );
	machine.memory = (cell_t*)malloc( request_size );
	printf("\tPointer %p\n", machine.memory );

	printf("Datastack : %d cells\n", dstacksize );
	machine.datastack = (cell_t*)malloc( dstacksize * CELL_SIZE );
	printf("\tPointer %p\n", (void*)(machine.datastack) );

	printf("Returnstack : %d cells\n", rstacksize );
	machine.returnstack = (cell_t*)malloc( rstacksize * CELL_SIZE );
	printf("\tPointer %p\n", (void*)(machine.returnstack) );

	printf("\tsetup = %x\n", setup );
	printf("\tquit = %x\n", quit );

	printf("Copy data\n");
	if ( machine.memory ) {
		memset( machine.memory, 0, request_size );
		memmove( machine.memory, image_data, image_data_len );
		WRITE_CELL( &machine, A_DICTIONARY_SIZE, request_size );
	}

	if ( setup ) {
		machine.IP = setup;
		machine_execute( &machine, A_THROW, 0 );
		printf("\nSetup complete\n\n");
	}
	printf("running ...\n");
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

