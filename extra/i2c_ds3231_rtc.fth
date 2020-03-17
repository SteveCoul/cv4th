
forth-wordlist ext-wordlist 2 set-order definitions

S" DS3231_ADDRESS" environment? 0= [IF]
	cr .( DS3231_ADDRESS not in environment ) abort [THEN]
constant DS3231_ADDRESS

[UNDEFINED] Wire.begin [IF]
	cr .( No Wire implementation found ) abort
[THEN]

: ds3231_clear
  DS3231_ADDRESS
  Wire.beginTransmission
  0 Wire.write drop
  0 Wire.write drop
  0 Wire.write drop
  0 Wire.write drop
  true Wire.endTransmission
;

: ds3231_dump
  DS3231_ADDRESS
  dup Wire.beginTransmission 
  0 Wire.write drop
  true Wire.endTransmission

  19 true Wire.requestFrom
  19 <> abort" didn't get enough data"

  19 0 do
    Wire.read here i + c! 
  loop

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

only forth definitions


