
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define MAX_LINE 100
static int total_in = 0;
static int total = 0;
static int line = MAX_LINE;
static void outchar( unsigned char c, int is_last ) {
	if ( line >= MAX_LINE ) {
		printf("\n  ");
		line = 0;
	}
	line += printf("%d%s", c, is_last ? "" : "," );
	total++;
}

int main( int argc, char** argv ) {
	int pad = 0;
	int last_char = -1;
	int count = 0;

	if ( argc > 1 ) pad = atoi( argv[1] );

	printf("const unsigned char image_data[] __attribute__((aligned(16))) = {\\");

	for (;;) {
		unsigned char c;
		int ret = read( STDIN_FILENO, &c, 1 );
		if ( ret != 1 ) {
			break;
		}
		total_in++;
		if ( last_char != -1 ) { outchar( last_char, 0 ); count++; }
		last_char = c;
	}
	
	if ( pad == 0 ) {
		count = 0;
	} else {
		if ( count >= pad ) {
			fprintf( stderr, "we've already output more than the maximum number of bytes\n" );
			return 1;
		}
		count = pad - count -1;
	}

	outchar( last_char, count == 0 );
	if ( count != 0 ) {
		while ( count ) {
			outchar( 0, count == 1 );
			count--;
		}
	}

	printf("};\nconst unsigned int image_data_len = %d; /* %d */ \n", total, total_in );
	printf("\n");
	return 0;
}

