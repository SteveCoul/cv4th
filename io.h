
#ifndef __io_h__
#define __io_h__

#include <stddef.h>

extern void ioInit( void );

typedef enum {
	IOR_OK=0,
	IOR_NOT_SUPPORTED,
	IOR_UNKNOWN
} ior_t;

typedef struct {
	void* link;
	const char*	name;
	ior_t (*open)( const char* name, unsigned int mode, int* fd );
	ior_t (*create)( const char* name, unsigned int mode, int* fd );
	ior_t (*close)( int fd );
	ior_t (*read)( int fd, void* buffer, unsigned int length );
	ior_t (*write)( int fd, void* buffer, unsigned int length );
	ior_t (*position)( int fd, unsigned long int* position );
	ior_t (*size)( int fd, unsigned long int* size );
} ioSubsystem;

extern void ioRegister( ioSubsystem* ios );
extern ior_t ioOpen( const char* name, size_t namelen, unsigned int mode, int* fd );
extern ior_t ioCreate( const char* name, size_t namelen, unsigned int mode, int* fd );
extern ior_t ioClose( int fd );
extern ior_t ioRead( int fd, void* buffer, unsigned int length );
extern ior_t ioWrite( int fd, void* buffer, unsigned int length );
extern ior_t ioPosition( int fd, unsigned long int* position );
extern ior_t ioSize( int fd, unsigned long int* size );
#endif

