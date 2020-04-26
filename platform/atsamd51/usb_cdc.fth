require platform/atsamd51/usb.fth
require platform/atsamd51/gclk.fth
require platform/atsamd51/mclk.fth

ext-wordlist forth-wordlist 2 set-order definitions

0x00800080 constant NVMCTRL_SW0
NVMCTRL_SW0 4 + constant USB_FUSES_TRANSN_ADDR

0x1B4F constant USB_VID
0x0D23 constant USB_PID

0 value usbrunning
UsbDeviceDescriptor 4 * buffer: endpoints
64 buffer: control_packet
64 buffer: outputbuffer

create devDescriptor
	18 c,
	0x12 c, 0x01 c, 0x00 c, 0x02 c,
	0xEF c, 0x02 c, 0x01 c, 0x40 c, 
    USB_VID 0xFF and c, USB_VID 8 rshift 0xFF and c, 
    USB_PID 0xFF and c, USB_PID 8 rshift 0xFF and c, 
	0x01 c, 0x42 c, 0x01 c, 0x02 c,
	0x03 c, 0x01 c,

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
  endpoint0 DeviceDescBank0 16 dump
  cr 
  ." Bank1 @ " endpoint0 DeviceDescBank1 uddb.addr @ .
  ." , byte_count " endpoint0 DeviceDescBank1 uddb.pcksize @ 0x3FFF and .
  endpoint0 DeviceDescBank1 16 dump
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
  1 UsbDevice.CTRLB.spdconf!		\ low speed, ( 0 = hi )
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

	1 USBDevice_DeviceEndPoint0.EPCFG.eptype0!	\ bank0 is control setup/out
	1 USBDevice_DeviceEndPoint0.EPCFG.eptype1!	\ bank1 is control in

	1 USBDevice_DeviceEndPoint0.EPSTATUSSET.bk0rdy!
	1 USBDevice_DeviceEndPoint0.EPSTATUSCLR.bk1rdy!

	3 endpoint0 DeviceDescBank0 uddb.pcksize setsize
	8 endpoint0 DeviceDescBank0 uddb.pcksize setmultisize
	0 endpoint0 DeviceDescBank0 uddb.pcksize setbytecount
	control_packet rel>abs drop endpoint0 DeviceDescBank0 uddb.addr !
	outputbuffer rel>abs drop endpoint0 DeviceDescBank1 uddb.addr !
	1 USBDevice_DeviceEndPoint0.EPSTATUSCLR.bk0rdy!

	usbClearReset 
	0 to usbrunning
  then
;

: ep0Rxspt?	( n -- flag ) 
  USBDevice_DeviceEndPoint0.EPINTFLAG.rxstp@ 0= 0= ;

: clearEp0Rxspt		( -- )
  1 USBDevice_DeviceEndPoint0.EPINTFLAG.rxstp! ;

0 value cpRequest
0 value cpRequestValue
0 value cpRequestIndex
0 value cpRequestDirection
0 value cpRequestLength

: readControlPacket	( -- )
  control_packet w@ to cpRequest
  control_packet 2 + w@ to cpRequestValue
  control_packet 4 + w@ 0x7F and to cpRequestIndex
  control_packet 4 + w@ 0x80 and 0= 0= to cpRequestDirection
  control_packet 6 + w@ to cpRequestLength
;

: .hex base @ >r hex 0 <# #S #> type r> base ! ;

: reply			( addr len -- )
  outputbuffer rel>abs drop endpoint0 DeviceDescBank1 uddb.addr !	\ needed?

  3 endpoint0 DeviceDescBank1 uddb.pcksize setsize
  0 endpoint0 DeviceDescBank1 uddb.pcksize setmultisize
  dup endpoint0 DeviceDescBank1 uddb.pcksize setbytecount

  dup if
    outputbuffer swap move
  else
    2drop
  then
  
  1 UsbDevice_DeviceEndPoint0.EPSTATUSSET.bk1rdy!
  1 UsbDevice_DeviceEndPoint0.EPINTFLAG.trcpt1!
  .endpoint0 
  begin 
    key? abort" aborted"
    UsbDevice_DeviceEndPoint0.EPINTFLAG.trfail1@ abort" failed"
    UsbDevice_DeviceEndPoint0.EPINTFLAG.trcpt1@ 
  until
;

: zeropacket 0 0 reply ;

: set-address
  cr ." Set address to " cpRequestValue .hex
  zeropacket
  cpRequestValue UsbDevice.DADD.dadd!
  1 UsbDevice.DADD.adden!
;

: get-descriptor
  cpRequestValue case
    0x0100 of cr ." get device descriptor" devDescriptor swap endof
\  0x0200 of cfgDescriptor swap endof
\  0x0300 of stringDescriptor0 swap endof
\  0x0301 of stringDescriptor1 swap endof
\  0x0302 of stringDescriptor2 swap endof
\  0x0303 of stringDescriptor3 swap endof
\  0x0F00 of bosDescriptor swap endof
  cr ." unhandled descriptor number " dup .hex
  0 swap
  endcase
  ?dup if
    count cpRequestLength min reply
  else
    \ TODO stall
  then
;

: (pollusb)		
  usbCheckReset
  ep0Rxspt? if
	clearEp0Rxspt

	readControlPacket
	1 USBDevice_DeviceEndPoint0.EPSTATUSCLR.bk0rdy!

	cpRequest case
	0x0500 of set-address endof
	0x0680 of get-descriptor endof
	0x0681 of get-descriptor endof
	cr ." Unhandled cpRequest value" dup .hex
	\ todo STALL
	endcase
  then
;

: pollUSB begin key? 0= while (pollusb) repeat ;

