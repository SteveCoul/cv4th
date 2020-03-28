#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#include "io_file.h"

static
ior_t f_open( const char* name, unsigned int mode, FileReference_t* priv ) {
	switch( mode ) {
	case IO_RDONLY: mode = O_RDONLY; break;
	case IO_WRONLY: mode = O_WRONLY; break;
	case IO_RDWR: mode = O_RDWR; break;
	default: mode = O_RDONLY; break;
	}

	priv->integer = open( name, mode );
	if ( priv->integer >= 0 ) return IOR_OK;
	return IOR_UNKNOWN;
}

static
ior_t f_create( const char* name, unsigned int mode, FileReference_t* priv ) {
	/* mode is implementation defined, ignore it, if you create a file I'll assume you want r/w */
	priv->integer = open( name, O_RDWR | O_CREAT | O_TRUNC, 0666 );
	if ( priv->integer >= 0 ) return IOR_OK;
	return IOR_UNKNOWN;
}

static
ior_t f_close( FileReference_t* priv ) {
	(void)close( priv->integer );
	return IOR_OK;
}

static
ior_t f_read( FileReference_t* priv, void* buffer, unsigned int length ) {
	if ( read( priv->integer, buffer, length ) < 0 ) return IOR_UNKNOWN;
	return IOR_OK;
}

static
ior_t f_write( FileReference_t* priv, void* buffer, unsigned int length ) {
	if ( write( priv->integer, buffer, length ) < 0 ) return IOR_UNKNOWN;
	return IOR_OK;
}

static ior_t f_position( FileReference_t* priv, unsigned long long int* position ) {
	position[0] = lseek( priv->integer, 0, SEEK_CUR );
	return IOR_OK;
}

static ior_t f_size( FileReference_t* priv, unsigned long long int* size ) {
	unsigned position = lseek( priv->integer, 0, SEEK_CUR );
	size[0] = lseek( priv->integer, 0, SEEK_END );
	position = lseek( priv->integer, position, SEEK_SET );
	return IOR_OK;
}

static ior_t f_seek( FileReference_t* priv, unsigned long int pos ) {
	if ( lseek( priv->integer, pos, SEEK_SET ) < 0 ) return IOR_UNKNOWN;
	return IOR_OK;
}

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


