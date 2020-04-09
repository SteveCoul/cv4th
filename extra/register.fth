require kernel/locals.fth
require kernel/structure.fth

ext-wordlist forth-wordlist 2 set-order 
open-namespace core
private-namespace

0x1234DEAD constant MAGIC

variable current-bank
variable current-register
variable current-register-size
variable current-array-size
variable byte-offset
variable bit-offset

ext-wordlist set-current

0 constant 8bit
1 constant 16bit
2 constant 32bit

private-namespace

: nbits				( n -- mask )
  0 swap 0 ?do
    1 lshift 1 or
  loop
;

: size>bytes		( reg-size -- nbytes )
  1 swap lshift
;

: size>bits			( reg-size -- nbits ) 
  size>bytes 8 *
;

: .hex32 base @ >r 0 hex <# # # # # # # # # S" 0x" holds #> type r> base ! ;

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
  0x1F and 20 lshift r> or  
  rot 3 and 30 lshift or	
  swap dup 32 = if drop 0 then 
  0x1F and 25 lshift or
;

: decode		( v -- regsize fieldsize fieldposition arraysize )
  dup 30 rshift 3 and swap
  dup 25 rshift 0x1F and dup 0 = if drop 32 then swap
  dup 20 rshift 0x1F and swap
  0xFFFF and
;

: decodeBits		( v -- first last )
  decode drop rot drop 	( size position -- )
  tuck + 1-
;

: decodeRegisterSize ( v -- size )
  decode drop 2drop 
;

: decodeArraySize ( v -- arraysize )
  decode nip nip nip
;

begin-structure bt
	1 cells +field	bt.address
	1 cells +field	bt.data
end-structure

variable is-first

: dump-register			\ nt -- flag
  dup link>xt >body
  cr
  is-first @ if				( nt dp -- )
    0 is-first !
  	dup bt.address @ ."   " .hex32
	dup bt.data @ decodeArraysize ?dup if
		[char] [ emit . [char] ] emit
    then
    space swap 4 spaces name>string type space
	bt.data @ decodeRegisterSize size>bits . ." bit register"
  else						( nt dp -- )
	4 spaces
    bt.data @ decodeBits
	[char] [ emit
    2dup = if
	  drop 5 .r
	else
      swap 2 .r [char] - emit 2 .r
	then
	[char] ] emit
    space name>string type 
  then
  true
;

: dump-bank				\ nt -- flag
  dup name>string cr cr ." Register " type
  link>xt >body r.wid @
  1 is-first !
  ['] dump-register swap traverse-wordlist
  true
;

: get-words				\ nt -- flag
  here @ 1+ cells here + !
  1 here +!
  true
;

\  bit hacky, assuming we have #words in wid cells left @ here!
: r-traverse-wordlist	\ xt wid --
  0 here !
  ['] get-words swap traverse-wordlist
  here @ if
    here here @ cells +	\ xt last --
    here @ 0 do
      2dup @ swap execute drop
	  1 cells -
    loop  
  then
  2drop
;

ext-wordlist set-current

: register-bank
  byte-offset !
  wordlist 
  create
	here dup current-bank ! >r bank allot	
	MAGIC r@ b.magic !
	r@ b.wid !
	r> drop
  does>
    b.wid @ ['] dump-bank swap r-traverse-wordlist
;

: skip-byte byte-offset +! ;
: skip-bit bit-offset +! ;
: element ;

: end-register-bank ;

private-namespace

: (register)			( arraysize size -- )
  current-register-size !
  current-array-size !
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

ext-wordlist set-current

: register				( size -- )
  0 swap (register)
;

: register-array		( arraylen size -- )
  (register)
;

private-namespace

0 [IF]
: dofetch				( address size -- v )
  dup 8bit = if
    drop c@
  else
	dup 16bit = if
		drop w@
	else
		drop @
	then
 then
;

: dostore				( data address size -- )
  dup 8bit = if
    drop c!
  else
	dup 16bit = if
		drop w!
	else
		drop !
	then
 then
;
[ELSE]
: dofetch				( address size -- v )
  dup 8bit = if
    drop 0 d8@
  else
	dup 16bit = if
		drop 0 d16@
	else
		drop 0 d32@
	then
 then
;

: dostore				( data address size -- )
  dup 8bit = if
    drop 0 d8!
  else
	dup 16bit = if
		drop 0 d16!
	else
		drop 0 d32!
	then
 then
;
[THEN]

\ TODO make these compiling words that make the masks etc and laydown literals and code.
\ then just execute them from the interpreter hook

: bitfetch				( arrayindex? pdata -- v )	{: | address regsize fieldsize fieldposition arraysize -- :}
  dup bt.address @ to address
  bt.data @ decode
  to arraysize
  to fieldposition
  to fieldsize
  to regsize

  arraysize if
    regsize size>bytes *
	address + to address
  then
  address regsize dofetch
  fieldposition rshift
  fieldsize nbits and
;

: bitstore				( v arrayindex? pdata -- )	{: | address regsize fieldsize fieldposition arraysize -- :}
  dup bt.address @ to address
  bt.data @ decode
  to arraysize
  to fieldposition
  to fieldsize
  to regsize

  arraysize if
    regsize size>bytes *
	address + to address
  then

(
  fieldsize regsize size>bits = fieldposition 0= and if
	address regsize dostore exit
  then
)

  ( v -- )
  fieldsize nbits and 
  fieldposition lshift
  ( newdata -- )
  address regsize dofetch
  ( newdata reg -- )
  fieldsize nbits fieldposition lshift invert
  and or
  address regsize dostore
;

: (bit)					( regsize fieldsize fieldposition arraysize address c-addr u -- )
  get-current >r current-register @ r.wid @ set-current
  ($create)
	r> set-current
	here >r bt allot	
	r@ bt.address !
	encode 
    r> bt.data !
  does>			( arrayindex? fetch=1/store=0 pdata -- )
	drop
;

ext-wordlist set-current

: bit					( size -- )
  dup >r
  current-register-size @ swap
  bit-offset @
  current-array-size @
  byte-offset @
  parse-name  
  (bit)
  r> bit-offset +!
;

: end-register 

  current-register-size @ dup size>bits 0 current-array-size @ byte-offset @  S" reg" (bit)

  current-array-size @ dup 0= if
    drop 1
  then
  current-register-size @ size>bytes * byte-offset +!
;

: end-register-array
  end-register
;

private-namespace

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

\ TODO redefine a deferred word called interpreter-hook so as to make a chain

: hook
  2dup + 1- c@ dup [char] @ =	( c-addr u last @ -- )
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
							r> [char] @ =
							state @ if
								swap 
								>body [literal]
								if ['] bitfetch else ['] bitstore then
								compile,
							else
								if ['] bitfetch else ['] bitstore then
								swap >body 
								swap execute
							then
							true
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

