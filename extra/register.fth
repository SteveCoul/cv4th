
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

variable base_address
variable byte_offset
variable bit_offset

\ ---------------------------------------------------------
private-namespace

: nbits				\ num -- val 
  0 swap 0 ?do
    1 lshift 1 or
  loop
;

: .hex				( u -- )	
  base @ >r hex 0 <# #s S" 0x" holds #> type r> base ! ;

\ ---------------------------------------------------------
private-namespace

64 buffer: bank_name

ext-wordlist set-current

: register-bank
  parse-name dup bank_name c! bank_name 1+ swap move
  0 byte_offset !
  dup base_address !
  bank_name count ($create) , does> cr ." Registers at " @ .
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
	base_address @ byte_offset @ + , 
	dup ,
	in_array @ if
		* 
	then
	byte_offset +!
  does> 
	cr ." Register " dup @ . ." , size " 1 cells + @ . 
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

: common				( bit-size c-addr u -- fetch store )
  ($create)
	current_register @ 0 cells + @ ,		\ address
	dup nbits bit_offset @ lshift invert ,	\ and reg mask	
    nbits ,									\ and val mask
	bit_offset @ ,							\ val shift
	in_array @ if
		current_register @ 1 cells + @ ,	\ register size (multiplier)
	else
		0 ,
	then

	current_register @ 1 cells + @			\ register size

	case 
	8bit of ['] d8@ ['] d8! rot endof
	16bit of ['] d16@ ['] d16! rot endof
	32bit of ['] d32@ ['] d32! rot endof
	1 abort" illegal register size"
	endcase
;

: bit-store				( bit-size c-addr u -- )
  common
	nip ,
  does>
	cr ."  Address " dup 0 cells + @ .hex
	   ."  Mask " dup 1 cells + @ .hex
	   ."  Val Mask " dup 2 cells + @ .hex
	   ."  Position " dup 3 cells + @ .
	   dup 4 cells + @ ?dup if ."  In array. size*index is " rot * . then
	   dup 5 cells + @ ."  xt " .hex
    drop
;

: bit-fetch				( bit-size c-addr u -- )
  common
	drop ,
  does>
	cr ."  Address " dup 0 cells + @ .hex
	   ."  Mask " dup 1 cells + @ .hex
	   ."  Val Mask " dup 2 cells + @ .hex
	   ."  Position " dup 3 cells + @ .
	   dup 4 cells + @ ?dup if ."  In array. size*index is " rot * . then
	   dup 5 cells + @ ."  xt " .hex
    drop
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

ext-wordlist get-order 1+ set-order

0 register-bank GCLK
	8bit register CTRLA
		1 bit swrst
	end-register
	3 skip-byte
	32bit register SYNCBUSY
		1 bit swrst
		1 skip-bit
		12 bit genctrl
	end-register
	24 skip-byte
	12 element 32bit register-array GENCTRLn
		5 bit src
		3 skip-bit
		1 bit genen
		1 bit idc
		1 bit oov
		1 bit oe
		1 bit divsel
		1 bit runstdby
		2 skip-bit
		16 bit div
	end-register-array
	48 skip-byte
	48 element 32bit register-array PCHCTRLn
		4 bit gen
		2 skip-bit
		1 bit chen
		1 bit wrtlock	
	end-register-array
end-register-bank
	
	
