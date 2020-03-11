
#include "io_platform.h"

void io_platform_print_term( const char* t ) {
	while ( t[0] != '\0' ) io_platform_write_term( *t++ );
}

static void _io_platform_printHEX_term( unsigned long long n ) {
	if ( n == 0 ) { io_platform_write_term( '0' ); } 
	else {
		int v = n % 16;
		if ( (n/16) != 0 ) {
			_io_platform_printHEX_term( n/16 );
		}
		if ( v > 9 ) v += 7;
		io_platform_write_term( v+'0' );
	}
}

void io_platform_printHEX_term( unsigned long long n ) {
	io_platform_print_term( "0x" );
	_io_platform_printHEX_term( n );
}

void io_platform_printN_term( int n ) {
	if ( n < 0 ) {  io_platform_write_term( '-' ); n = -n ; }
	if ( n == 0 ) { io_platform_write_term( '0' ); } 
	else {
		int v = n % 10;
		if ( (n/10) != 0 ) {
			io_platform_printN_term( n/10 );
		}
		io_platform_write_term( v+'0' );
	}
}

void io_platform_println_term( const char* t ) {
	io_platform_print_term( t );
	io_platform_print_term( "\r\n" );
}

