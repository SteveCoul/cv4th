
get-order internals swap 1+ set-order

: list-of-wordlists		\ widN .. wid1 n --
  0 A_LIST_OF_WORDLISTS >r

  begin
    r@ @ ?dup
  while					\ widN .. wid1 n next -- R: ptr --
	swap 1+
    r> @ 1 cells - >r
  repeat  
  r> drop
;

: get-first-word-each-wid		{: n -- :}	\ widN .. wid1 n --
  n 0 ?do
    n 1- roll ?dup if @ then
  loop
  n
;

: drop-empty			\ widN .. wid1 n --
  0 
  begin
    over
  while 
    rot 
	?dup if
      >r 1+
    then
    swap 1- swap
  repeat
  nip
  0
  begin
    2dup <>
  while
  	r> 
	rot rot 1+
  repeat
  drop 	
;

: get-highest	{: | idx val -- }		\ widN .. wid1 n -- widN .. wid1 n index-of-highest-wid
  -1 to idx
  0 to val
  dup 0 ?do
    i 1+ pick val > if
		i 1+ pick to val
		i 1+ to idx
	then
  loop
  idx
;

: show
	cr ." Word lists look like : " dup 0 ?do i 1+ pick . space loop
;

: n>r		\ xN .. x1 x -- : R x1 .. xN
  begin
    ?dup
  while
    swap 
	r> swap >r >r
    1-
  repeat
;

: nr>		
  begin	
	?dup
  while
    r> r> swap >r
	swap 1-
  repeat
;

: pick@		{: N -- } \ a-addrN .. a-addr1 count N -- a-addrN .. a-addr1 count   : fetch in place at the Nth stack item
  N n>r
  @
  N nr>
;

: for-each-word-in-order	{: xt | -- }
  list-of-wordlists
  get-first-word-each-wid
  drop-empty
  begin
    dup
  while			\ widN .. wid1 n --
	get-highest	>r 
	r@ pick xt execute
    r> pick@
    drop-empty
  repeat
  drop
;

: (show)
  cr 4 + 1 + count type
;

: all-words ['] (show) for-each-word-in-order ;

variable last-word 
variable line-counter
variable total-s
variable header-s
variable code-s
variable print-over

: (size)
  line-counter @ 0= if
	cr ." Total-Size  Header-Size Code-Size"
	20 line-counter !
  then
  -1 line-counter +!
  last-word @ over - 	\ head total-size --
  over last-word !
  over 4 + 1 + c@ 6 +	\ head total-size header-size
  2dup -				\ head total-size header-size code-size
  dup print-over @ > if
		  cr rot 
		  dup total-s +! 10 .r space 
		  swap dup header-s +! 10 .r space 
		  dup code-s +! 10 .r space 4 + 1 + count type
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
  total-s @ cr . space ." bytes total, " header-s @ . space ." used for headers and " code-s @ . space ." for code"
;


: size-words-over
  print-over !
  (size-words)
;

: size-words 
  0 print-over !
  (size-words)
;

