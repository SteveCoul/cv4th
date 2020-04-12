
require extra/register.fth
require kernel/structure.fth
require platform/atsamd51/gclk.fth
require platform/atsamd51/mclk.fth
require platform/atsamd51/gpio.fth

forth-wordlist ext-wordlist 2 set-order

: lcd lcd-clear 0 0 lcd-at-xy lcd-type lcd-update ;
: lcd2 0 1 lcd-at-xy lcd-type lcd-update ;
: lcd3 0 1 lcd-at-xy lcd-type lcd-update ;
: lcd4 0 1 lcd-at-xy lcd-type lcd-update ;
: wait  1000 * 0 do i drop loop ;
: ledon LED_BUILTIN OUTPUT pinMode LED_BUILTIN HIGH writeDigital ;
: ledoff LED_BUILTIN OUTPUT pinMode LED_BUILTIN LOW writeDigital ;
: dash 1 wait ledon 3 wait ledoff ;
: dot  1 wait ledon 1 wait ledoff ;
: HACF S" Burn baby Burn" lcd begin dot dot dot dash dash dash dot dot dot 6 wait again ;

0x41000000 register-bank UsbHost
	8bit register CTRLA
		1 bit swrst
		1 bit enable
		1 bit runstdby
		4 skip-bit
		1 bit mode
	end-register
	1 skip-byte
	8bit register SYNCBUSY
		1 bit swrst
		1 bit enable
	end-register
	8bit register QOSCTRL
		2 bit cqos
		2 bit dqos
	end-register
	4 skip-byte
	16bit register CTRLB
		1 skip-bit
		1 bit resume
		2 bit spdconf
		1 skip-bit
		1 bit tstj
		1 bit tstk
		1 skip-bit
		1 bit sofe
		1 bit busreset
		1 bit vbusok
		1 bit l1resume
	end-register
	8bit register HSOFC
		4 bit flenc
		3 skip-bit
		1 bit flence
	end-register
	1 skip-byte
	8bit register STATUS
		2 skip-bit
		2 bit speed
		2 skip-bit
		2 bit linestate
	end-register
	8bit register FSMSTATUS
	end-register
	2 skip-byte
	16bit register FNUM
		3 skip-bit
		11 bit fnum
	end-register
	8bit register FLENHIGH
	end-register
	1 skip-byte
	16bit register INTENCLR
		2 skip-bit
		1 bit hsof
		1 bit rst
		1 bit wakeup
		1 bit dnrsm
		1 bit uprsm
		1 bit ramacer
		1 bit dconn
		1 bit ddisc
	end-register
	2 skip-byte
	16bit register INTENSET
		2 skip-bit
		1 bit hsof
		1 bit rst
		1 bit wakeup
		1 bit dnrsm
		1 bit uprsm
		1 bit ramacer
		1 bit dconn
		1 bit ddisc
	end-register
	2 skip-byte
	16bit register INTFLAG
		2 skip-bit
		1 bit hsof
		1 bit rst
		1 bit wakeup
		1 bit dnrsm
		1 bit uprsm
		1 bit ramacer
		1 bit dconn
		1 bit ddisc
	end-register
	2 skip-byte
	16bit register PINTSMRY
	end-register
	2 skip-byte
	32bit register DESCADD
	end-register
	16bit register PADCAL
		5 bit transp
		1 skip-bit
		5 bit transn
		1 skip-bit
		3 bit trim
	end-register
	\ At this point there are 8 Host Pipe structures. I don't have the
	\ ability to embed structure definitions in register bank definitions
	\ and I don't need these anyhow atm.
end-register-bank

