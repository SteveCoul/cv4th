
require platform/atsamd51/sercom2_uart.fth
require platform/atsamd51/peripherals.fth
require platform/atsamd51/gpio.fth

ext-wordlist get-order 1+ set-order
open-namespace platform/atsamd51/gpio.fth

private-namespace

48000000 constant CLOCK_SPEED	\ speed of clock1

: clocks			( -- )
  1 MCLK.APBBMASK.sercom2!
  1 23 GCLK.PCHCTRLn.gen!
  1 23 GCLK.PCHCTRLn.chen!
  5 3 GCLK.PCHCTRLn.gen!   
  1 3 GCLK.PCHCTRLn.chen!
;

: doneEnabled?		( -- flag )	 SERCOM2_UART.SYNCBUSY.enable@ 0= ;
: enable			( -- ) 		 1 SERCOM2_UART.CTRLA.enable!  begin doneEnabled? until ;
: >data				( v -- ) 	 SERCOM2_UART.DATA.byte! ;

: available?		( -- flag )  SERCOM2_UART.INTFLAG.rxc@ 0= 0= ;
: error?			( -- flag )  SERCOM2_UART.INTFLAG.error@ 0= 0= ;
: clearError		( -- ) 1 	 SERCOM2_UART.INTFLAG.error! ;
: dataRegisterEmpty? ( -- flag ) SERCOM2_UART.INTFLAG.dre@ 0= 0= ;
: txcomplete?		( -- flag )  SERCOM2_UART.INTFLAG.txc@ 0= 0= ;
: .ints				( -- )
  cr
  ." | dre "
  SERCOM2_UART.INTFLAG.dre@ . 
  ." | txc "
  SERCOM2_UART.INTFLAG.txc@ . 
  ." | rxc "
  SERCOM2_UART.INTFLAG.rxc@ . 
  ." | rxs "
  SERCOM2_UART.INTFLAG.rxs@ . 
  ." | ctsic "
  SERCOM2_UART.INTFLAG.ctsic@ . 
  ." | rxbrk "
  SERCOM2_UART.INTFLAG.rxbrk@ . 
  ." | error "
  SERCOM2_UART.INTFLAG.error@ . 
;

: clearStatus		( -- )	0 	 SERCOM2_UART.STATUS.reg! ;
: overflow?			( -- flag )  SERCOM2_UART.STATUS.bufovf@ 0= 0= ;
: frameError?		( -- flag )  SERCOM2_UART.STATUS.ferr@ 0= 0= ;
: clearFrameError	( -- ) 1 	 SERCOM2_UART.STATUS.ferr! ;
: parityError?		( -- flag )  SERCOM2_UART.STATUS.perr@ 0= 0= ;
: .status			( -- ) 
  cr
  ." perr "
  SERCOM2_UART.STATUS.perr@ .
  ." | ferr "
  SERCOM2_UART.STATUS.ferr@ .
  ." | buvovf "
  SERCOM2_UART.STATUS.bufovf@ .
  ." | cts "
  SERCOM2_UART.STATUS.cts@ .
  ." | isf "
  SERCOM2_UART.STATUS.isf@ .
  ." | coll "
  SERCOM2_UART.STATUS.coll@ .
  ." | txe "
  SERCOM2_UART.STATUS.txe@ .
  ." | iter "
  SERCOM2_UART.STATUS.iter@ .
;

: reset				( -- )
  1 SERCOM2_UART.CTRLA.swrst!
  begin SERCOM2_UART.SYNCBUSY.swrst@ 0= until
;

: init				( baud -- )
  clocks


  PIN_D1 PIO_SERCOM setMux
  PIN_D1 enableMux
  PIN_D0 PIO_SERCOM setMux
  PIN_D0 enableMux

  reset
  1 SERCOM2_UART.CTRLA.mode!		\ 1=internal clock, 0=external
  1 SERCOM2_UART.CTRLA.sampr!		\ 16 bit over sampling, fractional

  CLOCK_SPEED 8 * swap 16 * /
  dup 8 / SERCOM2_UART.BAUD.baud!
  8 mod SERCOM2_UART.BAUD.frac!
;

: setstop			( 1|2 -- ) 1 = if 0 else 1 then SERCOM2_UART.CTRLB.sbmode! ;

: setParity			( mode -- )
  dup 0 <> if 1 else 0 then SERCOM2_UART.CTRLA.form!
  dup 1 <> if drop 0 then SERCOM2_UART.CTRLB.pmode!
;

: setEndian			( littleendian? -- ) if 1 else 0 then SERCOM2_UART.CTRLA.dord! ;

: setCharSize		( #data -- )
  case
  5 of 5 swap endof
  6 of 6 swap endof
  7 of 7 swap endof
  8 of 0 swap endof
  9 of 1 swap endof
  0 swap \ default 8bit
  endcase
  SERCOM2_UART.CTRLB.chsize!
;

: initframe			( #data lsbfirst? parity #stop -- )
  setStop
  setParity
  setEndian
  setCharsize
;

: initPads			( -- )
  0 SERCOM2_UART.CTRLA.txpo!
  1 SERCOM2_UART.CTRLA.rxpo!
  1 SERCOM2_UART.CTRLB.txen!
  1 SERCOM2_UART.CTRLB.rxen!
;

: start			( #data lsbfirst parity #stop baud -- )
  clocks reset init initframe initpads enable ;

: read				( -- value ) SERCOM2_UART.DATA.byte@ ;
: write				( v -- ) 	 begin dataRegisterEmpty? until >data ;
: flush				( -- ) 		 dataRegisterEmpty? 0= if begin txComplete? until ;

