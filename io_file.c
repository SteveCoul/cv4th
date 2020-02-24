
#include <stdio.h>
#include <string.h>
#include "io_file.h"

#ifdef NO_FILE


static ior_t f_open( const char* name, unsigned int mode, int* pfd ) { return IOR_NOT_SUPPORTED; }
static ior_t f_create( const char* name, unsigned int mode, int* pfd ) { return IOR_NOT_SUPPORTED; }
static ior_t f_close( int fd ) { return IOR_NOT_SUPPORTED; }
static ior_t f_read( int fd, void* buffer, unsigned int length ) { return IOR_NOT_SUPPORTED; }
static ior_t f_write( int fd, void* buffer, unsigned int length ) { return IOR_NOT_SUPPORTED; }
static ior_t f_position( int fd, unsigned long int* position ) { return IOR_NOT_SUPPORTED; }
static ior_t f_size( int fd, unsigned long int* size ) { return IOR_NOT_SUPPORTED; }
static ior_t f_seek( int fd, unsigned long int pos ) { return IOR_NOT_SUPPORTED; }

#else
#include <fcntl.h>
#include <unistd.h>

static
ior_t f_open( const char* name, unsigned int mode, int* pfd ) {
	switch( mode ) {
	case IO_RDONLY: mode = O_RDONLY; break;
	case IO_WRONLY: mode = O_WRONLY; break;
	case IO_RDWR: mode = O_RDWR; break;
	default: mode = O_RDONLY; break;
	}

	pfd[0] = open( name, mode );
	if ( pfd[0] >= 0 ) return IOR_OK;
	return IOR_UNKNOWN;
}

static
ior_t f_create( const char* name, unsigned int mode, int* pfd ) {
	/* mode is implementation defined, ignore it, if you create a file I'll assume you want r/w */
	pfd[0] = open( name, O_RDWR | O_CREAT | O_TRUNC, 0666 );
	if ( pfd[0] >= 0 ) return IOR_OK;
	return IOR_UNKNOWN;
}

static
ior_t f_close( int fd ) {
	(void)close( fd );
	return IOR_OK;
}

static
ior_t f_read( int fd, void* buffer, unsigned int length ) {
	if ( read( fd, buffer, length ) < 0 ) return IOR_UNKNOWN;
	return IOR_OK;
}

static
ior_t f_write( int fd, void* buffer, unsigned int length ) {
	if ( write( fd, buffer, length ) < 0 ) return IOR_UNKNOWN;
	return IOR_OK;
}

static ior_t f_position( int fd, unsigned long int* position ) {
	position[0] = lseek( fd, 0, SEEK_CUR );
	return IOR_OK;
}

static ior_t f_size( int fd, unsigned long int* size ) {
	unsigned position = lseek( fd, 0, SEEK_CUR );
	size[0] = lseek( fd, 0, SEEK_END );
	position = lseek( fd, position, SEEK_SET );
	return IOR_OK;
}

static ior_t f_seek( int fd, unsigned long int pos ) {
	if ( lseek( fd, pos, SEEK_SET ) < 1 ) return IOR_UNKNOWN;
	return IOR_OK;
}

#endif

ioSubsystem io_file = {	NULL,
						"file",
						f_open,
						f_create,
						f_close,
						f_read,
						f_write,
						f_position,
						f_size,
						f_seek };