0x41000000 register-bank UsbDevice
	8bit register CTRLA
		1 bit swrst
		1 bit enable
		1 bit runstdby
		4 skip-bit
		1 bit mode
	end-register
	1 skip-byte
	8bit register SYNCBUSY
		1 bit swrst
		1 bit enable
	end-register
	8bit register QOSCTRL
		2 bit cqos
		2 bit dqos
	end-register
	4 skip-byte
	16bit register CTRLB
		1 bit detach
		1 bit uprsm
		2 bit spdconf
		1 bit nreply
		4 skip-bit
		1 bit gnak
		2 bit lpmhdsk
  	end-register
	8bit register DADD
		7 bit dadd
		1 bit adden
	end-register
	1 skip-byte
	8bit register STATUS
		2 skip-bit
		2 bit speed
		2 skip-bit
		2 bit linestate
	end-register
	8bit register FSMSTATUS
	end-register
	2 skip-byte
	16bit register FNUM
		3 skip-bit
		11 bit fnum
		1 skip-bit
		1 bit fncerr
	end-register
	2 skip-byte
	16bit register INTENCLR
		1 bit suspend
		1 skip-bit
		1 bit sof
		1 bit eorst
		1 bit wakeup
		1 bit eorsm
		1 bit uprsm
		1 bit ramacer
		1 bit lpmnyet
		1 bit lpmsusp
	end-register
	2 skip-byte
	16bit register INTENSET
		1 bit suspend
		1 skip-bit
		1 bit sof
		1 bit eorst
		1 bit wakeup
		1 bit eorsm
		1 bit uprsm
		1 bit ramacer
		1 bit lpmnyet
		1 bit lpmsusp
	end-register
	2 skip-byte
	16bit register INTFLAG
		1 bit suspend
		1 skip-bit
		1 bit sof
		1 bit eorst
		1 bit wakeup
		1 bit eorsm
		1 bit uprsm
		1 bit ramacer
		1 bit lpmnyet
		1 bit lpmsusp
	end-register
	2 skip-byte
	16bit register EPINTSMRY
	end-register
	2 skip-byte
	32bit register DESCADD
	end-register
	16bit register PADCAL
		5 bit transp
		1 skip-bit
		5 bit transn
		1 skip-bit
		3 bit trim
	end-register
	214 skip-byte
	\ and here at 0x100 are the device endpoint structures which I cannot embed into 
	\ register bansk atm. So I define the first 4 of 8 seperately below. I don't need
	\ all 8
end-register-bank

0x41000100 register-bank USBDevice_DeviceEndPoint0
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

0x41000120 register-bank USBDevice_DeviceEndPoint1
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

0x41000140 register-bank USBDevice_DeviceEndPoint2
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

0x41000160 register-bank USBDevice_DeviceEndPoint3
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

begin-structure UsbDeviceDescBank
	4 +field uddb.addr
	4 +field uddb.pcksize		\	1:autozlp 3:size 14:multi-size 14:size
	2 +field uddb.extreg
	1 +field uddb.status_bk
	5 +field uddb.reserved
end-structure

begin-structure UsbDeviceDescriptor
	UsbDeviceDescBank +field DeviceDescBank0
	UsbDeviceDescBank +field DeviceDescBank1
end-structure

\ -------------------------------------------------------------------------

0x1B4F constant USB_VID
0x0D23 constant USB_PID
64 constant SIZE_PACKET 

0 constant USB_EP_COMM_IN
1 constant USB_EP_IN
2 constant USB_EP_OUT
3 constant USB_EP_COMM

0x0080 constant USB_REQUEST_GET_STATUS_ZERO
0x0081 constant USB_REQUEST_GET_STATUS_INTERFACE
0x0082 constant USB_REQUEST_GET_STATUS_ENDPOINT
0x0101 constant USB_REQUEST_CLEAR_FEATURE_INTERFACE
0x0102 constant USB_REQUEST_CLEAR_FEATURE_ENDPOINT
0x0301 constant USB_REQUEST_SET_FEATURE_INTERFACE
0x0302 constant USB_REQUEST_SET_FEATURE_ENDPOINT
0x0500 constant USB_REQUEST_SET_ADDRESS
0x0680 constant USB_REQUEST_GET_DESCRIPTOR
0x0681 constant USB_REQUEST_GET_DESCRIPTOR1
0x0880 constant USB_REQUEST_GET_CONFIGURATION
0x0900 constant USB_REQUEST_SET_CONFIGURATION
0x21A1 constant USB_REQUEST_GET_LINE_CODING
0x2021 constant USB_REQUEST_SET_LINE_CODING
0x2221 constant USB_REQUEST_SET_CONTROL_LINE_STATE

create line_config
  here 0 c, here
	0x00 c, 0xC2 c, 0x01 c, 0x00 c, 0x00 c, 0x00 c, 0x08 c,
  here swap - swap c!

create devDescriptor
  here 0 c, here
    0x12 c, 0x01 c, 0x00 c, 0x02 c, 0xEF c, 0x02 c, 0x01 c, 0x40 c,
	USB_VID 0xFF and c, USB_VID 8 rshift 0xFF and c,
	USB_PID 0xFF and c, USB_PID 8 rshift 0xFF and c,
	0x01 c, 0x42 c, 0x01 c, 0x02 c, 0x03 c, 0x01 c,
  here swap - swap c!

