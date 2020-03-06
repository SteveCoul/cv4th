
#include <Arduino.h>

#include "io_platform.h"

#ifdef __SAMD21G18A__
#define Serial SerialUSB
#endif

int io_platform_read_term( void ) {
	yield();
	int rc;
	if ( Serial.available() >= 1 )
		rc = Serial.read();
	else
		rc = -1;
	if ( rc == 13 ) rc = 10;


	if ( rc == 27 ) {
		if ( Serial.available() < 2 ) delay(250);
		if ( Serial.available() >= 2 ) {
			if ( Serial.peek() == '[' ) {
				rc = ( ( Serial.read() & 255 ) << 8 ) | ( Serial.read() & 255 );
			}
		}
	}

	return rc;
}

void io_platform_write_term( char c ) {
	if ( c == 10 ) { Serial.write(13); }
	Serial.write(c);
}

int io_platform_init( void ) {
	return 0;
}

void io_platform_term( void ) {
}

