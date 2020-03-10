
ext-wordlist get-order 1+ set-order

hex 68 constant ia decimal

: init
  PIN_D5 PIN_D6 Wire.begin
  Wire.reset
;

: clear
  Wire.beginTransmission
  0 Wire.sendByte if		\ address 0
	0 Wire.sendByte if		\ seconds
	  0 Wire.sendByte if		\ minute
	    0 Wire.sendByte if		\ horus
		  drop
	      cr ." Okay"
        then
      then
    then
  then
;

: show
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

