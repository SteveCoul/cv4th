
#ifndef __platform_h__
#define __platform_h__

#include "io.h"

extern int platform_init( void );
extern void platform_term( void );
extern int platform_read_term( void );
extern void platform_write_term( char c );
extern void platform_print_term( const char* t );
extern void platform_printN_term( int n );
extern void platform_printHEX_term( unsigned long long n );
extern void platform_println_term( const char* t );

#endif

