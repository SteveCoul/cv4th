
( Software implementation of I2C protocol implement our Wire wordset )

require extra/ringbuffer.fth

ext-wordlist forth-wordlist 2 set-order 

private-namespace

[UNDEFINED] pinMode [IF]
	cr .( You have not included a gpio driver yet, cannot build without it ) abort [THEN]
S" I2C_SDA_PIN" environment? 0= [IF]  cr .( I2C_SDA_PIN not in environment ) abort [THEN] value SDA_PIN
S" I2C_SCL_PIN" environment? 0= [IF]  cr .( I2C_SCL_PIN not in environment ) abort [THEN] value SCL_PIN

require extra/ringbuffer.fth

variable i2c_delay 				0 i2c_delay !

[DEFINED] ms [IF]
: i2c_wait i2c_delay @ ms ;
[ELSE]
: i2c_wait i2c_delay @ 0 ?do loop ;
[THEN]

: sdaOUT SDA_PIN OUTPUT pinMode ;                                
: sclOUT SCL_PIN OUTPUT pinMode ;                                
: sdaIN  SDA_PIN INPUT pinMode ;                                  
: sdaHI  SDA_PIN HIGH writeDigital ;
: sdaLO  SDA_PIN LOW writeDigital ;
: sclHI  SCL_PIN HIGH writeDigital ;
: sclLO  SCL_PIN LOW writeDigital ;
: sda@   SDA_PIN readDigital ;

: reset  	
  sdaIN sclOUT
\  begin sda@ 0= while sclHI sclLO repeat
  sdaOUT sclOUT sclHI sdaHI i2c_wait 
;

: start 	reset i2c_wait sdaLO i2c_wait sclLO ;
: end 		sdaLO i2c_wait sclHI i2c_wait sdaHI ;    
: bit   	if sdaHI else sdaLO then sclHI i2c_wait sclLO ;
: readbit 	sclHI i2c_wait sda@ sclLO ;

: 7bit 64  begin ?dup while 2dup and bit 1 rshift repeat drop ;
: 8bit 128 begin ?dup while 2dup and bit 1 rshift repeat drop ;

: read_direction 1 bit ;		 
: write_direction 0 bit ;
: ack 0 bit ;
: nack 1 bit ;
: ack?	sdaIN readbit sdaOUT ;
: read8 sdaIN 0 8 0 do 1 lshift readbit if 1 or then loop sdaOUT ;

32 constant #txbuffer #txbuffer RingBuffer: txbuffer
32 constant #rxbuffer #rxbuffer RingBuffer: rxbuffer

ext-wordlist set-current

: Wire.delay				( n -- )
  i2c_delay !
;

: Wire.reset				( -- )
  end reset start start reset 
;

: Wire.begin				(  -- )
  reset
;

: Wire.beginTransmission	( i2c-address -- )
  start 7bit write_direction ack? abort" failed wire begintransmission"
  txbuffer RingBuffer.empty
;

: Wire.write				( u -- 0|1 )
  txbuffer RingBuffer.push
;

: Wire.endTransmission		( flag -- )
  begin
    txbuffer RingBuffer.available
  while
	txbuffer RingBuffer.pop 8bit ack? abort" failed wire send"
  repeat
  if end then
;

: Wire.requestFrom			( i2c-address count doend? -- num )
  >r
  dup #rxbuffer < if
	rxbuffer RingBuffer.empty

	\ todo - timeout / end detection
	start i2c_wait swap 7bit read_direction ack? if
	  drop
	else
	  begin		 ( count -- )
	    ?dup
      while
   		read8 ack rxbuffer RingBuffer.push drop
		1-
	  repeat
	then	

    r> if end then
	rxbuffer RingBuffer.available
  else
    2drop r> drop 0
	1 abort" requestfrom too much"
  then
;
 
: Wire.read					( -- u )
  rxbuffer RingBuffer.pop
;

: Wire.available			( -- n )
  rxbuffer RingBuffer.available
;

only forth definitions

