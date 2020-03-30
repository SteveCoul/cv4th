
require kernel/structure.fth

internals ext-wordlist forth-wordlist 3 set-order 
definitions

0x1234DEAD constant MAGIC

variable current-bank
variable current-register
variable current-register-size
variable current-array-size
variable byte-offset
variable bit-offset

0 constant 8bit
1 constant 16bit
2 constant 32bit

begin-structure bank
	1 cells +field	b.magic
	1 cells +field	b.wid
end-structure

begin-structure reg
	1 cells +field	r.wid
end-structure

(
	encoded info field
	|10|98765|43210|9876|5432109876543210
    |33|22222|22222|1111|111111
	|--|-----|-----|----|----------------
	|  |	 |	   |	|array size
	|  |     |     |unused
	|  |     |position
	|  |	 |	   |
	|  |size of field 
	|  |0 means32
	regsize
	00 8bit
	01 16bit
	10 32bit
	11 unused
)

: encode		( regsize fieldsize fieldposition arraysize -- v )
  0xFFFF and >r				
  0x1F and 16 lshift r> or  
  rot 3 and 30 lshift or	
  swap dup 32 = if drop 0 then 
  0x1F and 25 lshift or
;

: decode		( v -- regsize fieldsize fieldposition arraysize )
  dup 30 lshift 3 and swap
  dup 25 lshift 0x1F and dup 0 = if drop 32 then swap
  dup 20 lshift 0x1F and swap
  0xFFFF and
;

begin-structure bt
	1 cells +field	bt.address
	1 cells +field	bt.data
end-structure

: register-bank
  byte-offset !
  wordlist 
  create
	here dup current-bank ! >r bank allot	
	MAGIC r@ b.magic !
	r@ b.wid !
	r> drop
  does>
;

: skip-byte byte-offset +! ;
: skip-bit bit-offset +! ;
: element ;

: end-register-bank ;

: register				( size -- )
  0 current-array-size !
  current-register-size !
  wordlist 
  get-current >r current-bank @ b.wid @ set-current
  create
  r> set-current
	here dup current-register ! >r reg allot
	r@ r.wid !
	r> drop
    0 bit-offset !
  does>
;

: end-register 
  current-register-size @ byte-offset +!
;

: register-array		( arraylen size -- )
  swap current-array-size !
  register
;

: end-register-array
  current-register-size @ current-array-size @ * byte-offset +!
;

: bit					( size -- )
  get-current >r current-register @ r.wid @ set-current
  create
	r> set-current
	here >r bt allot	
	current-register-size @	
	over					
	bit-offset @				
	current-array-size @		
	encode
	r@ bt.data !
	byte-offset @ r> bt.address !
	bit-offset +!
  does>
    drop
;

: token		( c-addr u -- c-addr-rem u-rem c-addr-tok u-tok )
  2dup
  begin
	over c@ [char] . <> 
	over 0 <>
    and
  while
    1 /string
  repeat
  ?dup 0= if
	drop 0 0 
  else	
	1 /string 2swap
    2 pick 1+ -
  then
;

: token1		( c-addr u -- c-addr' u' )
  token 2swap 2drop 
;
	
: token2		( c-addr u -- c-addr' u' )
  token 2drop token 2swap 2drop 
;

: token3		( c-addr u -- c-addr' u' )
  token 2drop token 2drop 
;	

: hook
  2dup + 1- dup c@ [char] @ =	( c-addr u last @ -- )
  swap [char] ! = or if
	( c-addr u -- ) 
	2dup + 1- c@ >r			\ store last char
	1-
	2dup token1 dup if	
		2>r					\ store 1st token
		2dup token2 dup if
			2>r
			token3 2r> 2r> 		\ t3 tu3 t2 tu2 t1 tu1 : R lc -- 
			$find 0= if
				r> drop
				2drop 2drop
				false
			else
				>body dup b.magic @ MAGIC <> if
				  drop 2drop 2drop r> drop false
				else
					b.wid @ search-wordlist 0= if
						2drop r> drop false
					else
						( t3 tu3 xt2 -- R: lc -- )
						>body r.wid @ search-wordlist if
							( bit -- R: lc -- )
							cr ." TODO - compile?"
							execute
							r> drop true
						else
							r> drop
							false
						then
					then
				then
			then
		else
			2drop 2drop 2r> 2drop r> drop
			false
		then
	else
		2drop 2drop r> drop false
	then
  else
    2drop false
  then
;

' hook is interpreter-hook

only forth definitions


