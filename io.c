
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "io.h"

static struct {
	int				native_fd;
	ioSubsystem*	p;
} myfiles[256];

static ioSubsystem*	list = NULL;

static
int freeslot( void ) {
	int i;
	for ( i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		if ( myfiles[i].native_fd == -1 ) 
			return i;
	return -1;
}

static
ioSubsystem* getSubsystem( const char* name ) {
	ioSubsystem* p = list;
	while ( p != NULL ) {
		if ( cmp( name, p->name, strlen( name ) + 1 ) == 0 ) 
			return p;
		p = (ioSubsystem*)(p->link);
	}
	return NULL;
}

static
void dropfile( int fd ) {
	int i;
	for ( i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		if ( myfiles[i].native_fd == fd ) {
			myfiles[i].native_fd = -1;
			return;
		}
}

static
ioSubsystem* getfile( int fd ) {
	int i;
	for ( i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		if ( myfiles[i].native_fd == fd ) 
			return myfiles[i].p;
	return NULL;
}

void ioInit( void ) {
	int i;
	for ( i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		myfiles[i].native_fd = -1;
}

void ioRegister( ioSubsystem* ios ) {
	ios->link = list;
	list = ios;
}

static
ior_t parse( const char* name, size_t name_len, char** p_type, char** p_path ) {
	static char path_buffer[ 1024 ];
	static char type_buffer[ 32 ];
	int i;

	if ( name_len >= sizeof(path_buffer)-1 ) return IOR_UNKNOWN;

	memmove( path_buffer, name, name_len );
	path_buffer[name_len] = 0;
	strcpy( type_buffer, "file" );	/* default */
	for ( i = 0; i < name_len-1; i++ ) {
		if ( ( name[i] == ':' ) && ( name[i+1] == '/' ) ) {
			int len;
			if ( i >= sizeof(type_buffer) ) return IOR_UNKNOWN;
			memmove( type_buffer, name, i );
			type_buffer[i] = 0;
			i++;		
			len = name_len - i;
			memmove( path_buffer, name+i, len );
			path_buffer[len] = 0;
			break;
		}
	}
			
	p_type[0] = type_buffer;
	p_path[0] = path_buffer;

	return 0;
}

ior_t ioOpen( const char* name, size_t name_len, unsigned int mode, int* pfd ) {
	char* c_type;
	char* c_path;
	ior_t rc;
	rc = parse( name, name_len, &c_type, &c_path );
	if ( rc == 0 ) {
		ioSubsystem* ios = getSubsystem( c_type );
		if ( ios == NULL ) {
			rc = IOR_UNKNOWN;
		} else {
			int i = freeslot();
			if ( i < 0 ) {
				rc = IOR_UNKNOWN;
			} else {
				rc = ios->open( c_path, mode, pfd );
				if ( rc == IOR_OK ) {
					myfiles[i].native_fd = pfd[0];
					myfiles[i].p = ios;
				}
			}
		}
	}
	return rc;
}

ior_t ioCreate( const char* name, size_t name_len, unsigned int mode, int* pfd ) {
	char* c_type;
	char* c_path;
	ior_t rc;
	rc = parse( name, name_len, &c_type, &c_path );
	if ( rc == 0 ) {
		ioSubsystem* ios = getSubsystem( c_type );
		if ( ios == NULL ) {
			rc = IOR_UNKNOWN;
		} else {
			int i = freeslot();
			if ( i < 0 ) {
				rc = IOR_UNKNOWN;
			} else {
				rc = ios->create( c_path, mode, pfd );
				if ( rc == IOR_OK ) {
					myfiles[i].native_fd = pfd[0];
					myfiles[i].p = ios;
				}
			}
		}
	}
	return rc;
}

ior_t ioClose( int fd ) {
	ior_t rc;
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return IOR_UNKNOWN;
	rc = i->close( fd );
	dropfile( fd );
	return rc;
}

ior_t ioRead( int fd, void* buffer, unsigned int length ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return IOR_UNKNOWN;
	return i->read( fd, buffer, length );
}

ior_t ioWrite( int fd, void* buffer, unsigned int length ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return IOR_UNKNOWN;
	return i->write( fd, buffer, length );
}

ior_t ioPosition( int fd, unsigned long int* position ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return IOR_UNKNOWN;
	return i->position( fd, position );
}

ior_t ioSize( int fd, unsigned long int* size ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return IOR_UNKNOWN;
	return i->size( fd, size );
}

