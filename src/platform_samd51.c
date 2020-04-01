
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sam.h>
#include "platform.h"

/* ************************************************************************** *
 *
 * ************************************************************************** */

#define ALIGNED __attribute__((aligned(4)));
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

static void LEDtoggle( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTTGL.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTTGL.reg |= ( 1 << 15 );
}

static void wait( int l ) { for ( int i = 0; i < (l*500000); i++ ) i = i; }
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

static UsbDeviceDescriptor endpoints[4] ALIGNED;
static uint8_t usb_active_config;
static uint8_t control_packet[ SIZE_PACKET ] ALIGNED;
static unsigned char outputbuffer[256] ALIGNED;
static unsigned char inputbuffer[256] ALIGNED;
static int num_chars = 0;
static bool wait_for_input = false;

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

int readUSB( void ) {
	int rc;

    UsbDeviceDescriptor *d = (UsbDeviceDescriptor *)USB->HOST.DESCADD.reg + USB_EP_OUT;

	if ( num_chars ) {
		rc = inputbuffer[0];
		num_chars--;
		memmove( inputbuffer, inputbuffer+1, num_chars );
	} else if ( wait_for_input == false ) {
        d->DeviceDescBank[0].ADDR.reg = (uint32_t)inputbuffer;
        d->DeviceDescBank[0].PCKSIZE.bit.BYTE_COUNT = 0;
        d->DeviceDescBank[0].PCKSIZE.bit.MULTI_PACKET_SIZE = 0;
        USB->DEVICE.DeviceEndpoint[USB_EP_OUT].EPSTATUSCLR.bit.BK0RDY = true;
        wait_for_input = true;	
		rc = -1;
    } else if (USB->DEVICE.DeviceEndpoint[USB_EP_OUT].EPINTFLAG.reg & USB_DEVICE_EPINTFLAG_TRCPT0) {
		num_chars = d->DeviceDescBank[0].PCKSIZE.bit.BYTE_COUNT;
        USB->DEVICE.DeviceEndpoint[USB_EP_OUT].EPINTFLAG.reg = USB_DEVICE_EPINTFLAG_TRCPT0;
		wait_for_input = false;
		rc = -1;
    } else {
		rc = -1;
	}

    return rc;
}

