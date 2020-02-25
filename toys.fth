
get-order internals swap 1+ set-order

create start

: drop-empty			\ widN .. wid1 n -- widN' .. wid1 n' ( no zeros in list )
  0
  begin		\ N..1 count stored --
    over
  while
	swap 1- swap rot	\ N...2 count' stored next --
	?dup if >r 1+ then
  repeat
  nip
  >r nr>
;

: get-highest
  0 >r -1 >r
  0 
  begin
    2dup <>
  while
	dup 2 + pick 
	r@ > if
		2r> 2drop
		dup dup 1+ >r 2 + pick >r
	then
	1+
  repeat
  drop r> drop r>
;

: pick@	n>r @ nr> drop ;

: for-each-word-in-order	{: xt | -- }
  \ get all wordlists 1st word pointer
  0 A_LIST_OF_WORDLISTS >r
  begin
    r@ @ ?dup
  while		
	@ swap 1+
    r> @ 1 cells - >r
  repeat  
  r> drop
  \ N...1 count --
  begin
    drop-empty
    ?dup
  while			\ widN .. wid1 n --
	get-highest	dup >r 
	pick xt execute
    r> pick@
  repeat
;

here start - cr . s"  bytes" type

: (show)
  cr link>name count type
;

: all-words ['] (show) for-each-word-in-order ;

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
;

: (size-words)
  0 total-s !
  0 header-s !
  0 code-s !
  0 line-counter ! here last-word ! ['] (size) for-each-word-in-order 
  total-s @ cr . ."  bytes total, " header-s @ . ."  used for headers and " code-s @ . ."  for code"
;


: size-words-over
  print-over !
  (size-words)
;

: size-words 
  0 print-over !
  (size-words)
;

: z" 
	postpone AHEAD
	[char] " parse
	here >r
	dup 1+ allot
	dup r@ + 0 swap c!
    r@ swap move
	postpone then
	r> [literal]
; immediate

