
require platform/atsamd51/uart.fth

forth-wordlist ext-wordlist 2 set-order

open-namespace platform/atsamd51/uart.fth

private-namespace

variable ignore_next_if_10

: uart-emit			( char -- )		
  dup 10 = if 13 write then
  write 
;

\ TODO - handle 3 char escape sequences
: uart-ekey			( -- char|-1 )	
  available? if 
    read 
    ignore_next_if_10 @ if
	  0 ignore_next_if_10 !
	  dup 10 = if drop recurse then
	then
    dup 13 = if
	  1 ignore_next_if_10 !
      drop 10
    then
  else -1 then 
;

ext-wordlist get-order 1+ set-order
open-namespace core

\ onboot: uart-console
\  0 ignore_next_if_10 !
\  8 true 0 1 115200 start 
\  ['] uart-emit is (emit)
\  ['] uart-ekey is (ekey)
\ onboot;

