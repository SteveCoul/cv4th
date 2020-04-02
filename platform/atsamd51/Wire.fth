
require platform/cortexm4/gclk.fth
require platform/cortexm4/sercom3_i2cm.fth

internals ext-wordlist forth-wordlist 3 set-order 
definitions

\ private-namespace

48000000 constant WIRE_CLOCK_SPEED	\ speed of clock1

20 constant PIN_WIRE_SDA
21 constant PIN_WIRE_SCL

: clocks
  1 24 GCLK.PCHCTRLn.gen!	\ clock for ID_CORE is 1 
  1 24 GCLK.PCHCTRLn.chen!
  5 3  GCLK.PCHCTRLn.gen!   \ clock for ID_SLOW is 5
  1 3  GCLK.PCHCTRLn.chen!
;

: reset
  1 SERCOM3_I2CM.CTRLA.swrst!
  begin SERCOM3_I2CM.CTRLA.swrst@ 0= SERCOM3_I2CM.SYNCBUSY.swrst@ 0= and until
;

: enable
  1 SERCOM3_I2CM.CTRLA.enable!
  begin SERCOM3_I2CM.SYNCBUSY.enable@ 0= until
  1 SERCOM3_I2CM.STATUS.busstate!
  begin SERCOM3_I2CM.SYNCBUSY.sysop@ 0= until
;

: disable
  0 SERCOM3_I2CM.CTRLA.enable!
  begin SERCOM3_I2CM.SYNCBUSY.enable@ 0= until
;

: init			( clock -- )
	reset
	5 SERCOM3_I2CM.CTRLA.mode!

	2 * 1 - WIRE_CLOCK_SPEED swap /
	SERCOM3_I2CM.BAUD.baud!
;

: nack 1 SERCOM3_I2CM.CTRLB.ackact!  ;
: ack 0 SERCOM3_I2CM.CTRLB.ackact! ;

: cmd	( cmd -- ) SERCOM3_I2CM.CTRLB.cmd! ;

: startWrite ( address -- ok? )
  1 lshift 0 or
  \ TODO wait until bus idle or mine?
  SERCOM3_I2CM.ADDR.addr!
  begin SERCOM3_I2CM.INTFLAG.mb@ until
  SERCOM3_I2CM.status.rxnack@ 0=
;

: startRead ( address -- ok? )
  1 lshift 1 or
  \ wait for bus?
  SERCOM3_I2CM.ADDR.addr!
  begin 
	SERCOM3_I2CM.INTFLAG.sb@ 0=
  while
  	SERCOM3_I2CM.INTFLAG.mb@ if
		3 SERCOM3_CTRLB.cmd! \ send stop if slave nacks
		false exit
  	then
  repeat
  SERCOM3_I2CM.status.rxnack@ 0=
;

: sendData	( byte -- ok? )
  SERCOM3_I2CM.DATA.byte!
  begin SERCOM3_I2CM.INTFLAG.mb@ 0= while
	SERCOM3_I2CM.STATUS.buserr@ if
	  false exit
    then
  repeat
  SERCOM3_I2CM.status.rxnack@ 0=
;

: nack?		( -- flag )
  SERCOM3_I2CM.status.rxnack@
;

: available ( -- flag )
  SERCOM3_I2CM.INTFLAG.sb@
;

: read ( -- byte )
  begin available until
  SERCOM3_I2CM.DATA.byte@
;

ext-wordlist set-current

: Wire.delay				( n -- )
	1 abort" not implemented"
;

: Wire.reset				( -- )
	1 abort" not implemented"
;

: Wire.begin				(  -- )
	1 abort" not implemented"
;

: Wire.beginTransmission	( i2c-address -- )
	1 abort" not implemented"
;

: Wire.write				( u -- 0|1 )
	1 abort" not implemented"
;

: Wire.endTransmission		( flag -- )
	1 abort" not implemented"
;

: Wire.requestFrom			( i2c-address count doend? -- num )
	1 abort" not implemented"
;
 
: Wire.read					( -- u )
	1 abort" not implemented"
;

: Wire.available			( -- n )
	1 abort" not implemented"
;

only forth definitions

