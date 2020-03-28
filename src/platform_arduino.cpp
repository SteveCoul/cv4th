
#include <Arduino.h>
#include <Wire.h>

#include "platform.h"

#ifdef __SAMD21G18A__
#define Serial SerialUSB
#endif

/* ********************************************************************************** *
 *
 * Terminal stuff
 *
 * ********************************************************************************** */

int platform_read_term( void ) {
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

void platform_write_term( char c ) {
	if ( c == 10 ) { Serial.write(13); }
	Serial.write(c);
	Serial.flush();
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

static ior_t digital_position( FileReference_t* priv, unsigned long long int* position ) {
	return IOR_UNKNOWN;
}

static ior_t digital_size( FileReference_t* priv, unsigned long long int* size ) {
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
 * Wire driver
 *	
 * ********************************************************************************** */

static
ior_t wire_open( const char* name, unsigned int mode, FileReference_t* priv ) {
	Wire.begin();
	return IOR_OK;
}

static
ior_t wire_create( const char* name, unsigned int mode, FileReference_t* priv ) {
	return IOR_UNKNOWN;
}

static
ior_t wire_close( FileReference_t* priv ) {
	return IOR_OK;
}

/**
 *	read +ve amount performs a requestFrom for the given amount +ve
 *
 *	read 0 read and read next byte into buffer 
 */
static
ior_t wire_read( FileReference_t* priv, void* buffer, unsigned int length ) {
	ior_t rc;
	if ( length == 0 ) {
		unsigned char* p = (unsigned char*)buffer;
		p[0] = Wire.read();
		rc = IOR_OK;
	} else {
		rc = (ior_t)Wire.requestFrom( priv->integer, (int)length, (int)(priv->flag) );
	}
	return rc;
}

/**
 *	write is used to send data bytes between begin/end transmission (the ior in this case
 *  is num bytes written )
 */
static
ior_t wire_write( FileReference_t* priv, void* buffer, unsigned int length ) {
	unsigned char*p = (unsigned char*)buffer;
	return (ior_t)Wire.write( p, length );
}

static ior_t wire_position( FileReference_t* priv, unsigned long long int* position ) {
	return IOR_UNKNOWN;
}

/**
 *	fileSize returns availble Rx bytes
 *
 */
static ior_t wire_size( FileReference_t* priv, unsigned long long int* size ) {
	size[0] = Wire.available();
	return IOR_OK;
}

/**
 * 	seek is used to configure/send commands
 *	Seek 0..7F will set i2c address
 *	seek 80 means 'dont send end after Tx/Rx'
 *	Seek 81 means 'send end after Tx/Rx'
 *  Seek 82 means 'begin transmission'
 *	Seek 83 means 'endTransmission'
 */
static ior_t wire_seek( FileReference_t* priv, unsigned long int pos ) {
	ior_t rc;
	if ( ( pos >= 0 ) && ( pos <= 0x7F ) ) {
		priv->integer = pos;
		rc = IOR_OK;
	} else if ( pos == 0x80 ) {
		priv->flag = false;
		rc = IOR_OK;
	} else if ( pos == 0x81 ) {	
		priv->flag = true;
		rc = IOR_OK;
	} else if ( pos == 0x82 ) {
		Wire.beginTransmission( priv->integer );
		rc = IOR_OK;
	} else if ( pos == 0x83 ) {
		Wire.endTransmission( priv->flag );
		rc = IOR_OK;
	} else {
		rc = IOR_UNKNOWN;
	}
	return rc;
}

ioSubsystem io_wire = {	NULL,
						"wire",
						wire_open,
						wire_create,
						wire_close,
						wire_read,
						wire_write,
						wire_position,
						wire_size,
						wire_seek };

/* ********************************************************************************** *
 *
 * ********************************************************************************** */

int platform_init( void ) {

	Serial.begin(115200);
	int counter = 5;
	while ( counter > 0 ) {
		Serial.print("Launching in "); Serial.println( counter );
		counter--;
		delay(1000);
	}

	ioRegister( &io_digital );
	ioRegister( &io_wire );
	return 0;
}

void platform_term( void ) {
}

