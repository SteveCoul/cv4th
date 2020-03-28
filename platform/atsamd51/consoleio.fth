
require platform/cortexm4/sercom.fth

ext-wordlist get-order 1+ set-order

: sysinit
  \ enable XOSC32K clock (external)
  1 osc32kctrl.xosc32k.en32k!
  1 osc32kctrl.xosc32k.cgm! 		\ standard mode 
  1 osc32kctrl.xosc32k.xtalen!
  1 osc32kctrl.xosc32k.enable! 
  begin osc32kctrl.status.xosc32krdy@ schedule until
;

\ These should be elsewhere
7 constant SERCOM0_GCLK_ID_CORE       
3 constant SERCOM0_GCLK_ID_SLOW         

: resetUART
  1 sercom0.ctrla.swrst!
  begin
	sercom0.ctrla.swrst@
	sercom0.syncbusy.swrst@
	or
  while
	schedule
  repeat
;

: enableUART
  1 sercom0.ctrla.enable!
  begin schedule sercom0.syncbusy.enable@ 0= until
;

: initClock
  1 SERCOM0_GCLK_ID_CORE GCLK.PCHCTRLn.chen!
  1 SERCOM0_GCLK_ID_SLOW GCLK.PCHCTRLn.chen!
;

: initUART			
  initClock
  1 MCLK.APBAMASK.sercom0!

  resetUART
  1	sercom0.ctrla.mode!				\ internal clock
  1 sercom0.ctrla.sampr!			\ 16x oversampling fractional baudrate
  1 sercom0.itenset.rxc!			\ interrupt receive complete
  1 sercom0.itenset.error!			\ interrupt error
  
  48000000 8 *
  16 115200 *
  /
  dup 8 mod
  swap 8 /
  0x1FFF and swap
  7 and 13 lshift or
  
  sercom0.baud.baud!				\ 115200 baudrate I hope

  0 sercom0.ctrlb.chsize!			\ 8 bit data
  0 sercom0.ctrlb.sbmode!			\ 1 stop bit
  0 sercom0.ctrlb.pmode!			\ default (no) parity
  0 sercom0.ctrla.txpo!				\ txpad
  0 sercom0.ctrla.rxpo!				\ rxpad
  1 sercom0.ctrlb.txen!				\ enable transmitter
  1 sercom0.ctrlb.rxen!				\ enable receiver
;

10 buffer: fred

onboot: consoleIO
	sysinit
	1 fred c!
	[char] 0 fred 1+ c!
	lcd-init lcd-clear lcd-update
	lcd-clear 0 0 lcd-at-xy S" initUART" lcd-type lcd-update
	initUART
	lcd-clear 0 0 lcd-at-xy S" Enable" lcd-type lcd-update
	enableUART
	lcd-clear 0 0 lcd-at-xy S" Ready" lcd-type lcd-update
	begin 
	    lcd-clear 1 1 lcd-at-xy fred count lcd-type lcd-update
		fred 1+ c@ 1+ dup [char] 9 > if
			drop [char] 0 
		then
		fred 1+ c!

		fred 1+ c@ sercom0.data.data!
    again
onboot;

