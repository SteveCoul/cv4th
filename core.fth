
: >flag				4 + ;														

: \
  #tib @ >in !
; 
OPCODE_IMMEDIATE forth-wordlist @ >flag c!
\ Apologies for the above magic, it makes the comment word immediate so I can use it

\ ---------------------------------------------------------------------------------------------

\ These words are defined in the native wrapper 

\ NATIVE: open-file																\ \ FILE
\ NATIVE: create-file															\ \ FILE
\ NATIVE: close-file															\ \ FILE
\ NATIVE: read-file																\ \ FILE
\ NATIVE: write-file															\ \ FILE
\ NATIVE: write-file															\ \ FILE
\ NATIVE: delete-file															\ \ FILE
\ NATIVE: file-position															\ \ FILE
\ NATIVE: file-size																\ \ FILE
\ NATIVE: file-status															\ \ FILE
\ NATIVE: flush-file															\ \ FILE
\ NATIVE: resize-file															\ \ FILE
\ NATIVE: rename-file															\ \ FILE
\ NATIVE: r/o																	\ \ FILE
\ NATIVE: w/o																	\ \ FILE
\ NATIVE: r/w																	\ \ FILE
\ NATIVE: nip																	\ \ CORE-EXT
\ NATIVE: rot																	\ \ CORE
\ NATIVE: tuck																	\ \ CORE-EXT
\ NATIVE: roll																	\ \ CORE-EXT
\ NATIVE: 2dup																	\ \ CORE
\ NATIVE: 2drop																	\ \ CORE
\ NATIVE: 2over																	\ \ CORE
\ NATIVE: 2swap																	\ \ CORE
\ NATIVE: forth-wordlist														\ \ SEARCH-ORDER
\ NATIVE: INTERNALS																\ \ INTERNAL
\ NATIVE: w@																	\ \ INTERNAL
\ NATIVE: w!																	\ \ INTERNAL
\ NATIVE: BYE																	\ \ INTERNAL
\ NATIVE: sp@ 																	\ \ INTERNAL
\ NATIVE: sp! 																	\ \ INTERNAL
\ NATIVE: rsp@ 																	\ \ INTERNAL
\ NATIVE: rsp! 																	\ \ INTERNAL
\ NATIVE: here																	\ \ CORE
\ NATIVE: state																	\ \ CORE
\ NATIVE: tib																	\ \ DEAD?
\ NATIVE: #tib																	\ \ DEAD?
\ NATIVE: >in																	\ \ CORE
\ NATIVE: base																	\ \ CORE
\ NATIVE: move																	\ \ CORE
\ NATIVE: depth																	\ \ CORE
\ NATIVE: over																	\ \ CORE
\ NATIVE: dup																	\ \ CORE
\ NATIVE: pick																	\ \ CORE-EXT
\ NATIVE: @																		\ \ CORE
\ NATIVE: =																		\ \ CORE
\ NATIVE: !																		\ \ CORE
\ NATIVE: not																	\ \ ???
\ NATIVE: or																	\ \ CORE
\ NATIVE: and																	\ \ CORE
\ NATIVE: c!																	\ \ CORE
\ NATIVE: c@																	\ \ CORE
\ NATIVE: drop																	\ \ CORE
\ NATIVE: emit																	\ \ CORE
\ NATIVE: *																		\ \ CORE
\ NATIVE: -																		\ \ CORE
\ NATIVE: >																		\ \ CORE
\ NATIVE: <																		\ \ CORE
\ NATIVE: +																		\ \ CORE
\ NATIVE: +!																	\ \ CORE
\ NATIVE: swap																	\ \ CORE
\ NATIVE: um/mod																\ \ CORE
\ NATIVE: execute																\ \ CORE
\ NATIVE: u< 																	\ \ CORE
\ NATIVE: u> 																	\ \ CORE-EXT


\ ---------------------------------------------------------------------------------------------

: get-current																	\ \ SEARCH-ORDER
  A_CURRENT @ 
;

: set-current																	\ \ SEARCH-ORDER
  A_CURRENT !
;

: immediate																		\ \ CORE
  OPCODE_IMMEDIATE
  get-current @ >flag
  c!
;

: [ 0 state !  ; immediate														\ \ CORE
: ] 1 state !  ;																\ \ CORE

: decimal 10 base ! ;															\ \ CORE
: hex 16 base ! ;																\ \ CORE-EXT

: 1- 1 - ;																		\ \ CORE
: 1+ 1 + ;																		\ \ CORE

: cells 4 * ;																	\ \ CORE
: cell+ 1 cells + ;																\ \ CORE
: chars ;																		\ \ CORE
: char+ 1+ ;																	\ \ CORE

: allot																			\ \ CORE
  A_HERE +!	
;

: c, here 1 allot c!  ;															\ \ CORE
: , here 1 cells allot !  ;														\ \ CORE

: r>																			\ \ CORE
  [ OPCODE_RFROM c, 
    OPCODE_RFROM c, 
    OPCODE_SWAP c, 
	OPCODE_TOR c, ]
; OPCODE_RFROM get-current @ >flag c!			\ set compile time behavior to lay opcode

: 2r>																			\ \ CORE EXT
  [ OPCODE_RFROM c, 
    OPCODE_RFROM c, 
	OPCODE_RFROM c,	
    OPCODE_SWAP c, 
	OPCODE_ROT c,
	OPCODE_TOR c, ]
