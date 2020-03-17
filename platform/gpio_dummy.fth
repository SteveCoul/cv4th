
ext-wordlist set-current

 0 constant INPUT
 1 constant OUTPUT
 2 constant INPUT_PULLUP

 1 constant HIGH
 0 constant LOW

: pinMode		( pin mode -- )
  2drop
;

: writeDigital	( pin level -- )
  2drop
;

: readDigital	( pin -- value )
  drop 0
;

only forth definitions


