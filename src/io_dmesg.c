#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "io_dmesg.h"

/* if i ever have threads make open/close grab the lock */

static char dmesg_buffer[1024];
static int dmesg_pos = 0;

static
ior_t f_open( const char* name, unsigned int mode, FileReference_t* priv ) {
	priv->integer = 0;
	return IOR_OK;
}

static
ior_t f_create( const char* name, unsigned int mode, FileReference_t* priv ) {
	return IOR_UNKNOWN;
}

static
ior_t f_close( FileReference_t* priv ) {
	return IOR_OK;
}

static
ior_t f_read( FileReference_t* priv, void* buffer, unsigned int length ) {
	unsigned int readable = dmesg_pos - priv->integer;

	if ( priv->integer >= dmesg_pos ) return (ior_t)0;

	if ( length > readable ) length = readable;
	
	memcpy( buffer, dmesg_buffer+priv->integer, length );
	priv->integer += length;
	return (ior_t)length;
}

static void make_space( unsigned int length ) {
	unsigned int space = sizeof(dmesg_buffer) - dmesg_pos ;
	if ( space < length ) {
		unsigned int need = length - space;
		memmove( dmesg_buffer, dmesg_buffer+need, dmesg_pos-need );
		dmesg_pos-=need;
	}
}

static
ior_t f_write( FileReference_t* priv, void* buffer, unsigned int length ) {

	if ( length == 0 ) return (ior_t)0;
	if ( length >= sizeof(dmesg_buffer ) ) return IOR_UNKNOWN;

	make_space( length );

	memcpy( dmesg_buffer+dmesg_pos, buffer, length );
	dmesg_pos += length;
	priv->integer+=length;
	return (ior_t)length;
}

static ior_t f_position( FileReference_t* priv, unsigned long long int* position ) {
	return IOR_UNKNOWN;
}

static ior_t f_size( FileReference_t* priv, unsigned long long int* size ) {
	size[0] = dmesg_pos;
	return IOR_OK;
}

static ior_t f_seek( FileReference_t* priv, unsigned long int pos ) {
	priv->integer = (int)pos;
	return IOR_OK;
}

ioSubsystem io_dmesg = {	NULL,
							"dmesg",
							f_open,
							f_create,
							f_close,
							f_read,
							f_write,
							f_position,
							f_size,
							f_seek };

void dmesg( const char* fmt, ... ) {
	int len;
	va_list args;

	va_start( args, fmt );
	len = vsnprintf( NULL, 0, fmt, args );
	va_end( args );

	if ( len > (int)sizeof(dmesg_buffer) ) return;
	make_space( len );
	va_start( args, fmt );
	dmesg_pos += vsprintf( dmesg_buffer+dmesg_pos, fmt, args );
	va_end( args );
}

