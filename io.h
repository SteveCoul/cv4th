
#ifndef __io_h__
#define __io_h__

#include <stddef.h>

extern void ioInit( void );

typedef struct {
	void* link;
	const char*	name;
	int (*open)( const char* name, unsigned int mode );
	int (*create)( const char* name, unsigned int mode );
	int (*close)( int fd );
	int (*flush)( int fd );
	int (*read)( int fd, void* buffer, unsigned int length );
	int (*write)( int fd, void* buffer, unsigned int length );
	int (*size)( int fd );
	int (*position)( int fd );
	int (*resize)( int fd, int new_size );
	int (*reposition)( int fd, int new_position );
	int (*rename)( const char* name, const char* new_name );
	int (*rm)( const char* name );
} ioSubsystem;

extern void ioRegister( ioSubsystem* ios );
extern int ioOpen( const char* name, size_t namelen, unsigned int mode );
extern int ioCreate( const char* name, size_t namelen, unsigned int mode );
extern int ioClose( int fd );
extern int ioFlush( int fd );
extern int ioRead( int fd, void* buffer, unsigned int length );
extern int ioWrite( int fd, void* buffer, unsigned int length );
extern int ioSize( int fd );
extern int ioPosition( int fd );
extern int ioResize( int fd, int new_size );
extern int ioReposition( int fd, int new_position );
extern int ioRename( const char* name, size_t namelen, const char* new_name, size_t new_namelen );
extern int ioDelete( const char* name, size_t namelen );

#endif

