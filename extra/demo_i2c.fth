
broken

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

