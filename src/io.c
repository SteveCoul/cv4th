
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "io.h"

static struct {
	FileReference_t	ref;
	ioSubsystem*	io;
} myfiles[256];

static ioSubsystem*	list = NULL;

static
int freeslot( void ) {
	int i;
	for ( i = 0; i < sizeof(myfiles)/sizeof(myfiles[0]); i++ )
		if ( myfiles[i].io == NULL )
			return i;
	return -1;
}

static
ioSubsystem* getSubsystem( const char* name ) {
	ioSubsystem* p = list;
	while ( p != NULL ) {
		if ( cmp( name, strlen(name)+1, p->name, strlen( name ) + 1, 0 ) == 0 ) {
			return p;
		}
		p = (ioSubsystem*)(p->link);
	}
	return NULL;
}

void ioInit( void ) {
	memset( myfiles, 0, sizeof(myfiles) );
	myfiles[0].io = (ioSubsystem*)1;	// Cannot use 0, because the index I return is the file descriptor
	// that in forth is put into source-id and source-id 0 has special meaning.
}

void ioRegister( ioSubsystem* ios ) {
	ios->link = list;
	list = ios;
}

static
ior_t parse( const char* name, size_t name_len, char** p_type, char** p_path ) {
#define NUM_BUFFERS 2
#define SIZE_PATH_BUFFER	255
#define SIZE_TYPE_BUFFER	11
	static int  which = 0;
	static char _path_buffer[NUM_BUFFERS][ SIZE_PATH_BUFFER+1 ];
	static char _type_buffer[NUM_BUFFERS][ SIZE_TYPE_BUFFER+1 ];
	char* path_buffer;
	char* type_buffer;
	int i;

	path_buffer = _path_buffer[ which ];
	type_buffer = _type_buffer[ which ];
	which++;
	if ( which == NUM_BUFFERS ) which = 0;

	if ( name_len >= SIZE_PATH_BUFFER ) return IOR_UNKNOWN;

	memmove( path_buffer, name, name_len );
	path_buffer[name_len] = 0;
	strcpy( type_buffer, "file" );	/* default */
	for ( i = 0; i < name_len-1; i++ ) {
		if ( ( name[i] == ':' ) && ( name[i+1] == '/' ) ) {
			int len;
			if ( i >= SIZE_TYPE_BUFFER ) return IOR_UNKNOWN;
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

	return IOR_OK;
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
				rc = ios->open( c_path, mode, &(myfiles[i].ref) );
				if ( rc != IOR_OK ) {
				} else {
					myfiles[i].io = ios;
					pfd[0] = i;
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
				rc = ios->create( c_path, mode, &(myfiles[i].ref) );
				if ( rc == IOR_OK ) {
					myfiles[i].io = ios;
					pfd[0] = i;
				}
			}
		}
	}
	return rc;
}

ior_t ioClose( int fd ) {
	ior_t rc = myfiles[fd].io->close( &(myfiles[fd].ref) );
	myfiles[fd].io = NULL;
	return rc;
}

ior_t ioRead( int fd, void* buffer, unsigned int length ) {
	return myfiles[fd].io->read( &(myfiles[fd].ref), buffer, length );
}

ior_t ioWrite( int fd, void* buffer, unsigned int length ) {
	return myfiles[fd].io->write( &(myfiles[fd].ref), buffer, length );
}

ior_t ioPosition( int fd, unsigned long long int* position ) {
	return myfiles[fd].io->position( &(myfiles[fd].ref), position );
}

ior_t ioSize( int fd, unsigned long long int* size ) {
	return myfiles[fd].io->size( &(myfiles[fd].ref), size );
}

ior_t ioSeek( int fd, unsigned long int position ) {
	return myfiles[fd].io->seek( &(myfiles[fd].ref), position );
}

