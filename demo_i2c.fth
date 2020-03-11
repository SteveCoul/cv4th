

S" I2C_SDA_PIN" environment? 0= [IF]  cr .( I2C_SDA_PIN not in environment ) abort [THEN]
S" I2C_SCL_PIN" environment? 0= [IF]  cr .( I2C_SCL_PIN not in environment ) abort [THEN]

forth-wordlist ext-wordlist 2 set-order definitions

: i2c_init
  S" I2C_SDA_PIN" environment? drop
  S" I2C_SCL_PIN" environment? drop
  Wire.begin
  Wire.reset
;

S" DS3231_ADDRESS" environment? [IF] constant DS3231_ADDRESS

forth-wordlist ext-wordlist 2 set-order definitions

: ds3231_clear
  DS3231_ADDRESS
  Wire.beginTransmission
  if
  0 Wire.sendByte if		\ address 0
	0 Wire.sendByte if		\ seconds
	  0 Wire.sendByte if		\ minute
	    0 Wire.sendByte if		\ horus
	      cr ." Okay"
        then
      then
    then
  then
  then
;

: ds3231_dump
  DS3231_ADDRESS
  dup Wire.beginTransmission 0= abort" Failed to start transmission on dump"
  0 Wire.sendByte 0= abort" Failed to send address 0 on dump"
  Wire.endTransmission
  Wire.requestFrom 0= abort" Failed request from"

  19 0 do
    Wire.read here i + c! 
  loop
  Wire.doneRead
  here 18 dump

  here 0 + c@ cr ." Seconds " dup 4 rshift 15 and [char] 0 + emit 15 and [char] 0 + emit
  here 1 + c@ cr ." Minutes " dup 4 rshift 15 and [char] 0 + emit 15 and [char] 0 + emit
  here 2 + c@ cr ." Hours " dup 32 and if [char] 1 emit then
                            dup 15 and [char] 0 + emit
                            dup 64 and if ."  pm" else ."  am" then
                            128 and if ."  [12hr]" else ."  [24hr]" then
  here 3 + c@ cr ." Day " .
  here 4 + c@ cr ." Date " dup 16 and if [char] 1 emit then 15 and [char] 0 + emit
  here 5 + c@ cr ." Month " dup 16 and if [char] 1 emit then dup 15 and [char] 0 + emit 128 and if ."  +century" then

;

[THEN]

S" AT24C32_ADDRESS" environment? [IF] constant AT24C32_ADDRESS

forth-wordlist ext-wordlist 2 set-order definitions

: eeprom@
  AT24C32_ADDRESS Wire.beginTransmission if
    dup 8 rshift 15 and Wire.sendByte if
	  15 and Wire.sendByte if
	    Wire.endTransmission
	    AT24C32_ADDRESS Wire.requestFrom if
		  Wire.read exit
        then
      then
   then
  then
  1 abort" failed"
;

: eeprom!
  AT24C32_ADDRESS Wire.beginTransmission if
    dup 8 rshift 15 and Wire.sendByte if
	  15 and Wire.sendByte if
	    Wire.endTransmission
		Wire.sendByte if
			exit
        then
      then
    then
  then
  1 abort" failed"
;

: eeprom-dump
	cr ." todo "
;

[THEN]

only forth definitions