; 

: r@																			\ \ CORE
  [
	OPCODE_RFROM c,
	OPCODE_RFROM c,
    OPCODE_DUP c,
    OPCODE_SWAP c,
	OPCODE_TOR c,
    OPCODE_SWAP c,
	OPCODE_TOR c,
  ]
; OPCODE_RFETCH get-current @ >flag c!

: >r																			\ \ CORE
  [
	OPCODE_RFROM c,
	OPCODE_SWAP c,
	OPCODE_TOR c,	
	OPCODE_TOR c,	
  ]
; OPCODE_TOR get-current @ >flag c!

: 2>r
  [	
	OPCODE_RFROM c,	
	OPCODE_ROT c,
	OPCODE_TOR c,
	OPCODE_SWAP c,
	OPCODE_TOR c,
	OPCODE_TOR c,
  ]
;

: 2r@ 																			\ \ CORE-EXT
  [ 
	OPCODE_RFROM c,
	OPCODE_RFROM c,
	OPCODE_RFROM c,		\ ret a b --
	OPCODE_ROT c,
	OPCODE_TOR c,
	OPCODE_SWAP c,
  ]
;

: negate 0 swap - ;																\ \ CORE

: true 1 ;																		\ \ CORE-EXT
: false 0 ;																		\ \ CORE-EXT

: bl 32 ;																		\ \ CORE
: cr 10 emit ;																	\ \ CORE

: 0= 0 = ;																		\ \ CORE
: 0< 0 < ;																		\ \ CORE

: 0<> 0= not ;																	\ \ CORE-EXT
: 0> 0 > ;																		\ \ CORE-EXT
: <> = not ;																	\ \ CORE-EXT

: within over - >r - r> u< ;													\ \ CORE-EXT

: if																			\ \ CORE
  OPCODE_JUMP_EQ_ZERO c,
  here 
  0 ,
; immediate

: else																			\ \ CORE
  OPCODE_JUMP c,
  here
  0 ,
  swap here swap !
; immediate

: then																			\ \ CORE
  here swap !
; immediate

: begin																			\ \ CORE
  here
; immediate

: until																			\ \ CORE
  OPCODE_JUMP_EQ_ZERO c,
  ,
; immediate

: while																			\ \ CORE
  OPCODE_JUMP_EQ_ZERO c,
  here swap
  0 ,
; immediate

: repeat																		\ \ CORE
  OPCODE_JUMP c,
  ,
  here swap !
; immediate

: get-order																		\ \ SEARCH-ORDER
  0 0 begin
    dup SIZE_ORDER <>
  while						\ widN .. wid1 N i --
	A_ORDER over cells + @	\ widN .. wid1 N i ? --
    dup if
      rot 1+ rot			\ widN .. wid1 ? N+1 i --
    else
	  drop
	then
    1+
  repeat 
  drop
;  

: set-order																		\ \ SEARCH-ORDER
  dup -1 = if
	drop 
	forth-wordlist 1
  then

  0
  begin
	dup SIZE_ORDER <>
  while
    dup cells A_ORDER + 0 swap !
	1+
  repeat
  drop

  dup 1- cells A_ORDER +		\ widN .. wid1 N addr --
  begin
    over 
  while
    rot			\ widN ... N addr wid1 --
	over !
    1 cells - swap 1- swap
  repeat
  2drop
;

internals set-current
: locals-count					\ how to create a variable badly :-)
  [ OPCODE_DOLIT c, here 9 + ,
	OPCODE_JUMP c, here 8 + ,
    0 ,
  ]
;
: locals-here					\ how to create a variable badly :-)
  [ OPCODE_DOLIT c, here 9 + ,
	OPCODE_JUMP c, here 8 + ,
    0 ,
  ]
;
forth-wordlist set-current

get-order internals swap 1+ set-order internals set-current
: end-locals
  locals-count @ if
	OPCODE_LPFETCH c,
	OPCODE_DOLIT c, 0 ,
	OPCODE_LFETCH c,
	OPCODE_LPSTORE c,
	OPCODE_RSPSTORE c,
    0 locals-count !
  then
;

: compile-l@
  OPCODE_DOLIT c, ,	
  OPCODE_LFETCH c,
;

forth-wordlist set-current

: exit end-locals OPCODE_RET c, ; immediate										\ \ CORE

: ?dup dup 0= if exit then dup ;												\ \ CORE

: also																			\ \ SEARCH-ORDER
  get-order over swap 1+ set-order
;

: forth																			\ \ SEARCH-ORDER
  get-order forth-wordlist swap 1+ set-order
;

: only																			\ \ SEARCH-ORDER
  -1 set-order
;

: wordlist																		\ \ SEARCH-ORDER
  here 0 ,
;

: definitions																	\ \ SEARCH-ORDER
  get-order over set-current
  begin ?dup while nip 1- repeat
;

: previous																		\ \ SEARCH-ORDER
  get-order nip 1- set-order
;

: type																			\ \ CORE
  begin 
	dup 0>
  while
    swap dup c@ emit
	1 + swap 1 -
  repeat
  2drop
;

internals set-current
: w,																			\ \ INTERNAL
  here 2 allot w!
;
forth-wordlist set-current

: count dup 1 + swap c@ ;														\ \ CORE

: literal OPCODE_DOLIT c, , ; immediate											\ \ CORE
: abs dup 0< if negate then ;													\ \ CORE

