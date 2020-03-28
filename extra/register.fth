
require kernel/structure.fth

ext-wordlist forth-wordlist 2 set-order

\ ---------------------------------------------------------
private-namespace

64 buffer: temp_name

: (+tmp_name)	\ c-addr u --
  temp_name count + >r
  dup temp_name c@ + temp_name c!
  r> swap move
;

: +tmp_name		\ caddr --
  count (+tmp_name) ;

: >tmp_name 0 temp_name c! +tmp_name ;

\ ---------------------------------------------------------
private-namespace

: >name 5 + ; \ HACK

variable rlink
variable blink
variable base_address
variable byte_offset
variable bit_offset

begin-structure dreg
	1 cells +field	dreg.link	\ must be first
	1 cells +field	dreg.name
	1 cells +field	dreg.addr
	1 cells +field	dreg.size
	1 cells +field	dreg.list
	1 cells +field	dreg.alen
end-structure

begin-structure dbit
	1 cells +field	dbit.link	\ must be first
	1 cells +field	dbit.addr
	1 cells +field  dbit.size
	1 cells +field	dbit.regmask
	1 cells +field	dbit.valmask
	1 cells +field	dbit.valshift
	1 cells +field	dbit.multiplier
	1 cells +field	dbit.fetch
	1 cells +field	dbit.store
end-structure

\ ---------------------------------------------------------
private-namespace

: nbits				\ num -- val 
  0 swap 0 ?do
    1 lshift 1 or
  loop
;

: .hex32			( u -- )	
  base @ >r hex 0 <# # # # # # # # # S" 0x" holds #> type r> base ! ;
: .hex				( u -- )	
  base @ >r hex 0 <# #s S" 0x" holds #> type r> base ! ;

\ ---------------------------------------------------------
private-namespace

64 buffer: bank_name

ext-wordlist set-current

: register-bank
  parse-name dup bank_name c! bank_name 1+ swap move
  0 byte_offset !
  base_address !
  bank_name count ($create) 
	here rlink !
	0 , 
  does> 
	cr ." Register bank"
	@ ?dup if
		begin
			?dup
		while
			cr
			dup dreg.addr @ .hex32 space 
			dup [char] + emit dreg.size @ . space
			dup dreg.name @ count type		
			dup dreg.alen @ ?dup if
				."  [0] " 
				1 ?do
					cr
					dup dreg.addr @ 
					over dreg.size @ i * +
					.hex32 space 
					dup [char] + emit dreg.size @ . space
					dup dreg.name @ count type		
					space [char] [ emit i . [char] ] emit
				loop
			then
			@
		repeat
	then
;

: end-register-bank ;

\ ---------------------------------------------------------
ext-wordlist set-current

: 8bit 1 ;
: 16bit 2 ;
: 32bit 4 ;

: element ;

\ ---------------------------------------------------------
private-namespace

variable in_array
variable current_register
64 buffer: register_name

: (register)
  in_array !
  parse-name 
  dup register_name c! register_name 1+ swap move
  bank_name >tmp_name
  c" ." +tmp_name
  register_name +tmp_name
  0 bit_offset !
  temp_name count ($create) 
	here current_register !
	here dreg allot					( size ^dreg -- )
	dup rlink @ !
	dup dreg.link rlink !
	get-current @ >name over dreg.name !
	base_address @ byte_offset @ + over dreg.addr ! 
	0 over dreg.list !
	dup dreg.list blink !		( size ^dreg -- )
	2dup dreg.size !		
	in_array @ if			( #elements? size ^dreg -- )
		2 pick swap dreg.alen !
		* 
	else
		0 swap dreg.alen !
	then
	byte_offset +!
  does> 
	cr ." Register " dup dreg.addr @ . ." , size " dreg.size @ .
;

ext-wordlist set-current

: register 0 (register) ;
: end-register ;

: register-array 1 (register) ;
: end-register-array ;

\ ---------------------------------------------------------
ext-wordlist set-current

: skip-byte byte_offset +! ;
: skip-bit bit_offset +! ;

\ ---------------------------------------------------------
private-namespace

\ by default register banks work in device memory
\ I may add an API to change that later
: default8@  0  d8@ ;
: default8!  0  d8! ;
: default16@ 0 d16@ ;
: default16! 0 d16! ;
: default32@ 0 d32@ ;
: default32! 0 d32! ;

: fsxt					( regsiter -- fetchXt storeXt )
  case
  8bit of ['] default8@ ['] default8! rot endof
  16bit of ['] default16@ ['] default16! rot endof
  32bit of ['] default32@ ['] default32! rot endof
  1 abort" Illegal register size"
  endcase
;

: common				( bit-size c-addr u -- fetch store )
  ($create)
	here dbit allot
	dup blink @ !
	dup dbit.link blink !
	2dup dbit.size !
	current_register @ 0 cells + @ over dbit.addr !				( size dbit -- )
    over nbits bit_offset @ lshift invert over dbit.regmask !
    swap nbits over dbit.valmask !		( dbit -- )
    bit_offset @ over dbit.valshift !
	in_array @ if
		current_register @ dreg.size @ 
	else
		0
	then
	over dbit.multiplier !
	dup current_register @ dreg.size @ fsxt		
	rot dbit.store !
	swap dbit.fetch !
;

: bit-store				( bit-size c-addr u -- )
  common
  does>
	( {mightbeindex?} dbit -- )
	dup dbit.multiplier @  dup if		( index dbit multiplier -- )
		rot *							( dbit offset -- )
	then
	swap >r
	r@ dbit.addr @ +
	( newval address -- R: dbit -- )
	swap r@ dbit.valmask @ and
	r@ dbit.valshift @ lshift swap
	( val address -- R: dbit -- )
	dup r@ dbit.fetch @ execute
	( val address reg -- R: dbit -- )
	r@ dbit.regmask @ and
	rot or swap
	( newreg address -- R: dbit -- )
	r> dbit.store @ execute
;

: bit-fetch				( bit-size c-addr u -- )
  common
  does>
	( {mightbeindex?} dbit -- )
	dup dbit.multiplier @  dup if		( index dbit multiplier -- )
		rot *							( dbit offset -- )
	then
	( dbit offset -- )
	over dbit.addr @ +
    over dbit.fetch @ execute
	over dbit.valshift @ rshift
	swap dbit.valmask @ and
;

ext-wordlist set-current

: bit 
  bank_name >tmp_name
  c" ." +tmp_name
  register_name +tmp_name
  c" ." +tmp_name
  parse-name (+tmp_name)
  
  dup c" @" +tmp_name temp_name count bit-fetch
  temp_name dup c@ 1- swap c!
  dup c" !" +tmp_name temp_name count bit-store

  bit_offset +!
;

\ ---------------------------------------------------------

only forth definitions

