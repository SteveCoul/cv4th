

forth-wordlist ext-wordlist 2 set-order definitions

S" AT24C32_ADDRESS" environment? 0= [IF]
	cr .( AT24C32_ADDRESS not in environment ) abort [THEN]
constant AT24C32_ADDRESS

[UNDEFINED] Wire.begin [IF]
	cr .( No Wire implementation found ) abort
[THEN]

: eeprom@
  AT24C32_ADDRESS Wire.beginTransmission 
  dup 8 rshift 15 and Wire.write drop
  255 and Wire.write drop
  true Wire.endTransmission

  AT24C32_ADDRESS 1 true Wire.requestFrom if
    Wire.read 
  else
	-1
  then
;

: eeprom!
  AT24C32_ADDRESS Wire.beginTransmission 
  dup 8 rshift 15 and Wire.write drop
  255 and Wire.write drop
  Wire.write drop
  true Wire.endTransmission
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

