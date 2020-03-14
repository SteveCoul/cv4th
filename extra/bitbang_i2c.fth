
ext-wordlist forth-wordlist internals 3 set-order definitions             

[UNDEFINED] pinMode [IF]
	cr .( You have not included a gpio driver yet, cannot build without it ) abort [THEN]

0 value SDA_PIN
0 value SCL_PIN

variable i2c_delay 				0 i2c_delay !

: i2c_wait i2c_delay @ ms ;

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
  begin sda@ 0= while sclHI sclLO repeat
  sdaOUT sclOUT sclHI sdaHI i2c_wait ;

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

ext-wordlist set-current

: Wire.begin				( sda-pin scl-pin -- )
  to SCL_PIN
  to SDA_PIN
  reset
;

: Wire.beginTransmission	( i2c-address -- okay? )
  start 7bit write_direction ack? 0=
;

: Wire.sendByte				( u -- okay? )
  8bit ack? 0= 
;

: Wire.endTransmission		( flag -- )
  if end then
;

: Wire.delay				( n -- )
  i2c_delay !
;

: Wire.requestFrom			( i2c-address -- okay? )
  start i2c_wait 7bit read_direction ack? 0=
;
 
: Wire.reset				( -- )
  end reset start start reset 
;

: Wire.read					( -- u )
  read8 ack
;

: Wire.doneRead
  end
;

only forth definitions