create cfgDescriptor
  here 0 c, here
	0x09 c, 0x02 c, 75   c, 0x00 c, 0x03 c, 0x01 c, 0x00 c, 0x80 c, 250  c, 
	0x08 c, 0x0B c, 0x00 c, 0x02 c, 0x02 c, 0x02 c, 0x01 c, 0x00 c, 0x09 c, 
	0x04 c, 0x00 c, 0x00 c, 0x01 c, 0x02 c, 0x02 c, 0x01 c, 0x00 c, 0x05 c, 
	0x24 c, 0x00 c, 0x10 c, 0x01 c, 0x04 c, 0x24 c, 0x02 c, 0x06 c, 0x05 c, 
	0x24 c, 0x06 c, 0x00 c, 0x01 c, 0x05 c, 0x24 c, 0x01 c, 0x03 c, 0x01 c, 
	0x07 c, 0x05 c,
	USB_EP_COMM 0x80 or c,  
    0x03 c, 0x08 c, 0x00 c, 0xFF c, 0x09 c, 0x04 c, 0x01 c, 0x00 c, 0x02 c, 
	0x0A c, 0x00 c, 0x00 c, 0x00 c, 0x07 c, 0x05 c, 
    USB_EP_IN 0x80 or c,  
	0x02 c, 
    SIZE_PACKET c, 
    0x00 c, 0x00 c, 0x07 c, 0x05 c, 
    USB_EP_OUT c,   
	0x02 c, 
	SIZE_PACKET c,  
	0x00 c, 0x00 c,
  here swap - swap c!

create bosDescriptor
  here 0 c, here
	0x05 c, 0x0F c, 0x05 c, 0x00 c, 0x00 c,
  here swap - swap c!

create stringdescriptor0
  here 0 c, here
	0x04 c, 0x03 c, 0x09 c, 0x04 c,
  here swap - swap c!

create stringdescriptor1
  here 0 c, here
	0x0E c, 0x03 c,
	char v c, 0 c,
	char e c, 0 c,
	char n c, 0 c,
	char d c, 0 c,
	char o c, 0 c,
	char r c, 0 c,
  here swap - swap c!

create stringdescriptor2
  here 0 c, here
	0x10 c, 0x03 c,
	char p c, 0 c,
	char r c, 0 c,
	char o c, 0 c,
	char d c, 0 c,
	char u c, 0 c,
	char c c, 0 c,
	char t c, 0 c,
  here swap - swap c!

create stringdescriptor3
  here 0 c, here
	0x22 c, 0x03 c,
	char 1 c, 0 c,
	char 2 c, 0 c,
	char 3 c, 0 c,
	char 4 c, 0 c,
	char 5 c, 0 c,
	char 6 c, 0 c,
	char 7 c, 0 c,
	char 8 c, 0 c,
	char 9 c, 0 c,
	char 0 c, 0 c,
	char 1 c, 0 c,
	char 2 c, 0 c,
	char 3 c, 0 c,
	char 4 c, 0 c,
	char 5 c, 0 c,
	char 6 c, 0 c,
  here swap - swap c!

UsbDeviceDescriptor 4 * buffer: endpoints
256 constant #outputbuffer
256 constant #inputbuffer
#outputbuffer buffer: outputbuffer
#inputbuffer buffer: inputbuffer
variable num_chars
variable usb_active_config
SIZE_PACKET buffer: controlpacket
variable wait_for_input

0x00800080 constant NVMCTRL_SW0

NVMCTRL_SW0 4 + constant USB_FUSES_TRANSN_ADDR

: nvmctrlGetSoftCalUSB		( -- tn tp pd )
  USB_FUSES_TRANSN_ADDR 0 d32@
  dup 31 and swap
  dup 5 rshift 31 and swap
  10 rshift 7 and
;

