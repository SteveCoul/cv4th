
require platform/atsamd51/usb.fth
require platform/atsamd51/gclk.fth
require platform/atsamd51/mclk.fth

ext-wordlist forth-wordlist 2 set-order definitions

0x00800080 constant NVMCTRL_SW0
NVMCTRL_SW0 4 + constant USB_FUSES_TRANSN_ADDR

0 value usbrunning
UsbDeviceDescriptor 4 * buffer: endpoints
64 buffer: control_packet
64 buffer: outputbuffer

: nvmctrlGetSoftCalUSB		( -- tn tp pd )
  USB_FUSES_TRANSN_ADDR 0 d32@
  dup 31 and swap
  dup 5 rshift 31 and swap
  10 rshift 7 and
;

: endpoint0 endpoints 0 UsbDeviceDescriptor * + ;
: endpoint1 endpoints 1 UsbDeviceDescriptor * + ;
: endpoint2 endpoints 2 UsbDeviceDescriptor * + ;
: endpoint3 endpoints 3 UsbDeviceDescriptor * + ;

: .endpoint0
  cr
  ." | dtlgout "  USBDevice_DeviceEndPoint0.EPSTATUS.dtlgout@ .
  ." | dtglin "   USBDevice_DeviceEndPoint0.EPSTATUS.dtglin@ .
  ." | curbk "    USBDevice_DeviceEndPoint0.EPSTATUS.curbk@ .
  ." | stallrq0 " USBDevice_DeviceEndPoint0.EPSTATUS.stallrq0@ .
  ." | stallrq1 " USBDevice_DeviceEndPoint0.EPSTATUS.stallrq1@ .
  ." | bk0rdy "   USBDevice_DeviceEndPoint0.EPSTATUS.bk0rdy@ .
  ." | bk1rdy "   USBDevice_DeviceEndPoint0.EPSTATUS.bk1rdy@ .
  ." |"
  cr
  ." | trcpt0 "   USBDevice_DeviceEndPoint0.EPINTFLAG.trcpt0@ .
  ." | trcpt1 "   USBDevice_DeviceEndPoint0.EPINTFLAG.trcpt1@ .
  ." | trfail0 "  USBDevice_DeviceEndPoint0.EPINTFLAG.trfail0@ .
  ." | trfail1 "  USBDevice_DeviceEndPoint0.EPINTFLAG.trfail1@ .
  ." | rxstp "    USBDevice_DeviceEndPoint0.EPINTFLAG.rxstp@ .
  ." | stall0 "   USBDevice_DeviceEndPoint0.EPINTFLAG.stall0@ .
  ." | stall1 "   USBDevice_DeviceEndPoint0.EPINTFLAG.stall1@ .
  cr 
  ." Bank0 @ " endpoint0 DeviceDescBank0 uddb.addr @ .
  ." , byte_count " endpoint0 DeviceDescBank0 uddb.pcksize @ 0x3FFF and .
  cr 
  ." Bank1 @ " endpoint0 DeviceDescBank1 uddb.addr @ .
  ." , byte_count " endpoint0 DeviceDescBank1 uddb.pcksize @ 0x3FFF and .
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

  1 UsbHost.CTRLA.enable!
  0 to usbrunning
;

: usbIsReset		( -- flag )		USBDevice.INTFLAG.eorst@ 0= 0= ;
: usbClearReset		( -- )			1 USBDevice.INTFLAG.eorst! ;

: setsize			( v addr -- )
  dup @ 0x8FFFFFFF and rot 7 and 28 lshift or swap ! ;

: setmultisize		( v addr -- )
  dup @ 0xF0003FFF and rot 0x3FFF and 14 lshift or swap ! ;

: setbytecount		( v addr -- )
  dup @ 0xFFFFC000 and rot 0x3FFF and or swap ! ;

: usbCheckReset		( -- )
  usbIsReset if
	cr ." usbReset detected"
    0 USBDevice.DADD.dadd!
	1 USBDevice.DADD.adden!

	1 USBDevice_DeviceEndPoint0.EPSTATUSCLR.bk0rdy!
	3 endpoint0 DeviceDescBank0 uddb.pcksize setsize
	8 endpoint0 DeviceDescBank0 uddb.pcksize setmultisize
	0 endpoint0 DeviceDescBank0 uddb.pcksize setbytecount
	control_packet rel>abs drop endpoint0 DeviceDescBank0 uddb.addr !
	1 USBDevice_DeviceEndPoint0.EPSTATUSSET.bk0rdy!

	1 USBDevice_DeviceEndPoint0.EPSTATUSCLR.bk1rdy!
	outputbuffer rel>abs drop endpoint0 DeviceDescBank1 uddb.addr !

    usbClearReset 
	0 to usbrunning

	.endpoint0
  then
;

: ep0Rxspt?	( n -- flag ) 
  USBDevice_DeviceEndPoint0.EPINTFLAG.rxstp@ 0= 0= ;

: clearEp0Rxspt		( -- )
  1 USBDevice_DeviceEndPoint0.EPINTFLAG.rxstp! ;

