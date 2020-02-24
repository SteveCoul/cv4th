
#ifndef __io_platform_h__
#define __io_platform_h__

#include "io.h"

extern int io_platform_init( void );
extern void io_platform_term( void );
extern ior_t io_platform_read_block( unsigned int number, void* where );
extern ior_t io_platform_write_block( unsigned int number, void* what );
extern int io_platform_block_fd( void );
extern int io_platform_block_count( void );

#endif