: initUSB
  PA24 enableMux PA24 7 setMux
  PA25 enableMux PA25 7 setMux

  1 USB_GCLK_ID GCLK.PCHCTRLn.gen!
  1 USB_GCLK_ID GCLK.PCHCTRLn.chen!

  1 MCLK.AHBMASK.usb!
  1 MCLK.APBBMASK.usb!

  1 UsbHost.CTRLA.swrst!
  begin UsbHost.SYNCBUSY.swrst@ 0= until

  nvmctrlGetSoftCalUSB
	
  UsbHost.PADCAL.trim!
  UsbHost.PADCAL.transp!
  UsbHost.PADCAL.transn!

  0 UsbHost.CTRLA.mode!
  1 UsbHost.CTRLA.runstdby!
  endpoints rel>abs drop UsbHost.DESCADD.reg!
  0 UsbDevice.CTRLB.spdconf!
  0 UsbDevice.CTRLB.detach!

  endpoints UsbDeviceDescriptor 4 * 0 fill

  0 num_chars !
  0 usb_active_config !
  0 wait_for_input !

  1 UsbHost.CTRLA.enable!
;

defer pollUSB		( -- flag )

\ NOTE - I KNOW EP_IN is 1
: writeUSB_EP_IN		( addr len -- )				
  dup #outputbuffer > abort" usb write size"
  dup 0= abort" usb empty write"

  tuck outputbuffer swap move

  endpoints UsbDeviceDescriptor + DeviceDescBank1 
  outputbuffer rel>abs drop over uddb.ADDR !
  uddb.PCKSIZE !

  1 USBDevice_DeviceEndPoint1.EPINTFLAG.trcpt1!
  1 USBDevice_DeviceEndPoint1.EPSTATUSSET.bk1rdy!

  begin
    USBDevice_DeviceEndPoint1.EPINTFLAG.trcpt1@
    0=
  while
    pollUSB 0= if exit then
  repeat
;	

\ I know the endpoint is 0
: writeCOMM			( addr len -- )				
  dup #outputbuffer > abort" usb write size"
  
  ?dup 0= if
	nip
  else
  	tuck outputbuffer swap move
  then
  ( len -- )

  endpoints DeviceDescBank1 
  outputbuffer rel>abs drop over uddb.ADDR !
  uddb.PCKSIZE !

  1 USBDevice_DeviceEndPoint1.EPINTFLAG.trcpt1!
  1 USBDevice_DeviceEndPoint1.EPSTATUSSET.bk1rdy!

  begin
    USBDevice_DeviceEndPoint1.EPINTFLAG.trcpt1@
  until
;	

0 [IF]
  USB->DEVICE.INTFLAG.reg = USB_DEVICE_INTFLAG_EORST;
-        USB->DEVICE.DADD.reg = USB_DEVICE_DADD_ADDEN | 0;
-        USB->DEVICE.DeviceEndpoint[0].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE0(1) | USB_DEVICE_EPCFG_EPTYPE1(1);
-        USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK0RDY;
-        USB->DEVICE.DeviceEndpoint[0].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK1RDY;
-        endpoints[0].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
-        endpoints[0].DeviceDescBank[0].ADDR.reg = (uint32_t)control_packet;
-        endpoints[0].DeviceDescBank[0].PCKSIZE.bit.MULTI_PACKET_SIZE = 8;
-        endpoints[0].DeviceDescBank[0].PCKSIZE.bit.BYTE_COUNT = 0;
-        endpoints[0].DeviceDescBank[1].PCKSIZE.bit.SIZE = 3;
-        endpoints[0].DeviceDescBank[1].ADDR.reg = (uint32_t)outputbuffer;
-        USB->DEVICE.DeviceEndpoint[0].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK0RDY;
-        usb_active_config = 0;
[THEN]

: (pollRST)
  S" (pollRST)" lcd
  8 UsbDevice.INTFLAG.reg! 		\ 1 UsbDevice.INTFLAG.eorst!
  0x80 UsbDevice.DADD.reg!		\ 0 UsbDevice.DADD.dadd!
  								\ 1 UsbDevice.DADD.adden!

  5 UsbDevice_DeviceEndPoint0.EPCFG.reg!	\ 1 UsbDevice_DeviceEndPoint0.EPCFG.eptype0!
 											\ 1 UsbDevice_DeviceEndPoint0.EPCFG.eptype1!
  64 UsbDevice_DeviceEndPoint0.EPSTATUSSET.reg!		\ 1 UsbDevice_DeviceEndPoint0.EPSTATUSSET.bk0rdy!
  128 UsbDevice_DeviceEndPoint0.EPSTATUSCLR.reg!	\ 1 UsbDevice_DeviceEndPoint0.EPSTATUSCLR.bk1rdy!

  3 28 lshift 				 endpoints DeviceDescBank0 uddb.PCKSIZE !
  controlpacket rel>abs drop endpoints DeviceDescBank0 uddb.ADDR !
  3 28 lshift 8 14 lshift or endpoints DeviceDescBank0 uddb.PCKSIZE !

  3 28 lshift 				 endpoints DeviceDescBank1 uddb.PCKSIZE !
  outputbuffer rel>abs drop  endpoints DeviceDescBank1 uddb.ADDR !

  64 UsbDevice_DeviceEndPoint0.EPSTATUSCLR.reg!	\ 1 UsbDevice_DeviceEndPoint0.EPSTATUSCLR.bk0rdy!
  0 usb_active_config !
  S" finished" lcd2
