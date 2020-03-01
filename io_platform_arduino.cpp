
#include "io_platform.h"

int io_platform_init( void ) {
	return 0;
}

void io_platform_term( void ) {
}

ior_t io_platform_read_block( unsigned int number, void* where ) {
	return IOR_UNKNOWN;
}

ior_t io_platform_write_block( unsigned int number, void* what ) {
	return IOR_UNKNOWN;
}

int io_platform_block_fd( void ) {
	return -1;
}

int io_platform_block_count( void ) {
	return 0;
}

