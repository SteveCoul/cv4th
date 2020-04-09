#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sam.h>
#include "platform.h"

/* ************************************************************************** *
 *
 * ************************************************************************** */

#define ALIGNED __attribute__((aligned(4)))
#define MIN( a, b ) ( (a) < (b) ) ? (a) : (b)

/* ************************************************************************** *
 *
 * ************************************************************************** */

static void LEDon( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTSET.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTSET.reg |= ( 1 << 15 );
}

static void LEDoff( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTCLR.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTCLR.reg |= ( 1 << 15 );
}

/*
static void LEDtoggle( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTTGL.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTTGL.reg |= ( 1 << 15 );
}
*/

#define WAIT 500000
//#define WAIT 100000

static void wait( int l ) { for ( int i = 0; i < (l*WAIT); i++ ) i = i; }
static void dot( void ) { LEDoff(); wait(1); LEDon(); wait(1); LEDoff(); wait(1); }
static void dash( void ) { LEDoff(); wait(1); LEDon(); wait(3); LEDoff(); wait(1); }
static void hacf( void ) { for(;;) { wait(6); dot(); dot(); dot(); dash(); dash(); dash(); dot(); dot(); dot(); } }

/* ************************************************************************** *
 *
 * ************************************************************************** */

#define USB_VID 0x1B4F
#define USB_PID 0x0D23
#define SIZE_PACKET 64

#define USB_EP_COMM_IN 0
#define USB_EP_IN 1
#define USB_EP_OUT 2
#define USB_EP_COMM 3

#define USB_REQUEST_GET_STATUS_ZERO 		0x0080
#define USB_REQUEST_GET_STATUS_INTERFACE 	0x0081
#define USB_REQUEST_GET_STATUS_ENDPOINT 	0x0082
#define USB_REQUEST_CLEAR_FEATURE_INTERFACE	0x0101
#define USB_REQUEST_CLEAR_FEATURE_ENDPOINT 	0x0102
#define USB_REQUEST_SET_FEATURE_INTERFACE 	0x0301
#define USB_REQUEST_SET_FEATURE_ENDPOINT 	0x0302
#define USB_REQUEST_SET_ADDRESS 			0x0500
#define USB_REQUEST_GET_DESCRIPTOR 			0x0680
#define USB_REQUEST_GET_DESCRIPTOR1 		0x0681
#define USB_REQUEST_GET_CONFIGURATION 		0x0880
#define USB_REQUEST_SET_CONFIGURATION 		0x0900
#define USB_REQUEST_GET_LINE_CODING 		0x21A1
#define USB_REQUEST_SET_LINE_CODING 		0x2021
#define USB_REQUEST_SET_CONTROL_LINE_STATE 	0x2221

static unsigned char* inputbuffer;
static unsigned char* control_packet;
static unsigned char* outputbuffer;
static UsbDeviceDescriptor* endpoint;
static uint8_t usb_active_config;

static uint8_t line_config[] = { 0x00, 0xC2, 0x01, 0x00, 0x00, 0x00, 0x08 };	// 115200 8N1

const char devDescriptor[] = { 	0x12, 0x01, 0x00, 0x02, 0xEF, 0x02, 0x01, 0x40,
								USB_VID & 0xff, USB_VID >> 8, USB_PID & 0xff,
								USB_PID >> 8, 0x01, 0x42, 0x01, 0x02, 0x03, 0x01 };

const char cfgDescriptor[] = { 	0x09, 0x02, 75, 0, 3, 0x01, 0x00, 0x80, 250, 0x08, 
								0x0B, 0x00, 0x02, 0x02, 0x02, 0x01, 0x00, 0x09, 0x04, 
								0x00, 0x00, 0x01, 0x02, 0x02, 0x01, 0x00, 0x05, 0x24, 
								0x00, 0x10, 0x01, 0x04, 0x24, 0x02, 0x06, 0x05, 0x24, 
								0x06, 0x00, 0x01, 0x05, 0x24, 0x01, 0x03, 0x01, 0x07,
								0x05, USB_EP_COMM | 0x80, 0x03, 0x08, 0x00, 0xFF, 0x09,
								0x04, 0x01, 0x00, 0x02, 0x0A, 0x00, 0x00, 0x00, 0x07,
								0x05, USB_EP_IN | 0x80, 0x02, SIZE_PACKET, 0x00, 0x00,
								0x07, 0x05, USB_EP_OUT, 0x02, SIZE_PACKET, 0x00, 0x00, };

static char bosDescriptor[] = { 0x05, 0x0F, 0x05, 0x00, 0x00 }; 