;

: (pollMSG)				{: | request request_value idx dir request_length -- :}
  S" (pollMSG)" lcd
  1 UsbDevice_DeviceEndPoint0.EPINTFLAG.rxstp!

  controlpacket w@ to request
  controlpacket 2 + w@ to request_value
  controlpacket 4 + w@ 0x7F and to idx
  controlpacket 4 + w@ 0x80 and 0= 0= to dir
  controlpacket 6 + w@ to request_length

  1 UsbDevice_DeviceEndPoint0.EPSTATUSCLR.bk0rdy!

  request 0 base @ >r hex <# #S #> r> base ! lcd2

  request case
    USB_REQUEST_GET_STATUS_ZERO of
	  0 outputbuffer !	\ need 2 bytes 
	  outputbuffer 2 request_length min writeCOMM
	  endof
    USB_REQUEST_GET_STATUS_INTERFACE of
	  0 outputbuffer !	\ need 2 bytes 
	  outputbuffer 2 request_length min writeCOMM
	  endof
    USB_REQUEST_GET_STATUS_ENDPOINT of
	  0 outputbuffer !	\ need 2 bytes 
	  idx 4 < if
	    dir if
		  UsbDevice_DeviceEndPoint0.EPSTATUS.stallrq0@ if 1 outputbuffer c! then
	    else
		  UsbDevice_DeviceEndPoint0.EPSTATUS.stallrq1@ if 1 outputbuffer c! then
	    then
	    outputbuffer 2 request_length min writeCOMM
	  else		
	    1 UsbDevice_DeviceEndPoint0.EPSTATUSSET.stallrq1!
	  then
	  endof
    USB_REQUEST_CLEAR_FEATURE_INTERFACE of
	  0 0 writeCOMM
	  endof
    \ default
	HACF
  endcase
;

: (pollUSB)				( -- flag )
  ledon
  UsbDevice.INTFLAG.eorst@ if 
    (pollRST) 
ledoff
    0 
  else
\    UsbDevice_DeviceEndPoint0.EPINTFLAG.rxstp@ if
\      (pollMSG) 
\    then
    usb_active_config @ 0= 0=
  then
  ledoff
;


