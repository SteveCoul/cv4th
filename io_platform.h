
#ifndef __io_platform_h__
#define __io_platform_h__

#include "io.h"

extern int io_platform_init( void );
extern void io_platform_term( void );
extern int io_platform_read_term( void );
extern void io_platform_write_term( char c );
extern void io_platform_print_term( const char* t );
extern void io_platform_printN_term( int n );
extern void io_platform_printHEX_term( unsigned long long n );
extern void io_platform_println_term( const char* t );
#endif