internals set-current
: should-skip	\ ( char delim -- flag )										\ \ INTERNAL
	dup bl = if
		over	
		= swap 9 =
		or
	else
		=
	then	
;
forth-wordlist set-current

internals set-current
: (parse) \ delimiter skip-char -- c-addr u										\ \ INTERNAL
  swap >r
  ?dup if
    >r
    begin
      >in @ #tib @ -
      0= if
        0
      else
        tib @ >in @ + c@ r@ should-skip
      then
    while
      1 >in +!
    repeat
    r> drop
  then
  r> 

  >in @ >r					\ delim -- R: first-idx --
  begin
    >in @ #tib @ -
	0= if
		0
	else
		tib @ >in @ + c@ over 			\ delim char delim --
		should-skip 0=
	then
  while
	1 >in +!
  repeat
  drop
  tib @ r@ +
  >in @ r> -
  >in @ #tib @ = not if 1 >in +! then	\ and the delimiter we hit goes too
;
forth-wordlist set-current

: parse 0 (parse) ;																\ \ CORE-EXT

: parse-name																	\ \ CORE-EXT
  bl bl (parse)
;

: word																			\ \ CORE

  \ makes a little buffer at compile time and gives me address at runtime. We can't parse 
  \ anything bigger than the size of the input buffer anyhow.
  [ OPCODE_JUMP c, here SIZE_INPUT_BUFFER + 4 + , here SIZE_INPUT_BUFFER allot ] literal

  >r
  bl (parse)
  dup r@ c!
  r@ 1+ swap move
  r>
;

: char																			\ \ CORE
  bl word count 0= if
    drop 0			
  else
    c@
  then
;

internals set-current
: [literal]																		\ \ INTERNAL
  OPCODE_DOLIT c, ,	
;
forth-wordlist set-current
 
: [char] char [literal] ; immediate 											\ \ CORE

: .																				\ \ CORE
  dup 0< if [char] - emit negate then		

  0 swap

  begin																						\ ( c n -- )
	0 base @ um/mod																			\ ( c r q -- )
	swap																					\ ( c q r -- )	
	[char] 0 +	dup [char] 9 > if 7 + then
	>r																						\ ( c q -- )
	swap 1+ swap																			\ ( C q -- )
    dup 0=
  until
  drop
	
  \ ( num-items on return stack )
  ?dup 0= if exit then
  begin
	r> emit
    1-
    ?dup 0=
  until
;

: order																			\ \ SEARCH-ORDER
  get-order 
  begin
    dup 0>
  while
    cr swap .
	1-
  repeat
  drop
;

: .(																			\ \ CORE-EXT
  [char] ) word count type
; immediate

: c" 																			\ \ CORE-EXT
  \ makes a little buffer at compile time and gives me address at runtime. We can't parse 
  \ anything bigger than the size of the input buffer anyhow.
  OPCODE_JUMP c, here 0 ,			\ patch-jump
  here							\ patch-jump where-to-store
  [char] " word count				\ patch-jump where-to-store text textlen
  dup 1+ allot
  here >r							\ 
  2 pick OPCODE_DOLIT c, ,		\ patch buffer text textlen --
  dup 3 pick c!
  rot 1+						\ patch text textlen buffer+1 --
  swap							\ patch text buffer+1 textlen --						
  move
  r> swap !
; immediate

: s"																			\ \ CORE / FILE-ACCESS
  state @ if
	OPCODE_JUMP c, here 0 ,			\ patch-jump
	here							\ patch-jump where-to-store
	[char] " word count				\ patch-jump where-to-store text textlen
	dup allot
	here >r							\ 
	2 pick OPCODE_DOLIT c, ,		\ 
	dup OPCODE_DOLIT c, ,			\ 
	>r swap r> move
	r> swap !
  else
	  \ makes a little buffer at compile time and gives me address at runtime. We can't parse 
  	  \ anything bigger than the size of the input buffer anyhow.
  	  [ OPCODE_JUMP c, here SIZE_INPUT_BUFFER + 4 + , here SIZE_INPUT_BUFFER allot ] literal
      [char] " word count			\ tmp c-addr u --
      swap 2 pick 2 pick			\ tmp u c-addr tmp u --
	  move
  then
; immediate

internals set-current
: head>name			>flag 1 + ;													\ \ INTERNAL
forth-wordlist set-current

: search-wordlist	\ c-addr u wid -- 0 | xt 1 | xt -1 							\ \ SEARCH-ORDER
	@	
	?dup 0= if 2drop 0 exit then

	begin					
		over over head>name c@ =				
		if
			2 pick 2 pick						
			2 pick head>name 1 + swap				
			[ OPCODE_COMPARE c, ]
			0= if 
														\ c-addr u link --
				nip nip
				dup 
				head>name count + 						
				swap >flag c@ OPCODE_IMMEDIATE = if
					1
				else
					-1
				then
				exit
			then
		then
	  @
	?dup 0= until
	2drop 0
;

internals set-current

: forget-locals	0 locals-wordlist !	;											\ \ INTERNAL

forth-wordlist set-current