static
uint32_t writeUSB(const void *pData, uint32_t length, uint8_t endpoint ) {

    UsbDeviceDescriptor *d = (UsbDeviceDescriptor *)USB->HOST.DESCADD.reg + endpoint;

	if ( length > sizeof(outputbuffer) ) hacf();
	if ( length > 0 ) 
		memcpy( outputbuffer, pData, length );

    d->DeviceDescBank[1].ADDR.reg = (uint32_t)outputbuffer;
    d->DeviceDescBank[1].PCKSIZE.bit.BYTE_COUNT = length;
    d->DeviceDescBank[1].PCKSIZE.bit.MULTI_PACKET_SIZE = 0;
    USB->DEVICE.DeviceEndpoint[endpoint].EPINTFLAG.reg = USB_DEVICE_EPINTFLAG_TRCPT1;
    USB->DEVICE.DeviceEndpoint[endpoint].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK1RDY;

    while (!(USB->DEVICE.DeviceEndpoint[endpoint].EPINTFLAG.reg & USB_DEVICE_EPINTFLAG_TRCPT1)) {
         if (endpoint && !pollUSB())
            return -1;
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
        endpoints[0].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
        endpoints[0].DeviceDescBank[0].ADDR.reg = (uint32_t)control_packet;
        endpoints[0].DeviceDescBank[0].PCKSIZE.bit.MULTI_PACKET_SIZE = 8;
        endpoints[0].DeviceDescBank[0].PCKSIZE.bit.BYTE_COUNT = 0;
        endpoints[0].DeviceDescBank[1].PCKSIZE.bit.SIZE = 3;
        endpoints[0].DeviceDescBank[1].ADDR.reg = (uint32_t)outputbuffer;
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
			writeUSB(outputbuffer, MIN( request_length, 2), USB_EP_COMM_IN );
			break;
		case USB_REQUEST_GET_STATUS_INTERFACE:
			outputbuffer[0] = 0;
			outputbuffer[1] = 0;
			writeUSB(outputbuffer, MIN( request_length, 2), USB_EP_COMM_IN );
			break;
		case USB_REQUEST_GET_STATUS_ENDPOINT:
			outputbuffer[0] = 0;
			outputbuffer[1] = 0;
			if (idx < 4 ) {
				if (direction) 
					outputbuffer[0] = (USB->DEVICE.DeviceEndpoint[idx].EPSTATUS.reg & USB_DEVICE_EPSTATUSSET_STALLRQ1) ? 1 : 0;
				else
					outputbuffer[0] = (USB->DEVICE.DeviceEndpoint[idx].EPSTATUS.reg & USB_DEVICE_EPSTATUSSET_STALLRQ0) ? 1 : 0;
				writeUSB(outputbuffer, MIN( request_length, 2), USB_EP_COMM_IN );
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_CLEAR_FEATURE_INTERFACE:
			writeUSB(NULL, 0, 0);
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
				writeUSB(NULL, 0, 0);
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_SET_FEATURE_INTERFACE:
			writeUSB(NULL, 0, 0);
			break;
		case USB_REQUEST_SET_FEATURE_ENDPOINT:
			if ((request_value == 0) && idx && (idx < 4)) {
				if (direction) 
					USB->DEVICE.DeviceEndpoint[idx].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
				else
					USB->DEVICE.DeviceEndpoint[idx].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ0;
				writeUSB(NULL, 0, 0);
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_SET_ADDRESS:
			writeUSB(NULL, 0, 0);
			USB->DEVICE.DADD.reg = USB_DEVICE_DADD_ADDEN | request_value;
			break;
		case USB_REQUEST_GET_DESCRIPTOR:
		case USB_REQUEST_GET_DESCRIPTOR1:
			if (request_value == 0x100) writeUSB(devDescriptor, MIN(request_length,sizeof(devDescriptor)), USB_EP_COMM_IN );
			else if (request_value == 0x200) writeUSB(cfgDescriptor, MIN(request_length,sizeof(cfgDescriptor)), USB_EP_COMM_IN );
			else if ( request_value == 0x300 ) writeUSB( stringdescriptor0, MIN(request_length, stringdescriptor0[0] ), USB_EP_COMM_IN );
			else if ( request_value == 0x301 ) writeUSB( stringdescriptor1, MIN(request_length, stringdescriptor1[0] ), USB_EP_COMM_IN );
			else if ( request_value == 0x302 ) writeUSB( stringdescriptor2, MIN(request_length, stringdescriptor2[0] ), USB_EP_COMM_IN );
			else if ( request_value == 0x303 ) writeUSB( stringdescriptor3, MIN(request_length, stringdescriptor3[0] ), USB_EP_COMM_IN );
			else if ( request_value == 0xF00 ) writeUSB(bosDescriptor, MIN(request_length,sizeof(bosDescriptor)), USB_EP_COMM_IN );
			else USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			break;
		case USB_REQUEST_GET_CONFIGURATION:
			writeUSB(&(usb_active_config), MIN( request_length, sizeof(usb_active_config)), USB_EP_COMM_IN );
			break;
		case USB_REQUEST_SET_CONFIGURATION:
			usb_active_config = (uint8_t)request_value;
			writeUSB(NULL, 0, 0);

			USB->DEVICE.DeviceEndpoint[ USB_EP_OUT ].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE0(3);
			endpoints[ USB_EP_OUT ].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
			USB->DEVICE.DeviceEndpoint[ USB_EP_OUT ].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK0RDY;
			endpoints[ USB_EP_OUT ].DeviceDescBank[0].ADDR.reg = (uint32_t)outputbuffer;

			USB->DEVICE.DeviceEndpoint[ USB_EP_IN ].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE1(3);
			endpoints[ USB_EP_IN ].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
			USB->DEVICE.DeviceEndpoint[ USB_EP_IN ].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK1RDY;
			endpoints[ USB_EP_IN ].DeviceDescBank[0].ADDR.reg = (uint32_t)inputbuffer;

			USB->DEVICE.DeviceEndpoint[USB_EP_COMM].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE1(4);
			endpoints[USB_EP_COMM].DeviceDescBank[1].PCKSIZE.bit.SIZE = 0;
			USB->DEVICE.DeviceEndpoint[USB_EP_COMM].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK1RDY;
			break;
		case USB_REQUEST_GET_LINE_CODING:
			writeUSB(line_config, MIN(request_length,sizeof(line_config)), USB_EP_COMM_IN );
			break;
		case USB_REQUEST_SET_LINE_CODING:
			writeUSB(NULL, 0, 0);
			break;
		case USB_REQUEST_SET_CONTROL_LINE_STATE:
			writeUSB(NULL, 0, 0);
			break;
		default:
			USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			break;
		}
	}

    return usb_active_config != 0;
}

static 
void nvmctrlGetSoftCalUSB( uint32_t* tn, uint32_t* tp, uint32_t* pd ) {
    tn[0] = ((*((uint32_t*) USB_FUSES_TRANSN_ADDR)) & USB_FUSES_TRANSN_Msk) >> USB_FUSES_TRANSN_Pos;
	if ( tn[0] == 0x1F ) tn[0] = 0x09;
    tp[0] = ((*((uint32_t*) USB_FUSES_TRANSP_ADDR)) & USB_FUSES_TRANSP_Msk) >> USB_FUSES_TRANSP_Pos;
	if ( tp[0] == 0x1F ) tp[0] = 0x19;
    pd[0] = ((*((uint32_t*) USB_FUSES_TRIM_ADDR)) & USB_FUSES_TRIM_Msk) >> USB_FUSES_TRIM_Pos;
	if ( pd[0] == 0x07 ) pd[0] = 0x06;
}

static
void initPINS( unsigned int m_pin, unsigned int m_mux, unsigned int p_pin, unsigned int p_mux ) {
	uint32_t v;

    PORT->Group[0].PINCFG[m_pin].bit.PMUXEN = 1;
	v = PORT->Group[0].PMUX[m_pin>>1].reg & ~(0xF << ((m_pin&1)<<2));
	v |= ( m_mux << ((m_pin&1)<<2) );
    PORT->Group[0].PMUX[m_pin>>1].reg = v;

    PORT->Group[0].PINCFG[p_pin].bit.PMUXEN = 1;
	v = PORT->Group[0].PMUX[p_pin>>1].reg & ~(0xF << ((p_pin&1)<<2));
	v |= ( p_mux << ((p_pin&1)<<2) );
    PORT->Group[0].PMUX[p_pin>>1].reg = v;
}

static
void initUSB( void ) {

	initPINS( PIN_PA24H_USB_DM, MUX_PA24H_USB_DM, PIN_PA25H_USB_DP, MUX_PA25H_USB_DP );

    GCLK->PCHCTRL[USB_GCLK_ID].reg = GCLK_PCHCTRL_GEN_GCLK0_Val | (1 << GCLK_PCHCTRL_CHEN_Pos);
    MCLK->AHBMASK.bit.USB_ = true;
    MCLK->APBBMASK.bit.USB_ = true;
    while(GCLK->SYNCBUSY.bit.GENCTRL0)
		;

    USB->HOST.CTRLA.bit.SWRST = 1;
    while (USB->HOST.SYNCBUSY.bit.SWRST) 
		;

	uint32_t tn;
	uint32_t tp;
	uint32_t pd;
	nvmctrlGetSoftCalUSB( &tn, &tp, &pd );
    USB->HOST.PADCAL.bit.TRANSN = tn;
    USB->HOST.PADCAL.bit.TRANSP = tp;
    USB->HOST.PADCAL.bit.TRIM = pd;

    USB->HOST.CTRLA.bit.MODE = 0;
    USB->HOST.CTRLA.bit.RUNSTDBY = true;
    USB->HOST.DESCADD.reg = (uint32_t)(&endpoints[0]);
    USB->DEVICE.CTRLB.bit.SPDCONF = USB_DEVICE_CTRLB_SPDCONF_FS_Val;
    USB->DEVICE.CTRLB.reg &= ~USB_DEVICE_CTRLB_DETACH;

    memset((uint8_t *)(endpoints), 0, sizeof(endpoints));
    usb_active_config = 0;
 	USB->HOST.CTRLA.bit.ENABLE = true;
}

/* ************************************************************************** *
 *
 * ************************************************************************** */

void gclkReset( void ) {
   GCLK->CTRLA.bit.SWRST = 1;
   while (GCLK->SYNCBUSY.bit.SWRST) 
		;
}

void internalOscForCPUClock( void ) {
    GCLK->GENCTRL[0].reg = GCLK_GENCTRL_SRC(GCLK_GENCTRL_SRC_OSCULP32K) |
                           GCLK_GENCTRL_OE |
                           GCLK_GENCTRL_GENEN;
    while (GCLK->SYNCBUSY.bit.GENCTRL0) 
		;
}

void configureDFLL( void ) {
    OSCCTRL->DFLLCTRLA.reg = 0;

    OSCCTRL->DFLLMUL.reg = OSCCTRL_DFLLMUL_CSTEP( 0x1 ) |
                           OSCCTRL_DFLLMUL_FSTEP( 0x1 ) |
                           OSCCTRL_DFLLMUL_MUL( 0xBB80 );

    while (OSCCTRL->DFLLSYNC.bit.DFLLMUL) 
		;

    OSCCTRL->DFLLCTRLB.reg = 0;
    while (OSCCTRL->DFLLSYNC.bit.DFLLCTRLB) 
		;

    OSCCTRL->DFLLCTRLA.bit.ENABLE = true;
    while (OSCCTRL->DFLLSYNC.bit.ENABLE) 
		;

    OSCCTRL->DFLLVAL.reg = OSCCTRL->DFLLVAL.reg;
    while(OSCCTRL->DFLLSYNC.bit.DFLLVAL ) 
		;

    OSCCTRL->DFLLCTRLB.reg = OSCCTRL_DFLLCTRLB_WAITLOCK |
    OSCCTRL_DFLLCTRLB_CCDIS | OSCCTRL_DFLLCTRLB_USBCRM ;

    while (!OSCCTRL->STATUS.bit.DFLLRDY) 
		;
}

void genericClockToDFLL( void ) {
    GCLK->GENCTRL[0].reg =
        GCLK_GENCTRL_SRC(GCLK_GENCTRL_SRC_DFLL) |
                         GCLK_GENCTRL_IDC |
                         GCLK_GENCTRL_OE |
                         GCLK_GENCTRL_GENEN;

    while (GCLK->SYNCBUSY.bit.GENCTRL0) 
		;
}

/* ************************************************************************** *
 *
 * ************************************************************************** */

int platform_init( void ) {
	/* Flash: 1 wait state */
    NVMCTRL->CTRLA.reg |= NVMCTRL_CTRLA_RWS(0);

	gclkReset();
	internalOscForCPUClock();
	configureDFLL();
	genericClockToDFLL();

    MCLK->CPUDIV.reg = MCLK_CPUDIV_DIV_DIV1;

	initUSB();
	return 0;
}

void platform_term( void ) {
}

int platform_read_term( void ) {
	int c;
	static int ignore_next_10 = 0;

	if ( !pollUSB() ) return -1;

	c = readUSB();
	if ( c >= 0 ) {
		if ( ( c == 10 ) && ( ignore_next_10 ) ) {
			ignore_next_10 = 1;
			return platform_read_term();
		}

		if ( c == 13 ) {
			c = 10;
			ignore_next_10 = 1;
		}
	}

	return c;
}

void platform_write_term( char c ) {
	if ( pollUSB() ) {
		if ( c == '\n' ) {
			c = 13;
			writeUSB( &c, 1, USB_EP_IN );
			c = 10;
		}
		writeUSB( &c, 1, USB_EP_IN );
	}
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

extern "C" int main( int argc, char** argv );

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

static void isr_NMI( void ) { }
static void isr_HardFault( void ) { }
static void isr_MemManage( void ) { }
static void isr_BusFault( void ) { }
static void isr_UsageFault( void ) { }
static void isr_SVC( void ) { }
static void isr_DebugMon( void ) { }
static void isr_PendSV( void ) { }
static void isr_SysTick( void ) { }
static void isr_PM( void ) { }
static void isr_MCLK( void ) { }
static void isr_OSCCTRL_0( void ) { }
static void isr_OSCCTRL_1( void ) { }
static void isr_OSCCTRL_2( void ) { }
static void isr_OSCCTRL_3( void ) { }
static void isr_OSCCTRL_4( void ) { }
static void isr_OSC32KCTRL( void ) { }
static void isr_SUPC_0( void ) { }
static void isr_SUPC_1( void ) { }
static void isr_WDT( void ) { }
static void isr_RTC( void ) { }
static void isr_EIC_0( void ) { }
static void isr_EIC_1( void ) { }
static void isr_EIC_2( void ) { }
static void isr_EIC_3( void ) { }
static void isr_EIC_4( void ) { }
static void isr_EIC_5( void ) { }
static void isr_EIC_6( void ) { }
static void isr_EIC_7( void ) { }
static void isr_EIC_8( void ) { }
static void isr_EIC_9( void ) { }
static void isr_EIC_10( void ) { }
static void isr_EIC_11( void ) { }
static void isr_EIC_12( void ) { }
static void isr_EIC_13( void ) { }
static void isr_EIC_14( void ) { }
static void isr_EIC_15( void ) { }
static void isr_FREQM( void ) { }
static void isr_NVMCTRL_0( void ) { }
static void isr_NVMCTRL_1( void ) { }
static void isr_DMAC_0( void ) { }
static void isr_DMAC_1( void ) { }
static void isr_DMAC_2( void ) { }
static void isr_DMAC_3( void ) { }
static void isr_DMAC_4( void ) { }
static void isr_EVSYS_0( void ) { }
static void isr_EVSYS_1( void ) { }
static void isr_EVSYS_2( void ) { }
static void isr_EVSYS_3( void ) { }
static void isr_EVSYS_4( void ) { }
static void isr_PAC( void ) { }
static void isr_TAL_0( void ) { }
static void isr_TAL_1( void ) { }
static void isr_RAMECC( void ) { }
static void isr_SERCOM0_0( void ) { }
static void isr_SERCOM0_1( void ) { }
static void isr_SERCOM0_2( void ) { }
static void isr_SERCOM0_3( void ) { }
static void isr_SERCOM1_0( void ) { }
static void isr_SERCOM1_1( void ) { }
static void isr_SERCOM1_2( void ) { }
static void isr_SERCOM1_3( void ) { }
static void isr_SERCOM2_0( void ) { }
static void isr_SERCOM2_1( void ) { }
static void isr_SERCOM2_2( void ) { }
static void isr_SERCOM2_3( void ) { }
static void isr_SERCOM3_0( void ) { }
static void isr_SERCOM3_1( void ) { }
static void isr_SERCOM3_2( void ) { }
static void isr_SERCOM3_3( void ) { }
static void isr_SERCOM4_0( void ) { }
static void isr_SERCOM4_1( void ) { }
static void isr_SERCOM4_2( void ) { }
static void isr_SERCOM4_3( void ) { }
static void isr_SERCOM5_0( void ) { }
static void isr_SERCOM5_1( void ) { }
static void isr_SERCOM5_2( void ) { }
static void isr_SERCOM5_3( void ) { }
static void isr_SERCOM6_0( void ) { }
static void isr_SERCOM6_1( void ) { }
static void isr_SERCOM6_2( void ) { }
static void isr_SERCOM6_3( void ) { }
static void isr_SERCOM7_0( void ) { }
static void isr_SERCOM7_1( void ) { }
static void isr_SERCOM7_2( void ) { }
static void isr_SERCOM7_3( void ) { }
static void isr_USB_0( void ) { }
static void isr_USB_1( void ) { }
static void isr_USB_2( void ) { }
static void isr_USB_3( void ) { }
static void isr_TCC0_0( void ) { }
static void isr_TCC0_1( void ) { }
static void isr_TCC0_2( void ) { }
static void isr_TCC0_3( void ) { }
static void isr_TCC0_4( void ) { }
static void isr_TCC0_5( void ) { }
static void isr_TCC0_6( void ) { }
static void isr_TCC1_0( void ) { }
static void isr_TCC1_1( void ) { }
static void isr_TCC1_2( void ) { }
static void isr_TCC1_3( void ) { }
static void isr_TCC1_4( void ) { }
static void isr_TCC2_0( void ) { }
static void isr_TCC2_1( void ) { }
static void isr_TCC2_2( void ) { }
static void isr_TCC2_3( void ) { }
static void isr_TCC3_0( void ) { }
static void isr_TCC3_1( void ) { }
static void isr_TCC3_2( void ) { }
static void isr_TCC4_0( void )  { }
static void isr_TCC4_1( void )  { }
static void isr_TCC4_2( void )  { }
static void isr_TC0( void )  { }
static void isr_TC1( void )  { }
static void isr_TC2( void )  { }
static void isr_TC3( void )  { }
static void isr_TC4( void )  { }
static void isr_TC5( void )  { }
static void isr_TC6( void )  { }
static void isr_TC7( void )  { }
static void isr_PDEC_0( void )  { }
static void isr_PDEC_1( void )  { }
static void isr_PDEC_2( void )  { }
static void isr_ADC0_0( void )  { }
static void isr_ADC0_1( void )  { }
static void isr_ADC1_0( void )  { }
static void isr_ADC1_1( void )  { }
static void isr_AC( void )  { }
static void isr_DAC_0( void )  { }
static void isr_DAC_1( void )  { }
static void isr_DAC_2( void )  { }
static void isr_DAC_3( void )  { }
static void isr_DAC_4( void )  { }
static void isr_I2S( void )  { }
static void isr_PCC( void )  { }
static void isr_AES( void )  { }
static void isr_TRNG( void )  { }
static void isr_ICM( void )  { }
static void isr_PUKCC( void )  { }
static void isr_QSPI( void )  { }
static void isr_SDHC0( void )  { }
static void isr_SDHC1( void )  { }

typedef void(*vfunc)(void);

__attribute__ ((section(".isr_vector"))) vfunc const exception_table[]  = {
	(vfunc)(&__StackTop), Reset_Handler, isr_NMI, isr_HardFault, isr_MemManage, isr_BusFault,
	isr_UsageFault, NULL, NULL, NULL, NULL, isr_SVC, isr_DebugMon, NULL, isr_PendSV,
	isr_SysTick, isr_PM, isr_MCLK, isr_OSCCTRL_0, isr_OSCCTRL_1, isr_OSCCTRL_2, 
	isr_OSCCTRL_3, isr_OSCCTRL_4, isr_OSC32KCTRL, isr_SUPC_0, isr_SUPC_1, isr_WDT,
	isr_RTC, isr_EIC_0, isr_EIC_1, isr_EIC_2, isr_EIC_3, isr_EIC_4, isr_EIC_5,
	isr_EIC_6, isr_EIC_7, isr_EIC_8, isr_EIC_9, isr_EIC_10, isr_EIC_11, isr_EIC_12,
	isr_EIC_13, isr_EIC_14, isr_EIC_15, isr_FREQM, isr_NVMCTRL_0, isr_NVMCTRL_1, 
	isr_DMAC_0, isr_DMAC_1, isr_DMAC_2, isr_DMAC_3, isr_DMAC_4, isr_EVSYS_0,
	isr_EVSYS_1, isr_EVSYS_2, isr_EVSYS_3, isr_EVSYS_4, isr_PAC, isr_TAL_0, isr_TAL_1,
	NULL, isr_RAMECC, isr_SERCOM0_0, isr_SERCOM0_1, isr_SERCOM0_2, isr_SERCOM0_3,
	isr_SERCOM1_0, isr_SERCOM1_1, isr_SERCOM1_2, isr_SERCOM1_3, isr_SERCOM2_0,
	isr_SERCOM2_1, isr_SERCOM2_2, isr_SERCOM2_3, isr_SERCOM3_0, isr_SERCOM3_1,
	isr_SERCOM3_2, isr_SERCOM3_3, isr_SERCOM4_0, isr_SERCOM4_1, isr_SERCOM4_2,
	isr_SERCOM4_3, isr_SERCOM5_0, isr_SERCOM5_1, isr_SERCOM5_2, isr_SERCOM5_3,
	isr_SERCOM6_0, isr_SERCOM6_1, isr_SERCOM6_2, isr_SERCOM6_3, isr_SERCOM7_0,
	isr_SERCOM7_1, isr_SERCOM7_2, isr_SERCOM7_3, NULL, NULL, isr_USB_0, isr_USB_1,
	isr_USB_2, isr_USB_3, NULL, isr_TCC0_0, isr_TCC0_1, isr_TCC0_2, isr_TCC0_3,
	isr_TCC0_4, isr_TCC0_5, isr_TCC0_6, isr_TCC1_0, isr_TCC1_1, isr_TCC1_2, 
	isr_TCC1_3, isr_TCC1_4, isr_TCC2_0, isr_TCC2_1, isr_TCC2_2, isr_TCC2_3,
	isr_TCC3_0, isr_TCC3_1, isr_TCC3_2, isr_TCC4_0, isr_TCC4_1, isr_TCC4_2, isr_TC0,
	isr_TC1, isr_TC2, isr_TC3, isr_TC4, isr_TC5, isr_TC6, isr_TC7, isr_PDEC_0, 
	isr_PDEC_1, isr_PDEC_2, isr_ADC0_0, isr_ADC0_1, isr_ADC1_0, isr_ADC1_1,
	isr_AC, isr_DAC_0, isr_DAC_1, isr_DAC_2, isr_DAC_3, isr_DAC_4, isr_I2S,
	isr_PCC, isr_AES, isr_TRNG, isr_ICM, isr_PUKCC, isr_QSPI, isr_SDHC0, isr_SDHC1 };


