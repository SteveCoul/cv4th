
#include "platform.h"

void platform_print_term( const char* t ) {
	while ( t[0] != '\0' ) platform_write_term( *t++ );
}

static void _platform_printHEX_term( unsigned long long n ) {
	if ( n == 0 ) { platform_write_term( '0' ); } 
	else {
		int v = n % 16;
		if ( (n/16) != 0 ) {
			_platform_printHEX_term( n/16 );
		}
		if ( v > 9 ) v += 7;
		platform_write_term( v+'0' );
	}
}

void platform_printHEX_term( unsigned long long n ) {
	platform_print_term( "0x" );
	_platform_printHEX_term( n );
}

void platform_printN_term( int n ) {
	if ( n < 0 ) {  platform_write_term( '-' ); n = -n ; }
	if ( n == 0 ) { platform_write_term( '0' ); } 
	else {
		int v = n % 10;
		if ( (n/10) != 0 ) {
			platform_printN_term( n/10 );
		}
		platform_write_term( v+'0' );
	}
}

void platform_println_term( const char* t ) {
	platform_print_term( t );
	platform_print_term( "\r\n" );
}

