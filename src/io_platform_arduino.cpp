
#include <Arduino.h>

#include "io_platform.h"

#ifdef __SAMD21G18A__
#define Serial SerialUSB
#endif

/* ********************************************************************************** *
 *
 * Terminal stuff
 *
 * ********************************************************************************** */

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

/* ********************************************************************************** *
 *
 * Digital GPIO driver
 *
 * ********************************************************************************** */

static
ior_t digital_open( const char* name, unsigned int mode, FileReference_t* priv ) {
	if ( mode != IO_RDWR ) return IOR_UNKNOWN;
	/* not very robust */
	priv->integer = atoi( name+1 );
	return IOR_OK;
}

static
ior_t digital_create( const char* name, unsigned int mode, FileReference_t* priv ) {
	return IOR_UNKNOWN;
}

static
ior_t digital_close( FileReference_t* priv ) {
	return IOR_OK;
}

static
ior_t digital_read( FileReference_t* priv, void* buffer, unsigned int length ) {
	char *p = (char*)buffer;
	p[0] = digitalRead( priv->integer );
	return IOR_OK;
}

static
ior_t digital_write( FileReference_t* priv, void* buffer, unsigned int length ) {
	char *p = (char*)buffer;
	if ( length == 0 ) return IOR_UNKNOWN;
	if ( p[0] ) digitalWrite( priv->integer, HIGH );
	else digitalWrite( priv->integer, LOW );
	return IOR_OK;
}

static ior_t digital_position( FileReference_t* priv, unsigned long int* position ) {
	return IOR_UNKNOWN;
}

static ior_t digital_size( FileReference_t* priv, unsigned long int* size ) {
	size[0] = 3;
	return IOR_OK;
}

static ior_t digital_seek( FileReference_t* priv, unsigned long int pos ) {
	if ( pos == 0 ) { pinMode( priv->integer, INPUT );  }
	else if ( pos == 1 ) { pinMode( priv->integer, OUTPUT );  }
	else if ( pos == 2 ) { pinMode( priv->integer, INPUT_PULLUP ); }
	else return IOR_UNKNOWN;
	return IOR_OK;
}

ioSubsystem io_digital = {	NULL,
							"digital",
							digital_open,
							digital_create,
							digital_close,
							digital_read,
							digital_write,
							digital_position,
							digital_size,
							digital_seek };

/* ********************************************************************************** *
 *
 * ********************************************************************************** */

int io_platform_init( void ) {

	Serial.begin(115200);
	int counter = 5;
	while ( counter > 0 ) {
		Serial.print("Launching in "); Serial.println( counter );
		counter--;
		delay(1000);
	}

	ioRegister( &io_digital );
	return 0;
}

void io_platform_term( void ) {
}

