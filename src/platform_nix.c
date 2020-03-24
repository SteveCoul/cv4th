
#include <fcntl.h>
#include <stdio.h>
#include <termios.h>
#include <unistd.h>

#include "platform.h"

int platform_read_term( void ) {
	int tmp;
	unsigned char c[3];
	int ret;
	if (isatty(STDIN_FILENO) )
		ret = read( STDIN_FILENO, c, 3 );	
	else
		ret = read( STDIN_FILENO, c, 1 );	
	/* I'm expecting either 1 byte or 3 ( 27 x y ) */
	if ( ret < 0 ) tmp = -1;
	else if ( ret == 1 ) tmp = c[0];
	else tmp = ( c[1] << 8 ) | c[2];
	return tmp;
}

void platform_write_term( char c ) {
	if ( write( STDOUT_FILENO, &c, 1 ))
		;
}

int platform_init( void ) {
	struct termios raw;
	tcgetattr( STDIN_FILENO, &raw );
	raw.c_lflag &= ~(ECHO | ICANON );
	tcsetattr( STDIN_FILENO, TCSAFLUSH, &raw );

	if ( fcntl( STDIN_FILENO, F_SETFL, fcntl( STDIN_FILENO, F_GETFL ) | O_NONBLOCK ) )
		;
	return 0;
}

void platform_term( void ) {
	struct termios raw;
	tcgetattr( STDIN_FILENO, &raw );
	raw.c_lflag |= (ECHO | ICANON );
	tcsetattr( STDIN_FILENO, TCSAFLUSH, &raw );
}