static uint8_t stringdescriptor0[] = { 0x04, 0x03, 0x09, 0x04 };
static uint8_t stringdescriptor1[] = { 0x0E, 0x03, 
									   'v', 0,
									   'e', 0,
									   'n', 0,
									   'd', 0,
									   'o', 0,
									   'r', 0 };
static uint8_t stringdescriptor2[] = { 0x10, 0x03, 
									   'p', 0,
									   'r', 0,
									   'o', 0,
									   'd', 0,
									   'u', 0,
									   'c', 0,
									   't', 0 };
static uint8_t stringdescriptor3[] = { 0x22, 0x03,
									   '1', 0,
									   '2', 0,
									   '3', 0,
									   '4', 0,
									   '5', 0,
									   '6', 0,
									   '7', 0,
									   '8', 0,
									   '9', 0,
									   '0', 0,
									   '1', 0,
									   '2', 0,
									   '3', 0,
									   '4', 0,
									   '5', 0,
									   '6', 0 };

static bool pollUSB();

static
uint32_t writeUSB(const void *pData, uint32_t length ) {

    UsbDeviceDescriptor *d = endpoint;

	if ( length > 0 ) 
		memcpy( outputbuffer, pData, length );

    d->DeviceDescBank[1].ADDR.reg = (uint32_t)outputbuffer;
    d->DeviceDescBank[1].PCKSIZE.bit.BYTE_COUNT = length;
    d->DeviceDescBank[1].PCKSIZE.bit.MULTI_PACKET_SIZE = 0;
    USB->DEVICE.DeviceEndpoint[0].EPINTFLAG.reg = USB_DEVICE_EPINTFLAG_TRCPT1;
    USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK1RDY;

    while (!(USB->DEVICE.DeviceEndpoint[0].EPINTFLAG.reg & USB_DEVICE_EPINTFLAG_TRCPT1)) {
//         if (endpoint && !pollUSB())
//            return -1;
    }

    return length;
}

