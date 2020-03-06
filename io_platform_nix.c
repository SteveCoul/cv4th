
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

