#define ENABLE_USB	

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

//#define WAIT 500000
#define WAIT 100000

static void wait( int l ) { for ( int i = 0; i < (l*WAIT); i++ ) i = i; }
static void dot( void ) { LEDoff(); wait(1); LEDon(); wait(1); LEDoff(); wait(1); }
static void dash( void ) { LEDoff(); wait(1); LEDon(); wait(3); LEDoff(); wait(1); }
static void hacf( void ) { for(;;) { wait(6); dot(); dot(); dot(); dash(); dash(); dash(); dot(); dot(); dot(); } }

/* ************************************************************************** *
 *
 * ************************************************************************** */
#ifdef ENABLE_USB

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

    GCLK->PCHCTRL[USB_GCLK_ID].reg = GCLK_PCHCTRL_GEN_GCLK1_Val | (1 << GCLK_PCHCTRL_CHEN_Pos);
    MCLK->AHBMASK.bit.USB_ = true;
    MCLK->APBBMASK.bit.USB_ = true;

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

#endif
/* ************************************************************************** *
 *
 * ************************************************************************** */
#ifdef NATIVE_CLOCK_INIT

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
                           OSCCTRL_DFLLMUL_MUL( 0 );

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

void genericClock( uint32_t which ) {
    GCLK->GENCTRL[0].reg =
        GCLK_GENCTRL_SRC(which) |
                         GCLK_GENCTRL_IDC |
                         GCLK_GENCTRL_OE |
                         GCLK_GENCTRL_GENEN;

    while (GCLK->SYNCBUSY.bit.GENCTRL0) 
		;
}

void clock1_48Mhz( void ) {
	GCLK->GENCTRL[1].reg = GCLK_GENCTRL_SRC(GCLK_GENCTRL_SRC_DFLL_Val) | GCLK_GENCTRL_GENEN;

    while (GCLK->SYNCBUSY.bit.GENCTRL1) 
		;
}

void clock5_1Mhz( void ) {
	GCLK->GENCTRL[5].reg = GCLK_GENCTRL_SRC(GCLK_GENCTRL_SRC_DFLL_Val) | GCLK_GENCTRL_GENEN | GCLK_GENCTRL_DIV(48u);
  	while ( GCLK->SYNCBUSY.bit.GENCTRL5 )
		;
}

void pll0_120Mhz( void ) {
	GCLK->PCHCTRL[OSCCTRL_GCLK_ID_FDPLL0].reg = (1 << GCLK_PCHCTRL_CHEN_Pos) | GCLK_PCHCTRL_GEN(GCLK_PCHCTRL_GEN_GCLK5_Val);
	OSCCTRL->Dpll[0].DPLLRATIO.reg = OSCCTRL_DPLLRATIO_LDRFRAC(0x00) | OSCCTRL_DPLLRATIO_LDR(119); //120 Mhz
	while(OSCCTRL->Dpll[0].DPLLSYNCBUSY.bit.DPLLRATIO)
		;
	OSCCTRL->Dpll[0].DPLLCTRLB.reg = OSCCTRL_DPLLCTRLB_REFCLK_GCLK | OSCCTRL_DPLLCTRLB_LBYPASS;
	OSCCTRL->Dpll[0].DPLLCTRLA.reg = OSCCTRL_DPLLCTRLA_ENABLE;
	while( OSCCTRL->Dpll[0].DPLLSTATUS.bit.CLKRDY == 0 || OSCCTRL->Dpll[0].DPLLSTATUS.bit.LOCK == 0 )
		;
}

void pll1_100Mhz( void ) {
	GCLK->PCHCTRL[OSCCTRL_GCLK_ID_FDPLL1].reg = (1 << GCLK_PCHCTRL_CHEN_Pos) | GCLK_PCHCTRL_GEN(GCLK_PCHCTRL_GEN_GCLK5_Val);
	OSCCTRL->Dpll[1].DPLLRATIO.reg = OSCCTRL_DPLLRATIO_LDRFRAC(0x00) | OSCCTRL_DPLLRATIO_LDR(99); 
	while(OSCCTRL->Dpll[1].DPLLSYNCBUSY.bit.DPLLRATIO)
		;
	OSCCTRL->Dpll[1].DPLLCTRLB.reg = OSCCTRL_DPLLCTRLB_REFCLK_GCLK | OSCCTRL_DPLLCTRLB_LBYPASS;
	OSCCTRL->Dpll[1].DPLLCTRLA.reg = OSCCTRL_DPLLCTRLA_ENABLE;
	while( OSCCTRL->Dpll[1].DPLLSTATUS.bit.CLKRDY == 0 || OSCCTRL->Dpll[1].DPLLSTATUS.bit.LOCK == 0 )
		;
}

#endif
/* ************************************************************************** *
 *
 * ************************************************************************** */

static bool terminal_ready;

int platform_init( void ) {

	terminal_ready = false;
#ifdef NATIVE_CLOCK_INIT
	gclkReset();
	internalOscForCPUClock();
	configureDFLL();
	clock5_1Mhz();
	clock1_48Mhz();
	pll0_120Mhz();
	pll1_100Mhz();
	genericClock( GCLK_GENCTRL_SRC_DPLL0 );
	MCLK->CPUDIV.reg = MCLK_CPUDIV_DIV_DIV1;

	SUPC->VREG.bit.SEL = 0; 	// LDO reg

	// CACHE
	__disable_irq();
	CMCC->CTRL.reg = 1;
	__enable_irq();
#endif

	return 0;
}

void platform_term( void ) {
}

#ifdef ENABLE_USB
static char preboot_io[1024];
static int pbi = 0;
#endif

void platform_write_term( char c ) {
#ifdef ENABLE_USB
	if ( !terminal_ready ) {
		preboot_io[pbi++] = c;
		return;
	}

	if ( pollUSB() ) {
		if ( c == '\n' ) {
			c = 13;
			writeUSB( &c, 1, USB_EP_IN );
			c = 10;
		}
		writeUSB( &c, 1, USB_EP_IN );
	}
#endif
}

int platform_read_term( void ) {
#ifdef ENABLE_USB
	int c;
	static int ignore_next_10 = 0;

	if ( !terminal_ready ) {

		initUSB();
		terminal_ready = true;

		LEDon();
reloop:
		int crap = platform_read_term();
		if ( crap < 0 ) goto reloop;

		for ( int i = 0; i < pbi; i++ ) platform_write_term( preboot_io[i] );
		return crap;
	}

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
#else
	return -1;
#endif
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