static
bool pollUSB() {
    if (USB->DEVICE.INTFLAG.reg & USB_DEVICE_INTFLAG_EORST) {
        USB->DEVICE.INTFLAG.reg = USB_DEVICE_INTFLAG_EORST;
        USB->DEVICE.DADD.reg = USB_DEVICE_DADD_ADDEN | 0;
        USB->DEVICE.DeviceEndpoint[0].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE0(1) | USB_DEVICE_EPCFG_EPTYPE1(1);
        USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK0RDY;
        USB->DEVICE.DeviceEndpoint[0].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK1RDY;
        endpoint[0].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
        endpoint[0].DeviceDescBank[0].ADDR.reg = (uint32_t)control_packet;
        endpoint[0].DeviceDescBank[0].PCKSIZE.bit.MULTI_PACKET_SIZE = 8;
        endpoint[0].DeviceDescBank[0].PCKSIZE.bit.BYTE_COUNT = 0;
        endpoint[0].DeviceDescBank[1].PCKSIZE.bit.SIZE = 3;
        endpoint[0].DeviceDescBank[1].ADDR.reg = (uint32_t)outputbuffer;
        USB->DEVICE.DeviceEndpoint[0].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK0RDY;
        usb_active_config = 0;
    } else if (USB->DEVICE.DeviceEndpoint[0].EPINTFLAG.reg & USB_DEVICE_EPINTFLAG_RXSTP) {
		unsigned int request;
		bool direction;
		unsigned int idx;
		unsigned int request_value;
		unsigned int request_length;

		USB->DEVICE.DeviceEndpoint[0].EPINTFLAG.reg = USB_DEVICE_EPINTFLAG_RXSTP;

		request = control_packet[0] | ( control_packet[1] << 8 );
		request_value = control_packet[2] | ( control_packet[3] << 8 );
		idx = control_packet[4] | ( control_packet[5] << 8 );
		request_length = control_packet[6] | ( control_packet[7] << 8 );

		direction = idx & 0x80;
		idx = idx & 0x7F;

		USB->DEVICE.DeviceEndpoint[0].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK0RDY;

		switch ( request ) {
		case USB_REQUEST_GET_STATUS_ZERO:
			outputbuffer[0] = 0;
			outputbuffer[1] = 0;
			writeUSB(outputbuffer, MIN( request_length, 2) );
			break;
		case USB_REQUEST_GET_STATUS_INTERFACE:
			outputbuffer[0] = 0;
			outputbuffer[1] = 0;
			writeUSB(outputbuffer, MIN( request_length, 2) );
			break;
		case USB_REQUEST_GET_STATUS_ENDPOINT:
			outputbuffer[0] = 0;
			outputbuffer[1] = 0;
			if (idx < 4 ) {
				if (direction) 
					outputbuffer[0] = (USB->DEVICE.DeviceEndpoint[idx].EPSTATUS.reg & USB_DEVICE_EPSTATUSSET_STALLRQ1) ? 1 : 0;
				else
					outputbuffer[0] = (USB->DEVICE.DeviceEndpoint[idx].EPSTATUS.reg & USB_DEVICE_EPSTATUSSET_STALLRQ0) ? 1 : 0;
				writeUSB(outputbuffer, MIN( request_length, 2) );
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_CLEAR_FEATURE_INTERFACE:
			writeUSB(NULL, 0 );
			break;
		case USB_REQUEST_CLEAR_FEATURE_ENDPOINT:
			if ((request_value == 0) && idx && (idx < 4 )) {
				if (direction) {
					if (USB->DEVICE.DeviceEndpoint[idx].EPSTATUS.reg & USB_DEVICE_EPSTATUSSET_STALLRQ1) {
						USB->DEVICE.DeviceEndpoint[idx].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_STALLRQ1;
						if (USB->DEVICE.DeviceEndpoint[idx].EPINTFLAG.reg & USB_DEVICE_EPINTFLAG_STALL1) {
							USB->DEVICE.DeviceEndpoint[idx].EPINTFLAG.reg = USB_DEVICE_EPINTFLAG_STALL1;
							USB->DEVICE.DeviceEndpoint[idx].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSSET_DTGLIN;
						}
					}
				} else {
					if (USB->DEVICE.DeviceEndpoint[idx].EPSTATUS.reg & USB_DEVICE_EPSTATUSSET_STALLRQ0) {
						USB->DEVICE.DeviceEndpoint[idx].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_STALLRQ0;
						if (USB->DEVICE.DeviceEndpoint[idx].EPINTFLAG.reg & USB_DEVICE_EPINTFLAG_STALL0) {
							USB->DEVICE.DeviceEndpoint[idx].EPINTFLAG.reg = USB_DEVICE_EPINTFLAG_STALL0;
							USB->DEVICE.DeviceEndpoint[idx].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSSET_DTGLOUT;
						}
					}
				}
				writeUSB(NULL, 0 );
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_SET_FEATURE_INTERFACE:
			writeUSB(NULL, 0 );
			break;
		case USB_REQUEST_SET_FEATURE_ENDPOINT:
			if ((request_value == 0) && idx && (idx < 4)) {
				if (direction) 
					USB->DEVICE.DeviceEndpoint[idx].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
				else
					USB->DEVICE.DeviceEndpoint[idx].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ0;
				writeUSB(NULL, 0 );
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_SET_ADDRESS:
			writeUSB(NULL, 0 );
			USB->DEVICE.DADD.reg = USB_DEVICE_DADD_ADDEN | request_value;
			break;
		case USB_REQUEST_GET_DESCRIPTOR:
		case USB_REQUEST_GET_DESCRIPTOR1:
			if (request_value == 0x100) writeUSB(devDescriptor, MIN(request_length,sizeof(devDescriptor)) );
			else if (request_value == 0x200) writeUSB(cfgDescriptor, MIN(request_length,sizeof(cfgDescriptor)) );
			else if ( request_value == 0x300 ) writeUSB( stringdescriptor0, MIN(request_length, stringdescriptor0[0] ) );
			else if ( request_value == 0x301 ) writeUSB( stringdescriptor1, MIN(request_length, stringdescriptor1[0] ) );
			else if ( request_value == 0x302 ) writeUSB( stringdescriptor2, MIN(request_length, stringdescriptor2[0] ) );
			else if ( request_value == 0x303 ) writeUSB( stringdescriptor3, MIN(request_length, stringdescriptor3[0] ) );
			else if ( request_value == 0xF00 ) writeUSB(bosDescriptor, MIN(request_length,sizeof(bosDescriptor)) );
			else USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			break;
		case USB_REQUEST_GET_CONFIGURATION:
			writeUSB(&(usb_active_config), MIN( request_length, sizeof(usb_active_config)) );
			break;
		case USB_REQUEST_SET_CONFIGURATION:
			usb_active_config = (uint8_t)request_value;
			writeUSB(NULL, 0 );

			USB->DEVICE.DeviceEndpoint[ USB_EP_OUT ].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE0(3);
			endpoint[ USB_EP_OUT ].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
			USB->DEVICE.DeviceEndpoint[ USB_EP_OUT ].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK0RDY;
			endpoint[ USB_EP_OUT ].DeviceDescBank[0].ADDR.reg = (uint32_t)outputbuffer;

			USB->DEVICE.DeviceEndpoint[ USB_EP_IN ].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE1(3);
			endpoint[ USB_EP_IN ].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
			USB->DEVICE.DeviceEndpoint[ USB_EP_IN ].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK1RDY;
			endpoint[ USB_EP_IN ].DeviceDescBank[0].ADDR.reg = (uint32_t)inputbuffer;

			USB->DEVICE.DeviceEndpoint[USB_EP_COMM].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE1(4);
			endpoint[USB_EP_COMM].DeviceDescBank[1].PCKSIZE.bit.SIZE = 0;
			USB->DEVICE.DeviceEndpoint[USB_EP_COMM].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK1RDY;
			break;
		case USB_REQUEST_GET_LINE_CODING:
			writeUSB(line_config, MIN(request_length,sizeof(line_config)) );
			break;
		case USB_REQUEST_SET_LINE_CODING:
			writeUSB(NULL, 0 );
			break;
		case USB_REQUEST_SET_CONTROL_LINE_STATE:
			writeUSB(NULL, 0 );
			break;
		default:
			USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			break;
		}
	}

    return usb_active_config != 0;
}

static
ior_t usbhack_open( const char* name, unsigned int mode, FileReference_t* priv ) {
	return IOR_OK;
}

static
ior_t usbhack_create( const char* name, unsigned int mode, FileReference_t* priv ) {
	return IOR_UNKNOWN;
}

static
ior_t usbhack_close( FileReference_t* priv ) {
	return IOR_OK;
}

static
ior_t usbhack_read( FileReference_t* priv, void* buffer, unsigned int length ) {
	return IOR_OK;
}

static
ior_t usbhack_write( FileReference_t* priv, void* buffer, unsigned int length ) {
	return IOR_OK;
}

static ior_t usbhack_position( FileReference_t* priv, unsigned long long int* position ) {
	return IOR_UNKNOWN;
}

static ior_t usbhack_size( FileReference_t* priv, unsigned long long int* size ) {
	size[0] = pollUSB();
	return IOR_OK;
}

static ior_t usbhack_seek( FileReference_t* priv, unsigned long int pos ) {
	static int count = 0;	
	uint32_t v = (pos & 0xFFFFFFFF);
	if ( count == 0 ) {
		endpoint = (UsbDeviceDescriptor*)v;
	}
	else if ( count == 1 ) {	
		outputbuffer = (unsigned char*)v;
	}
	else if ( count == 2 ) {	
		inputbuffer = (unsigned char*)v;
	}
	else if ( count == 3 ) {	
		control_packet = (unsigned char*)v;
	}
	count++;
	return IOR_OK;
}

ioSubsystem io_usbhack = {	NULL,
							"usbhack",
							usbhack_open,
							usbhack_create,
							usbhack_close,
							usbhack_read,
							usbhack_write,
							usbhack_position,
							usbhack_size,
							usbhack_seek };

/* ************************************************************************** *
 *
 * ************************************************************************** */


int platform_init( void ) {
	ioRegister( &io_usbhack );
	return 0;
}

void platform_term( void ) {
}

void platform_write_term( char c ) {
}

int platform_read_term( void ) {
	return -1;
}

/* ************************************************************************** *
 *
 * ************************************************************************** */

extern uint32_t __etext;
extern uint32_t __data_start__;
extern uint32_t __data_end__;
extern uint32_t __bss_start__;
extern uint32_t __bss_end__;
extern uint32_t __StackTop;

extern int main( int argc, char** argv );

void Reset_Handler(void) {
	uint32_t *pSrc, *pDest;

  	pSrc = &__etext;
  	pDest = &__data_start__;

  	if ((&__data_start__ != &__data_end__) && (pSrc != pDest)) {
    	for (; pDest < &__data_end__; pDest++, pSrc++)
      		*pDest = *pSrc;
  	}

  	if ((&__data_start__ != &__data_end__) && (pSrc != pDest)) {
    	for (pDest = &__bss_start__; pDest < &__bss_end__; pDest++)
      		*pDest = 0;
  	}
	main( 1, NULL );
}

/* ************************************************************************** *
 *
 * ************************************************************************** */

typedef void(*vfunc)(void);

__attribute__ ((section(".isr_vector"))) vfunc const exception_table[]  = {
	(vfunc)(&__StackTop), Reset_Handler, hacf, hacf, hacf, hacf,
	hacf, NULL, NULL, NULL, NULL, hacf, hacf, NULL, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, NULL, hacf, hacf, hacf, hacf, hacf,
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, NULL, NULL, hacf, hacf, hacf, hacf, NULL, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf,
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf };

