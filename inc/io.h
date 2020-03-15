
#ifndef __io_h__
#define __io_h__

#include <stddef.h>

extern void ioInit( void );

typedef struct {
	void*	pointer;
	int		integer;
	int		flag;
} FileReference_t;

#define IO_RDONLY 1
#define IO_WRONLY 2
#define IO_RDWR	  4

typedef enum {
	IOR_OK=0,
	IOR_NOT_SUPPORTED,
	IOR_UNKNOWN
} ior_t;

typedef struct {
	void* link;
	const char*	name;
	ior_t (*open)( const char* name, unsigned int mode, FileReference_t* private_data );
	ior_t (*create)( const char* name, unsigned int mode, FileReference_t* private_data );
	ior_t (*close)( FileReference_t* private_data );
	ior_t (*read)( FileReference_t* private_data, void* buffer, unsigned int length );
	ior_t (*write)( FileReference_t* private_data, void* buffer, unsigned int length );
	ior_t (*position)( FileReference_t* private_data, unsigned long int* position );
	ior_t (*size)( FileReference_t* private_data, unsigned long int* size );
	ior_t (*seek)( FileReference_t* private_data, unsigned long int position );
} ioSubsystem;

extern void ioRegister( ioSubsystem* ios );
extern ior_t ioOpen( const char* name, size_t namelen, unsigned int mode, int* fd );
extern ior_t ioCreate( const char* name, size_t namelen, unsigned int mode, int* fd );
extern ior_t ioClose( int fd );
extern ior_t ioRead( int fd, void* buffer, unsigned int length );
extern ior_t ioWrite( int fd, void* buffer, unsigned int length );
extern ior_t ioPosition( int fd, unsigned long int* position );
extern ior_t ioSize( int fd, unsigned long int* size );
extern ior_t ioSeek( int fd, unsigned long int position );

#endif

