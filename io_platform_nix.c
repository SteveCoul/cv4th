
#include <fcntl.h>
#include <stdio.h>
#include <termios.h>
#include <unistd.h>

#include "io_platform.h"

int io_platform_read_term( void ) {
	int tmp;
	unsigned char c[3];
	int ret = read( STDIN_FILENO, c, 3 );	
	/* I'm expecting either 1 byte or 3 ( 27 x y ) */
	if ( ret == 1 ) tmp = c[0];
	else tmp = ( c[1] << 8 ) | c[2];
	return tmp;
}

void io_platform_write_term( char c ) {
	if ( write( STDOUT_FILENO, &c, 1 ))
		;
}

int io_platform_init( void ) {
	struct termios raw;
	tcgetattr( STDIN_FILENO, &raw );
	raw.c_lflag &= ~(ECHO | ICANON );
	tcsetattr( STDIN_FILENO, TCSAFLUSH, &raw );
	return 0;
}

void io_platform_term( void ) {
	struct termios raw;
	tcgetattr( STDIN_FILENO, &raw );
	raw.c_lflag |= (ECHO | ICANON );
	tcsetattr( STDIN_FILENO, TCSAFLUSH, &raw );
}

ior_t io_platform_read_block( unsigned int number, void* where ) {
	if ( lseek( io_platform_block_fd(), number*1024, SEEK_SET ) < 0 ) return IOR_UNKNOWN;
	if ( read( io_platform_block_fd(), where, 1024 ) != 1024 ) return IOR_UNKNOWN;
	return IOR_OK;
}

ior_t io_platform_write_block( unsigned int number, void* what ) {
	(void)lseek( io_platform_block_fd(), number*1024, SEEK_SET );
	if ( write( io_platform_block_fd(), what, 1024 ) )
		;
	return IOR_OK;
}

int io_platform_block_fd( void ) {
	static int fd = -1;
	if ( fd == -1 ) {
		fd = open( "blockfile", O_RDWR | O_CREAT, 0666 );
		if (ftruncate( fd, io_platform_block_count() * 1024 ))
			;
	}
	return fd;
}

int io_platform_block_count( void ) {
	return 65535;
}

