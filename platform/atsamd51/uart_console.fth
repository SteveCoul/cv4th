
require platform/atsamd51/uart.fth

ext-wordlist get-order 1+ set-order
open-namespace core

forth-wordlist set-current
\ private-namespace

: uart-emit			( char -- )		write ;
: uart-ekey			( -- char|-1 )	available? if read else -1 then ;
: uart-init			( -- )
  8 true 0 1 115200 start 
\  ['] uart-emit is (emit)
\  ['] uart-ekey is (ekey)
;

onboot: uart-console
	uart-init
onboot;