0 [IF]
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
				writeCOMM(NULL, 0 );
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_SET_FEATURE_INTERFACE:
			writeCOMM(NULL, 0 );
			break;
		case USB_REQUEST_SET_FEATURE_ENDPOINT:
			if ((request_value == 0) && idx && (idx < 4)) {
				if (direction) 
					USB->DEVICE.DeviceEndpoint[idx].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
				else
					USB->DEVICE.DeviceEndpoint[idx].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ0;
				writeCOMM(NULL, 0 );
			} else {
				USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			}
			break;
		case USB_REQUEST_SET_ADDRESS:
			writeCOMM(NULL, 0 );
			USB->DEVICE.DADD.reg = USB_DEVICE_DADD_ADDEN | request_value;
			break;
		case USB_REQUEST_GET_DESCRIPTOR:
		case USB_REQUEST_GET_DESCRIPTOR1:
			if (request_value == 0x100) writeCOMM(devDescriptor, MIN(request_length,sizeof(devDescriptor)) );
			else if (request_value == 0x200) writeCOMM(cfgDescriptor, MIN(request_length,sizeof(cfgDescriptor)) );
			else if ( request_value == 0x300 ) writeCOMM( stringdescriptor0, MIN(request_length, stringdescriptor0[0] ) );
			else if ( request_value == 0x301 ) writeCOMM( stringdescriptor1, MIN(request_length, stringdescriptor1[0] ) );
			else if ( request_value == 0x302 ) writeCOMM( stringdescriptor2, MIN(request_length, stringdescriptor2[0] ) );
			else if ( request_value == 0x303 ) writeCOMM( stringdescriptor3, MIN(request_length, stringdescriptor3[0] ) );
			else if ( request_value == 0xF00 ) writeCOMM(bosDescriptor, MIN(request_length,sizeof(bosDescriptor)) );
			else USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			break;
		case USB_REQUEST_GET_CONFIGURATION:
			writeCOMM(&(usb_active_config), MIN( request_length, sizeof(usb_active_config)) );
			break;
		case USB_REQUEST_SET_CONFIGURATION:
			usb_active_config = (uint8_t)request_value;
			writeCOMM(NULL, 0 );

			USB->DEVICE.DeviceEndpoint[ USB_EP_OUT ].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE0(3);
			pEndPoint[ USB_EP_OUT ].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
			USB->DEVICE.DeviceEndpoint[ USB_EP_OUT ].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK0RDY;
			pEndPoint[ USB_EP_OUT ].DeviceDescBank[0].ADDR.reg = (uint32_t)outputbuffer;

			USB->DEVICE.DeviceEndpoint[ USB_EP_IN ].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE1(3);
			pEndPoint[ USB_EP_IN ].DeviceDescBank[0].PCKSIZE.bit.SIZE = 3;
			USB->DEVICE.DeviceEndpoint[ USB_EP_IN ].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_BK1RDY;
			pEndPoint[ USB_EP_IN ].DeviceDescBank[0].ADDR.reg = (uint32_t)inputbuffer;

			USB->DEVICE.DeviceEndpoint[USB_EP_COMM].EPCFG.reg = USB_DEVICE_EPCFG_EPTYPE1(4);
			pEndPoint[USB_EP_COMM].DeviceDescBank[1].PCKSIZE.bit.SIZE = 0;
			USB->DEVICE.DeviceEndpoint[USB_EP_COMM].EPSTATUSCLR.reg = USB_DEVICE_EPSTATUSCLR_BK1RDY;
			break;
		case USB_REQUEST_GET_LINE_CODING:
			writeCOMM(line_config, MIN(request_length,sizeof(line_config)) );
			break;
		case USB_REQUEST_SET_LINE_CODING:
			writeCOMM(NULL, 0 );
			break;
		case USB_REQUEST_SET_CONTROL_LINE_STATE:
			writeCOMM(NULL, 0 );
			break;
		default:
			USB->DEVICE.DeviceEndpoint[0].EPSTATUSSET.reg = USB_DEVICE_EPSTATUSSET_STALLRQ1;
			break;
		}
	}
[THEN]

' (pollUSB) is pollUSB

\ I Known USB_EP_OUT is 2
: readUSB		( -- char | -1 )
  num_chars @ if
	inputbuffer c@
    -1 num_chars +!
	inputbuffer 1 + inputbuffer num_chars @ cmove
  else
	wait_for_input @ 0= if
		endpoints UsbDeviceDescriptor 2 * + DeviceDescBank0
		inputbuffer rel>abs drop over uddb.ADDR !
		0 swap uddb.PCKSIZE !

  		1 USBDevice_DeviceEndPoint2.EPSTATUSCLR.bk0rdy!
		
		1 wait_for_input !
		-1
	else
		USBDevice_DeviceEndPoint2.EPINTFLAG.trcpt0@ if
		  endpoints UsbDeviceDescriptor 2 * + DeviceDescBank0 uddb.PCKSIZE @ num_chars !
		  1  USBDevice_DeviceEndPoint2.EPINTFLAG.trcpt0!
		  0 wait_for_input !
		  -1
		else
		  -1
        then
	then
  then
;

: usb-ekey			( -- char | -1 )
  pollUSB 0= if 
    -1 
  else
   readUSB
   dup 13 = if drop 10 then
  then
;

\ very inefficient.
variable emit-buffer

: usb-emit			\ char --
drop exit
  pollUSB 0= if drop else
    dup 10 = if
	  13 emit-buffer c!
	  emit-buffer 1+ c!
	  emit-buffer 2 writeUSB_EP_IN	
    else
	  emit-buffer c!
	  emit-buffer 1 writeUSB_EP_IN	
    then
  then
;

open-namespace core

onboot: UsbConsole
	ledon
	Wire.begin lcd-init S" Boot" lcd-type lcd-update
	initUSB
    ['] usb-emit ['] (emit) defer!
	['] usb-ekey ['] (ekey) defer!
onboot;

