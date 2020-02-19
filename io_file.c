
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "io_file.h"

static
int f_open( const char* name, unsigned int mode ) {
	return open( name, mode );
}

static
int f_create( const char* name, unsigned int mode ) {
	// mode is implementation defined, ignore it, if you create a file I'll assume you want r/w
	int rc = open( name, O_RDWR | O_CREAT | O_TRUNC, 0666 );
	return rc;
}

static
int f_close( int fd ) {
	(void)close( fd );
	return 0;
}

static
int f_flush( int fd ) {
	return 0;
}

static
int f_read( int fd, void* buffer, unsigned int length ) {
	return read( fd, buffer, length );
}

static
int f_write( int fd, void* buffer, unsigned int length ) {
	return write( fd, buffer, length );
}

static
int f_size( int fd ) {
	long l = lseek( fd, 0, SEEK_CUR );
	long s = lseek( fd, 0, SEEK_END );
	(void)lseek( fd, l, SEEK_SET );
	return (int)s;
}

static
int f_position( int fd ) {
	return (int)lseek( fd, 0, SEEK_CUR );
}

static
int f_resize( int fd, int new_size ) {
	errno = ENOTSUP;
	return -1;
}

static
int f_reposition( int fd, int new_position ) {
	errno = ENOTSUP;
	return -1;
}

static
int f_rename( const char* name, const char* new_name ) {
	errno = ENOTSUP;
	return -1;
}

static
int f_rm( const char* name ) {
	errno = ENOTSUP;
	return -1;
}

ioSubsystem io_file = {	NULL,
						"file",
						f_open,
						f_create,
						f_close,
						f_flush,
						f_read,
						f_write,
						f_size,
						f_position,
						f_resize,
						f_reposition,
						f_rename,
						f_rm };

