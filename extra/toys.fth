
( Just random stuff )

only forth definitions
internals ext-wordlist get-order 2 + set-order

internals set-current

variable last-word 
variable line-counter
variable total-s
variable header-s
variable code-s
variable print-over

: (size)
  -1 line-counter +!
  last-word @ over - 	\ head total-size --
  over last-word !
  over link>name c@ 1 cells + 2 +	\ head total-size header-size
  2dup -				\ head total-size header-size code-size
  dup print-over @ > if
          line-counter @ 0= if
            cr ." Total-Size  Header-Size Code-Size"
        	20 line-counter !
          then
		  cr rot 
		  dup total-s +! 10 .r space 
		  swap dup header-s +! 10 .r space 
		  dup code-s +! 10 .r space link>name ctype
  else
		  rot 
		  total-s +! 
		  swap header-s +!
		  code-s +!
		  drop
  then
  true
;

: (size-words)
  0 total-s !
  0 header-s !
  0 code-s !
  0 line-counter ! here last-word ! ['] (size) traverse-all-wordlists
  total-s @ cr . ."  bytes total, " header-s @ . ."  used for headers and " code-s @ . ."  for code"
;

ext-wordlist set-current

: size-words-over
  print-over !
  (size-words)
;

: size-words 
  0 print-over !
  (size-words)
;

: device-dump		\ a-addr len --													
  base @ >r hex
  over +	

  begin			\ ptr end --
	2dup <
  while
    cr
    over .8 ." : "

	16 0 do	
		over i + over < if over i + 0 d8@ .2 bl emit else 3 spaces then
		i 7 = if space then
	loop

	[char] | emit space

	16 0 do
	    over i + over < if over i + 0 d8@ aschar emit then
	loop

    swap 16 + swap 
  repeat
  2drop
  cr
  r> base !
;


