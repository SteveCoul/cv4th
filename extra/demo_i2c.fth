


forth-wordlist ext-wordlist 2 set-order definitions

: i2c_init
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
  true Wire.endTransmission
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
	  255 and Wire.sendByte if
	    true Wire.endTransmission
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
	  255 and Wire.sendByte if
		Wire.sendByte if
	    	true Wire.endTransmission
			exit
        then
      then
    then
  then
  1 abort" failed"
;

: eeprom-dump
  base @ >r hex
  over +	

  begin			\ ptr end --
	2dup <
  while
    cr
    over 0 <# # # # # # # # # #> type ." : "

	16 0 do	
		over i + over < if over i + eeprom@ 0 <# # # #> type bl emit else 3 spaces then
		i 7 = if space then
	loop

	[char] | emit space

	16 0 do
	    over i + over < if over i + eeprom@ aschar emit then
	loop

    swap 16 + swap 
  repeat
  2drop
  cr
  r> base !
;

: >eeprom		( c-addr u eeprom-addr --)
  >r
  begin
    ?dup
  while
    over c@ r@ eeprom! 1 ms
	r> 1+ >r
    1 /string
  repeat
  r> 2drop
;

[THEN]

S" AS3935_ADDRESS" environment? [IF] constant AS3935_ADDRESS

forth-wordlist ext-wordlist 2 set-order definitions

: as3935@
  AS3935_ADDRESS Wire.beginTransmission 0= if
	drop
  else
    Wire.sendByte if
      false Wire.endTransmission
      AS3935_ADDRESS Wire.requestFrom if
	    Wire.read 
	    Wire.doneRead
	    exit
      then
    then
  then
  -1
;

: as3935-dump
  base @ >r
  hex

  cr 9 0 ?do i as3935@ 0 <# # # #> type space

  0 as3935@
  cr ." PWD " dup 1 and .
  cr ." AFE_GB " 1 rshift 31 and .

  1 as3935@
  cr ." WDTH " dup 15 and .
  cr ." NF_LEV " 4 rshift 7 and .

  2 as3935@
  cr ." SREJ " dup 15 and .
  cr ." MIN_NUM_LIGH " dup 4 rshift 3 and .
  cr ." CL_STAT " 6 rshift 1 and .

  3 as3935@
  cr ." INT " dup 15 and .
  cr ." MASK_DIST " dup 5 rshift 1 and .
  cr ." LCO_DIV " 6 rshift 3 and .

  4 as3935@
  cr ." S_LIG_L " .

  5 as3935@
  cr ." S_LIG_M " .

  6 as3935@
  cr ." S_LIG_MM " 31 and .

  7 as3935@
  cr ." DISTANCE " 63 and .

  8 as3935@
  cr ." TUN_CAP " dup 15 and .
  cr ." DISP_TRCO " dup 5 rshift 1 and .
  cr ." DISP_SRCO " dup 6 rshift 1 and .
  cr ." DISP_LCO " 7 rshift 1 and .
  r> base !
;

[THEN]

only forth definitions

