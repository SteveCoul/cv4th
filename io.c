
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "common.h"
#include "io.h"

static struct {
	int				native_fd;
	ioSubsystem*	p;
} myfiles[256];

static ioSubsystem*	list = NULL;

static
int freeslot( void ) {
	for ( int i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
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
	for ( int i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		if ( myfiles[i].native_fd == fd ) {
			myfiles[i].native_fd = -1;
			return;
		}
}

static
ioSubsystem* getfile( int fd ) {
	for ( int i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		if ( myfiles[i].native_fd == fd ) 
			return myfiles[i].p;
	return NULL;
}

void ioInit( void ) {
	for ( int i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		myfiles[i].native_fd = -1;
}

void ioRegister( ioSubsystem* ios ) {
	ios->link = list;
	list = ios;
}

static
int parse( const char* name, size_t name_len, char** p_type, char** p_path ) {
	static char path_buffer[ 1024 ];
	static char type_buffer[ 32 ];
	if ( name_len >= sizeof(path_buffer)-1 ) return -ENAMETOOLONG;

	memmove( path_buffer, name, name_len );
	path_buffer[name_len] = 0;
	strcpy( type_buffer, "file" );	/* default */
	int i;
	for ( i = 0; i < name_len-1; i++ ) {
		if ( ( name[i] == ':' ) && ( name[i+1] == '/' ) ) {
			if ( i >= sizeof(type_buffer) ) return -ENAMETOOLONG;
			memmove( type_buffer, name, i );
			type_buffer[i] = 0;
			i++;		
			int len = name_len - i;
			memmove( path_buffer, name+i, len );
			path_buffer[len] = 0;
			break;
		}
	}
			
	p_type[0] = type_buffer;
	p_path[0] = path_buffer;

	return 0;
}

int ioOpen( const char* name, size_t name_len, unsigned int mode ) {
	char* c_type;
	char* c_path;
	int rc;
	rc = parse( name, name_len, &c_type, &c_path );
	if ( rc == 0 ) {
		ioSubsystem* ios = getSubsystem( c_type );
		if ( ios == NULL ) {
			rc = -EOPNOTSUPP;
		} else {
			int i = freeslot();
			if ( i < 0 ) {
				rc = -EMFILE;
			} else {
				int fd = ios->open( c_path, mode );
				if ( fd < 0 ) {
					rc = -errno;
				} else {
					myfiles[i].native_fd = fd;
					myfiles[i].p = ios;
					rc = fd;
				}
			}
		}
	}
	return rc;
}

int ioCreate( const char* name, size_t name_len, unsigned int mode ) {
	char* c_type;
	char* c_path;
	int rc;
	rc = parse( name, name_len, &c_type, &c_path );
	if ( rc == 0 ) {
		ioSubsystem* ios = getSubsystem( c_type );
		if ( ios == NULL ) {
			rc = -EOPNOTSUPP;
		} else {
			int i = freeslot();
			if ( i < 0 ) {
				rc = -EMFILE;
			} else {
				int fd = ios->create( c_path, mode );
				if ( fd < 0 ) {
					rc = -errno;
				} else {
					myfiles[i].native_fd = fd;
					myfiles[i].p = ios;
					rc = fd;
				}
			}
		}
	}
	return rc;
}

int ioClose( int fd ) {
	int rc;
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	rc = i->close( fd );
	dropfile( fd );
	return rc;
}

int ioFlush( int fd ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->flush( fd );
}

int ioRead( int fd, void* buffer, unsigned int length ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->read( fd, buffer, length );
}

int ioWrite( int fd, void* buffer, unsigned int length ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->write( fd, buffer, length );
}

int ioSize( int fd ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->size( fd );
}

int ioPosition( int fd ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->position( fd );
}

int ioResize( int fd, int new_size ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->resize( fd, new_size );
}

int ioReposition( int fd, int new_position ) {
	ioSubsystem* i = getfile( fd );
	if ( i == NULL ) return -EBADF;
	return i->reposition( fd, new_position );
}

int ioRename( const char* name, size_t namelen, const char* new_name, size_t new_namelen ) {
	printf("\nioRename not implemented\n" );
	return -ENOTSUP;
}

int ioDelete( const char* name, size_t namelen ) {
	printf("\nioDelete not implemented\n" );
	return -ENOTSUP;
}