: find		\ ( c-addr -- c-addr 0 | xt 1 | xt -1 )								\ \ CORE SEARCH-WORDLIST
  >r
  get-order		\ widN ... wid1 wid-count -- : R: c-addr --
  locals-wordlist swap 1+
  ?dup 0= if r> 0 exit then
  begin
 	1- swap
 	r@ count rot
 	search-wordlist 
	?dup if 	\ widN .. wid1 wid-count xt flag -- R: c-addr --
 	  r> drop
 	  >r >r					\ widN .. wid1 wid-count -- R: flag xt --
 	  begin dup if nip 1- then ?dup 0= until	\ Ndrop
 	  r> r> exit
    then
	\ widN .. wid1 wid-count
    ?dup 0=
  until
  r> 0
;

internals set-current
: (abort)																		\ \ INTERNAL
	0 sp!
   	0 rsp!
	0 state !
	forget-locals
    A_QUIT @	
	?dup if
		 [ OPCODE_JUMPD c, ]	\ don't return from here, off and running
	then
    cr s" (abort) under bootstrap" type cr
	\ if no interpreter we RET, which in the VM means return and it'll run a new loop
;
forth-wordlist set-current

internals set-current
: exception-handler			\ how to create a variable badly :-)
  [ OPCODE_DOLIT c, here 9 + ,
	OPCODE_JUMP c, here 8 + ,
    0 ,
  ]
;
forth-wordlist set-current

: catch																			\ \ EXCEPTION
  sp@ >r
  exception-handler @ >r
  rsp@ exception-handler !
  execute
  r> exception-handler !
  r> drop
  0
;

: throw																			\ \ EXCEPTION

  ?dup if

	exception-handler @ 0= if
		dup -1 = if
			(abort)
		then
		dup -2 = if
			cr s" [THROW (nohandler)] " type
			here count type cr		
			(abort)
		then
		cr s" [THROW (nohandler)] Exception #" type . cr
		(abort)
	then

    exception-handler @ rsp!
    r> exception-handler !
	r> swap >r
	sp! drop r>
  then
;

: abort																			\ \ CORE EXCEPTION
  -1 throw
; 

: '																				\ \ CORE
	bl word 
	find
	0= if
		cr s" word not found" type abort
	then
; 

: <#																			\ \ CORE
  0
  A_PICTURED_NUMERIC SIZE_PICTURED_NUMERIC
  + 1- 
  c!
;

: hold																			\ \ CORE
  A_PICTURED_NUMERIC SIZE_PICTURED_NUMERIC
  + 1- >r
  r@ dup c@ 1+ - c!
  r@ c@ 1+ r> c!
;

: holds																			\ \ CORE-EXT
  begin dup while 1- 2dup + c@ hold repeat 2drop
;

: #>																			\ \ CORE
  2drop 
  A_PICTURED_NUMERIC SIZE_PICTURED_NUMERIC
  + 1- dup >r
  dup c@ -
  r> c@
;

: #																				\ \ CORE
	base @ 
	um/mod 
	swap dup 9 > if 7 + then [char] 0 + hold
	0
;

: #s 																			\ \ CORE
	begin # 2dup or 0= until
;

: sign																			\ \ CORE
	0< if [char] - hold then	
;

internals set-current
: >name																			\ \ INTERNAL
  dup >r	\ p -- R: xt --
  begin
    1-
    dup count + r@ =
  until
  r> drop 
;

: >head																			\ \ INTERNAL
  >name
  1-
  1 cells -
;
forth-wordlist set-current

