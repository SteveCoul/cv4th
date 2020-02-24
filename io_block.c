#include <stdio.h>
#include <stdint.h>

#include "io_platform.h"
#include "io_block.h"

/* a really dumb file system that I promise only has one client at a time :-) */

static uint32_t _pos;

static
ior_t f_open( const char* name, unsigned int mode, int* pfd ) {
    _pos = 0;
	pfd[0] = io_platform_block_fd();
	return IOR_OK;
}

static
ior_t f_create( const char* name, unsigned int mode, int* pfd ) {
	return IOR_NOT_SUPPORTED;
}

static
ior_t f_close( int fd ) {
	return IOR_OK;
}

static
ior_t f_read( int fd, void* buffer, unsigned int length ) {
	ior_t rc;
	if ( length != 1024 ) {
		rc = IOR_UNKNOWN;
	} else {
		rc = io_platform_read_block( _pos / 1024, buffer );
	}
	return rc;
}

static
ior_t f_write( int fd, void* buffer, unsigned int length ) {
	ior_t rc;
	if ( length != 1024 ) {
		rc = IOR_UNKNOWN;
	} else {
		rc = io_platform_write_block( _pos / 1024, buffer );
	}
	return rc;
}

static ior_t f_position( int fd, unsigned long int* position ) {
	position[0] = _pos;
	return IOR_OK;
}

static ior_t f_size( int fd, unsigned long int* size ) {
	size[0] = io_platform_block_count() * 1024;
	return IOR_OK;
}

static ior_t f_seek( int fd, unsigned long int pos ) {
	ior_t rc;
	unsigned long int size;
	rc = f_size( fd, &size );
	if ( rc == IOR_OK ) {
		if ( pos >= size ) {
			rc = IOR_UNKNOWN;
		} else if ( ( pos % 1024 ) != 0 ) {
			rc = IOR_UNKNOWN;
		} else {
			_pos = pos;
			rc = IOR_OK;
		}
	}
	return rc;
}

ioSubsystem io_block = {	NULL,
						"block",
						f_open,
						f_create,
						f_close,
						f_read,
						f_write,
						f_position,
						f_size,
						f_seek };


