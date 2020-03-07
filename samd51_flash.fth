
ext-wordlist forth-wordlist internals 3 set-order definitions

S" /FLASH_BASE" environment? 0= [IF]  cr .( /FLASH_BASE not in environment ) abort [THEN] constant FLASH_BASE
S" /FLASH_SIZE" environment? 0= [IF]  cr .( /FLASH_SIZE not in environment ) abort [THEN] constant FLASH_SIZE

: flash_write		( flash-address source len -- errorflag )
  cr ." Flash base " FLASH_BASE .
  cr ." Flash Write " over . ." :" dup . ."  -> " 2 pick .
  2drop drop 1
;

: flash_read		( dest flash-address len -- errorflag )
  cr ." Flash base " FLASH_BASE .
  cr ." Flash Read from " over . ."  -> " 2 pick . ." :" dup .
  2drop drop 1
;

only forth definitions