: [']																			\ \ CORE
	bl word find drop [literal]
; immediate

: compile,																		\ \ CORE-EXT
  dup >head >flag c@ dup OPCODE_IMMEDIATE = swap OPCODE_NONE = or if
	dup 65536 < if
		OPCODE_SHORT_CALL c, w,
	else
	  	OPCODE_CALL c, ,
	then
  else
    >head >flag c@ c,
  then
;

\ Obsolete and I don't need it either so not doing it
\ [compile]																		\ \ CORE-EXT

: postpone																		\ \ CORE
	bl word find ?dup 0= if		
		cr type s"  not found" type abort
	else
		1 = if 
			compile,
		else
			[literal]
			['] compile, 
			compile,
 		then
 	then
; immediate

: again																			\ \ CORE-EXT
  0 postpone literal
  postpone until
; immediate

: abort"																		\ \ CORE EXCEPTION
	postpone ?dup
	postpone if
	postpone s"
    postpone here	
    postpone dup
	postpone c!
    postpone here
 	postpone 1+
    postpone swap
    postpone move
	-2 [literal]
	postpone throw
    postpone then
; immediate

: ."																			\ \ CORE
	postpone s"
	postpone type
; immediate

: do		\ limit idx --														\ \ CORE
	OPCODE_DOLIT c,
	here				\ cs: here
	0 ,
	postpone >r			
	postpone >r
	postpone >r
    postpone begin		\ cs: here whatever
; immediate

: ?do		\ limit idx --														\ \ CORE-EXT
	postpone 2dup
	postpone =
	OPCODE_JUMP_EQ_ZERO c,
	here 
	0 ,
	
	OPCODE_DOLIT c,					\ get the resolv address at runtime N bytes on from here
	here 13 + ,
	OPCODE_FETCH c,
	\ 3 numbers to satisfy unloop after the jump (limit index, something random)
	OPCODE_DUP c, OPCODE_TOR c,
	OPCODE_SWAP c, OPCODE_TOR c,
	OPCODE_SWAP c, OPCODE_TOR c,	
	OPCODE_JUMPD c,
	
	here swap !
	OPCODE_DOLIT c,
	here				\ cs: here
	0 ,
	postpone >r			
	postpone >r
	postpone >r
    postpone begin		\ cs: here whatever
; immediate

: unloop																		\ \ CORE
  r>
  r> drop
  r> drop
  r> drop
  >r
;

: +loop 																		\ \ CORE
	postpone r>
	postpone r>		\ N limit idx --
    postpone rot	\ limit idx N --
    postpone +		\ limit IDX --
    postpone 2dup
	postpone >
	postpone not	\ limit IDX flag --
    postpone swap
	postpone >r
	postpone swap
	postpone >r
    postpone until
	here swap !
	postpone unloop
; immediate

: loop																			\ \ CORE
  1 [literal]
  postpone +loop
; immediate

: i																				\ \ CORE
  r> r> r>		\ rpick would be nice
  dup >r
  swap >r
  swap >r
;

: j																				\ \ CORE
  r> r> r> r> r> 
  dup >r
  swap >r
  swap >r
  swap >r
  swap >r
;

: leave																			\ \ CORE
	postpone r>
	postpone r>
	postpone r@
	postpone swap
	postpone >r
	postpone swap
	postpone >r
	OPCODE_JUMPD c,
; immediate

: case																			\ \ CORE-EXT
  0
; immediate

: endcase																		\ \ CORE-EXT
  0 ?do
	  postpone then
  loop
  postpone drop
; immediate

: of																			\ \ CORE-EXT
  postpone over
  postpone =
  postpone if
  swap 1+
; immediate

: endof																			\ \ CORE-EXT
  swap
  postpone else
  swap
; immediate

: space																			\ \ CORE
  bl emit
;

: spaces	\ n --																\ \ CORE
  begin
    dup 0>
  while
    space
    1-
  repeat
  drop
;

internals set-current
: >name 	 \ xt -- c-addr														\ \ INTERNAL
  dup >r
  begin
	1- 
	dup count + r@ =
  until
  r> drop
;
forth-wordlist set-current

: key																			\ \ CORE
  begin
    [ OPCODE_IN c, ]
	?dup 
  until
;

: :noname																		\ \ CORE-EXT
  0 here 		
  1 state !
;

: :																				\ \ CORE
  here 0				\ colon-sys --
  get-current @ ,
  OPCODE_NONE c,
  bl word 
  count dup c,			\ colon-sys c-addr u --
  here over allot		\ colon-sys c-addr u here --
  swap move
  1 state !
;

: ; 																			\ \ CORE
  end-locals
  OPCODE_RET c,
  ?dup 0= if
	get-current !
  else
    nip
  then
  0 state !
  forget-locals
; immediate

\ From this point on the bootstrap interpreter is no longer performing : and ; words
\ but the above FORTH code is doing the job.

: create																		\ \ CORE
  here 
  get-current @ ,
  get-current !					\ warning, I don't really want the definition on the wordlist until it's complete !
  OPCODE_NONE c,
  bl word count dup c,
  here over allot
  swap move

  OPCODE_DOLIT c,			\ not sure I really need this lit, I can just fix >body
  here 0 ,

  OPCODE_JUMP c,
  here cell+ ,
  OPCODE_RET c,

  here swap !
;

: >body 1+ @ ; 																	\ \ CORE

internals set-current
: (does>)																		\ \ INTERNAL
  get-current @ cell+ 1+ count + 1+ cell+ 1+ !
;
forth-wordlist set-current

: does>																			\ \ CORE
  end-locals
  \ the '10' is the DOLIT and a CALL, we cannot let postpone use SHORT_CALL (via compile,)
  OPCODE_DOLIT c, here 10 + ,
  OPCODE_CALL c, ['] (does>) , 	\ *was* postpone (does>), see above
  OPCODE_RET c,
; immediate

: constant create , does> @ ;													\ \ CORE
: variable create 0 , does> ;													\ \ CORE
: buffer: create allot ;														\ \ CORE-EXT
: value create , does> @ ;														\ \ CORE-EXT

internals set-current
: >= < not ;																	\ \ INTERNAL
: <= > not ;																	\ \ INTERNAL
forth-wordlist set-current

256 buffer: pad																	\ \ CORE-EXT

\ a bit of a lie atm since we're technically including from a file
\ but for bootstrap purposes we pretend we're not
0 value source-id																\ \ CORE-EXT

: to																			\ \ CORE-EXT
	bl word 

	dup count locals-wordlist search-wordlist if
		nip
		1+ @		\ get the literal from the first instruction in the word
		OPCODE_DOLIT c,
		,
		OPCODE_LSTORE c,
		exit
	then

	find 0= abort" word not found (to)"
	state @ if
		[literal]
		postpone >body
		postpone !
	else	
		>body !
	then
; immediate

: defer create ['] abort , does> @ execute ;									\ \ CORE-EXT
: defer! >body ! ;																\ \ CORE-EXT
: defer@ >body @ ;																\ \ CORE-EXT

: is																			\ \ CORE-EXT
  state @ 
  if
 	postpone ['] postpone defer!
  else
    ' defer!
  then
; immediate

: action-of																		\ \ CORE-EXT
  state @
  if
    postpone ['] postpone defer@
  else
    ' defer@
  then
;

: ( 																			\ \ CORE FILE
  source-id 0> abort" i haven't implemented the file semantics of ("
  [char] ) word drop 
; immediate	

: align	;	( I dont currently have any alignment requirements )				\ \ CORE
: aligned ;	( I dont currently have any alignment requirements )				\ \ CORE

: save-input																	\ \ CORE-EXT
  tib @
  #tib @
  >in @
  source-id
;

: restore-input																	\ \ CORE-EXT
  to source-id
  >in !
  #tib !
  tib !
;

: words																			\ \ SEARCH-ORDER
  cr
  get-current @		
  ?dup 0= if exit then
  begin
    dup head>name count type bl emit	
    @
    dup 0 =
  until
  drop
  cr
;

: dump		\ a-addr len --														\ \ PROGRAMMING-TOOLS
  base @ >r hex
  over +	

  begin			\ ptr end --
    cr
    over 0 <# # # # # # # # # #> type s" : " type

	16 0 do
		over i + over <= if over i + c@ 0 <# # # #> type bl emit else 3 spaces then
		i 7 = if bl emit then
	loop

	[char] | emit bl emit

	16 0 do
	    over i + over <= if over i + c@ dup 31 < over 127 > or if drop [char] . then emit then
	loop

    swap 16 + swap 
    2dup >=
  until
  2drop
  cr
  r> base !
;

internals set-current

: opcodename 		\ value -- caddr u | -- 0
  drop 0
;

: dis		\ a-addr len --														\ \ INTERNAL
  base @ >r hex
  over + swap		\ end p --
  begin
    cr dup 0 <# # # # # # # # # #> type s" : " type

  	dup c@ OPCODE_SHORT_CALL = if
		dup 1+ w@ >name count type
		3 +	
	else
		dup c@ OPCODE_CALL = if
			dup 1+ @ >name count type 
			5 +
	    else
			dup c@ OPCODE_DOLIT = if
			  dup 1+ @ 0 <# #s #> type
	      	  5 +
			else
				dup c@ OPCODE_RET = if
					s" Ret" type
					drop dup	\ force end
				else
					dup c@ OPCODE_JUMP = if
						s" Jump" type dup 1+ @ [char] [ emit 0 <# # # # # # # # # #> type [char] ] emit
						5 +
					else
						dup c@ OPCODE_JUMPD = if
							s" JumpD" type
							1 +
						else
	  						dup c@ OPCODE_JUMP_EQ_ZERO = if
								s" jeq0 " type dup 1+ @ [char] [ emit 0 <# # # # # # # # # #> type [char] ] emit
								5 +
							else
								dup c@ opcodename ?dup if
									type
									1+
								else
									dup s" code " type c@ 0 <# #s #> type
								    1+
								then
							then
						then
					then
				then
			then
		then
	then
    2dup <=
  until
  2drop
  r> base !
;
forth-wordlist set-current

: see bl word find if 20000 dis then ;											\ \ PROGRAMMING-TOOLS

: .r																			\ \ CORE-EXT
  swap dup >r abs 0 <# #s r> sign #> 
  \ width c-addr u --
  rot over - 
  spaces type
;

: u.r																			\ \ CORE-EXT
  swap 0 <# #s #> 
  \ width c-addr u --
  rot over - 
  spaces type
;

: .s 																			\ \ PROGRAMMING-TOOLS
  depth
  ?dup 0= if cr 10 spaces s" (empty)" type exit then

  cr 13 spaces ." top"
  0 begin
    2dup <>
  while
    dup 2 + pick cr 16 .r
	1+
  repeat
  2drop
;

: >number		\ ud c-addr u -- ud c-addr u									\ \ CORE
	begin
		dup 0= if exit then
		over c@ 		

		\ ud c-addr u char --
		dup [char] a >=		
		over [char] z <=		
		and if 32 - then
		\ ud c-addr u charlc --
		dup [char] 0 < if drop exit then
		dup [char] Z > if drop exit then
		dup [char] 9 > over [char] A < and if drop exit then
		[char] 0 -
		dup 9 > if 7 - then

		\ ud c-addr u digit --
		dup base @ >= if drop exit then
		rot rot
		\ ud digit c-addr u --
		1- >r
		1+ >r
		>r
		base @ [ OPCODE_UMULT c, ]
		r> 0 [ OPCODE_ADD2 c, ]
		r> 
		r> 
	0 until
;

\ some folks call this 'interpret' :-)
internals set-current
: (evaluate)																	\ \ INTERNAL
  begin
    bl word 

	dup c@ 0= if drop exit then

	find ?dup 0= if	
		count
	
		over c@ [char] - = 
		if 
			1- swap 1+ swap 
			-1 >r 
		else
			1 >r
			over c@ [char] + = 
			if 
				1- swap 1+ swap
			then
		then

		0 0 2swap >number
		\ ud c-addr u -- : R: multiplier --
		?dup 0= if	
			drop 
			abort"	>number gave the interpreter a number too big for 1 cell and I don't handle that yet"
			r> *
			state @ if
				 [literal]
			then
		else
			r> drop
			cr type ."  not found (interpreter)"
			2drop
			abort
		then
	else
		1 = if
			execute
		else
			state @ if
				compile,
			else
				execute
			then
		then
	then
  0 until
;
forth-wordlist set-current

: evaluate																		\ \ CORE
  >r >r
  save-input
  r> tib !
  r> #tib !
  0 >in !
  -1 to source-id
  (evaluate)
  restore-input
;

: source																		\ \ CORE
  tib @ #tib @
;

: accept		\ addr max -- count												\ \ CORE
  swap 0		\ max addr count --
  begin
    key
	case			\ max addr count key --
       8 of dup emit rot 1- rot 1- rot endof
	  13 of endof
	  10 of drop nip nip exit endof
	  dup 3 pick c!
	  rot 1+ rot 1+ rot
	endcase
    2 pick over =
  until
  nip nip	
;

: unused																		\ \ CORE-EXT
	SIZE_FORTH here -
;

internals set-current
: eof?		\ id -- flag														\ \ INTERNAL
  dup >r
  file-size if 2drop r> drop true then
  r> file-position if 2drop 2drop true then
  rot = rot rot = and
;
forth-wordlist set-current
  
: read-line																		\ \ FILE
  dup eof? if 2drop drop 0 false 0 exit then

  >r 0
  \ c-addr max count -- : R: fileid --
  begin
	2dup <>
	r@ eof? 
	not and
  while					\ c-addr max count -- : R: fileid --
	2 pick 1 r@ read-file ?dup if
		r> drop
		rot drop
		rot drop
		\ count ior --
		false swap exit
    then
	drop	
	\ c-addr max count --
	2 pick c@ 13 <> if
		2 pick c@ 10 = if
			nip nip true 0
			r> drop
			exit
		then
		rot 1+ rot rot 1+
	then
  repeat
  r> drop nip nip true 0
;

: refill																		\ \ CORE-EXT FILE
  source-id
  case
  -1 of false swap endof
  0 of tib @ SIZE_INPUT_BUFFER accept #tib ! 0 >in ! true swap endof

  drop 

  tib @ SIZE_INPUT_BUFFER 2 - source-id read-line if 
	2drop false 
	exit
  then

  false = if
	drop false
    exit
  then

  #tib !
  0 >in !
  true
  0 endcase
;

: marker																		\ \ CORE-EXT
  here
  create
	,
    here SIZE_ORDER cells allot
	A_ORDER swap SIZE_ORDER cells move
	get-current ,
  does>
    SIZE_ORDER 2 cells + dump
	1 abort" FIX THE DICTIONARY DUDE!"
;

: fill																			\ \ CORE
  begin
    over 0>
  while
    \ c-addr u fil
	rot 	\ u fil addr
	2dup c!
	1+
	rot 1-
	rot
  repeat
  2drop drop
;

: erase	0 fill ;																\ \ CORE-EXT

: s\" 																			\ \ CORE-EXT FILE
  1 abort" s-slash-quote not implemented."
; immediate

\ ---------------------------------------------------------------------------------------------
\ 
\ ---------------------------------------------------------------------------------------------

: */ 1 abort" */ not implemented"; immediate									\ \ CORE
: */MOD 1 abort" */MOD not implemented"; immediate								\ \ CORE
: / 1 abort" / not implemented"; immediate										\ \ CORE
: /MOD 1 abort" /MOD not implemented"; immediate								\ \ CORE
: 2* 1 abort" 2* not implemented"; immediate									\ \ CORE
: 2/ 1 abort" 2/ not implemented"; immediate									\ \ CORE
: 2! 1 abort" 2! not implemented"; immediate									\ \ CORE
: FM/MOD  1 abort" FM/MOD  not implemented"; immediate							\ \ CORE
: M* 1 abort" M* not implemented"; immediate									\ \ CORE
: MOD 1 abort" MOD not implemented"; immediate									\ \ CORE
: S>D 1 abort" S>D not implemented"; immediate									\ \ CORE
: SM/REM 1 abort" SM/REM not implemented"; immediate							\ \ CORE
: UM* 1 abort" UM* not implemented"; immediate									\ \ CORE

: 2@ 1 abort" 2@ not implemented"; immediate									\ \ CORE

: INVERT 1 abort" INVERT not implemented"; immediate							\ \ CORE
: LSHIFT 1 abort" LSHIFT not implemented"; immediate							\ \ CORE
: MAX 1 abort" MAX not implemented"; immediate									\ \ CORE
: MIN 1 abort" MIN not implemented"; immediate									\ \ CORE
: RSHIFT 1 abort" RSHIFT not implemented"; immediate							\ \ CORE
: XOR 1 abort" XOR not implemented"; immediate									\ \ CORE

: RECURSE 1 abort" RECURSE not implemented"; immediate							\ \ CORE

\ ---------------------------------------------------------------------------------------------
\ environment support
\ ---------------------------------------------------------------------------------------------

internals set-current
wordlist constant ENVIRONMENT-wid
get-order ENVIRONMENT-wid swap 1+ set-order definitions

: /COUNTED_STRING		255 ;
: /HOLD					SIZE_PICTURED_NUMERIC ;
: /PAD					255 ;
: ADDRESS-UNIT-BITS		32 ;
: FLOORED				1 ;
: MAX-CHAR				255 ;
: MAX-D					1 abort" max-d environment not done" ;
: MAX-N					1 abort" max-n environment not done" ;
: MAX-U					1 abort" max-u environment not done" ;
: MAX-UD				1 abort" max-ud environment not done" ;
: RETURN-STACK-CELLS	SIZE_RETURN_STACK ;
: STACK-CELLS			SIZE_DATA_STACK ;

internals forth-wordlist 2 set-order forth definitions

: environment?																	\ \ CORE
	ENVIRONMENT-wid search-wordlist if
	  execute true
    else
	  false
    then
;

get-order internals swap 1+ set-order

\ ---------------------------------------------------------------------------------------------
\ ---------------------------------------------------------------------------------------------

: compare																		\ \ STRING
  rot			\ c-addr1 c-addr2 u2 u1
  over -		\ c-addr1 c-addr2 u2 diff --
  ?dup if
    nip nip nip
  else
    [ get-order internals swap 1+ set-order OPCODE_COMPARE get-order nip 1- set-order c, ]
  then
;

\ ---------------------------------------------------------------------------------------------
\ ---------------------------------------------------------------------------------------------

get-order ENVIRONMENT-wid swap 1+ set-order definitions
16 constant #LOCALS

internals forth-wordlist 2 set-order definitions
: (local)
  2dup or 0= if
	2drop
	0 locals-here !

	locals-count @ if
		['] rsp@ compile,
		OPCODE_LPFETCH c, 
		['] >r compile,
		OPCODE_LPSTORE c, 
	then
	locals-count @ 0 ?do ['] >r compile, loop
  else
	locals-here @ 0= if
		0 locals-count !
		here unused + 1024 - locals-here !			\ HACK, a fairly arbitary number of bytes for dictionary
													\ all hell breaks loose if we get within 1k of the end normally
													\ or our locals exceed it.
													\ TODO abort" if dictionary already full or we would go over buffer
	then

	locals-here @				\ c-addr u lh --

	locals-wordlist @ over ! 
    dup locals-wordlist !
	1 cells +

	OPCODE_IMMEDIATE over c!  1 +
	
	over over c!  1 +

	2dup 2>r
	swap move
	2r>							\ u lh --	
	+							\ locals here

	OPCODE_DOLIT over c! 1+
	locals-count @ 1+ over ! 1 cells +		
	OPCODE_CALL over c! 1+
	['] compile-l@ over ! 1 cells +

	OPCODE_RET over c!  1+

	locals-here !

	1 locals-count +!
  then
; 

: locals|
  begin
  	bl word count
	?dup 0= if
		1 abort" failed local parsing"
	then
    2dup s" |" compare 0= if
		2drop
		0 0 (local) 
		exit 
	then
	(local)
  again
; immediate

only definitions

\ ---------------------------------------------------------------------------------------------
\ Files
\ ---------------------------------------------------------------------------------------------

only definitions
get-order internals swap 1+ set-order

: bin ;																			\ \ FILE

: required																		\ \ FILE
  \ the wat to implement this is to put all filenames that i've required so far
  \ into a word list for comparison against to guard against re-including. Then
  \ when marker is used it'll remove anything from this wid too and allow require
  \ to operate again! easy. don't really need it tho.
  1 abort" required not implemented."
;

: require																		\ \ FILE
  parse-name required
;

get-order internals swap 1+ set-order internals set-current
variable line-end
10 line-end c!
forth-wordlist set-current

: write-line																	\ \ FILE
  \ c-addr u fileid -- 
  rot rot 2 pick write-file				\ fileid ior --
  swap line-end 1 rot write-file		\ ior1 ior2 --
  or
;

internals set-current
variable save-tmp

: save
  bl word count 
  cr ." Saving to " 2dup type
  0 create-file if
	drop cr ." failed to create file"
  else
	\ fd --
	287454020 save-tmp !
	dup save-tmp 1 cells rot write-file drop
	cr ." Header " save-tmp @ hex . decimal

	here unused + save-tmp ! 
	cr ." Total Dictionary size " save-tmp @ dup . space hex . decimal
	dup save-tmp 1 cells rot write-file drop

	S" STACK-CELLS" environment? drop save-tmp !
	cr ." Data stack size (cells) " save-tmp @ .
	dup save-tmp 1 cells rot write-file drop

	S" RETURN-STACK-CELLS" environment? drop save-tmp !
	cr ." Return stack size (cells) " save-tmp @ .
	dup save-tmp 1 cells rot write-file drop

	cr ." Entrypoint " hex A_QUIT @ . decimal
	dup A_QUIT 1 cells rot write-file drop

	dup 0 here rot write-file if
		cr ." failed write"
	then
	close-file if
		cr ." failed to close file"
	then
  then
; immediate
forth-wordlist set-current

: include-file																	\ \ FILE
  >r save-input r> to source-id
  begin
    refill
  while
	['] (evaluate) catch
	case 
	0 of endof
	-1 of endof
	-2 of cr here count type cr endof
	dup cr ." Exception #" . cr
	endcase
  repeat 
  restore-input
;

: included																		\ \ FILE
  r/o open-file if drop cr ." failed" else include-file then
;

: include																		\ \ FILE
  parse-name included
;

\ ---------------------------------------------------------------------------------------------
\
\ Now we'll build a proper Forth interpreter and patch it in as entry point. 
\
\ ---------------------------------------------------------------------------------------------

internals set-current
: prompt?
  state @ 0= if
	cr [char] [ emit depth . ." ] Ok. " cr
  then
;
forth-wordlist set-current

: quit																			\ \ CORE
  0 rsp!
  0 to source-id

  postpone [
  begin
    refill
  while
	['] (evaluate) catch
	case 
	0 of drop prompt? 0 endof
    postpone [
	-1 of endof
	-2 of cr here count type cr endof
	dup cr ." Exception #" . cr
	endcase
  repeat
  bye	
; 

get-order internals swap 1+ set-order
' quit A_QUIT !	
only definitions

