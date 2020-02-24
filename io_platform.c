
#include <termios.h>
#include <unistd.h>

#include "io_platform.h"

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
	return IOR_OK;
}

ior_t io_platform_write_block( unsigned int number, void* what ) {
	return IOR_OK;
}

