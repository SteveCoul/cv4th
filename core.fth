
\ ---------------------------------------------------------------------------------------------

\ These words are defined in the native wrapper 

\ here																			\ \ CORE
\ state																			\ \ CORE
\ >in																			\ \ CORE
\ base																			\ \ CORE
\ u<																			\ \ CORE
\ rot																			\ \ CORE
\ 2dup																			\ \ CORE
\ 2drop																			\ \ CORE
\ 2swap																			\ \ CORE
\ move																			\ \ CORE
\ depth																			\ \ CORE
\ over																			\ \ CORE
\ dup																			\ \ CORE
\ @																				\ \ CORE
\ =																				\ \ CORE
\ !																				\ \ CORE
\ <																				\ \ CORE
\ +																				\ \ CORE
\ +!																			\ \ CORE
\ swap																			\ \ CORE
\ um/mod																		\ \ CORE
\ sm/rem																		\ \ CORE
\ execute																		\ \ CORE
\ 0= 																			\ \ CORE
\ or																			\ \ CORE
\ and																			\ \ CORE
\ c!																			\ \ CORE
\ c@																			\ \ CORE
\ drop																			\ \ CORE
\ emit																			\ \ CORE
\ *																				\ \ CORE
\ m*																			\ \ CORE
\ um*																			\ \ CORE
\ -																				\ \ CORE
\ >																				\ \ CORE
\ tuck																			\ \ CORE-EXT
\ u>																			\ \ CORE-EXT
\ nip																			\ \ CORE-EXT
\ roll																			\ \ CORE-EXT
\ pick																			\ \ CORE-EXT
\ r/o																			\ \ FILE
\ w/o																			\ \ FILE
\ r/w																			\ \ FILE
\ open-file																		\ \ FILE
\ close-file																	\ \ FILE
\ create-file																	\ \ FILE
\ read-file																		\ \ FILE
\ write-file																	\ \ FILE
\ delete-file																	\ \ FILE
\ file-position																	\ \ FILE
\ file-size																		\ \ FILE
\ file-status																	\ \ FILE
\ flush-file																	\ \ FILE
\ resize-file																	\ \ FILE
\ rename-file																	\ \ FILE
\ reposition-file																\ \ FILE
\ INTERNALS																		\ \ INTERNAL
\ A_LIST_OF_WORDLISTS															\ \ INTERNAL
\ locals-wordlist																\ \ INTERNAL
\ SIZE_DATA_STACK																\ \ INTERNAL
\ SIZE_RETURN_STACK																\ \ INTERNAL
\ SIZE_FORTH																	\ \ INTERNAL
\ SIZE_INPUT_BUFFER																\ \ INTERNAL
\ SIZE_PICTURED_NUMERIC															\ \ INTERNAL
\ SIZE_ORDER																	\ \ INTERNAL
\ A_HERE																		\ \ INTERNAL
\ A_QUIT																		\ \ INTERNAL
\ A_CURRENT																		\ \ INTERNAL
\ A_ORDER																		\ \ INTERNAL
\ A_PICTURED_NUMERIC															\ \ INTERNAL
\ A_INPUT_BUFFER																\ \ INTERNAL
\ rsp@																			\ \ INTERNAL
\ rsp!																			\ \ INTERNAL 
\ sp@																			\ \ INTERNAL
\ sp!																			\ \ INTERNAL
\ w@																			\ \ INTERNAL
\ w!																			\ \ INTERNAL
\ bye																			\ \ INTERNAL
\ forth-wordlist																\ \ SEARCH-ORDER
\ tib																			\ \ 
\ #tib																			\ \ 

\ and in the INTERNALS various VM opcodes op?????? words, by default only the ones actually
\ used in this file are exported.

\ The bootstrap interpreter also has invisible implementations of the following words
\ which it will stop using as soon as it sees a good FORTH implementation below

\ \																				\ \ CORE
\ :																				\ \ CORE
\ ;																				\ \ CORE

\ ---------------------------------------------------------------------------------------------

: get-current																	\ \ SEARCH-ORDER
  A_CURRENT @ 
;

: set-current																	\ \ SEARCH-ORDER
  A_CURRENT !
;

internals set-current
: >flag				4 + ;														
forth-wordlist set-current

: immediate																		\ \ CORE
  opIMMEDIATE
  get-current @ >flag
  c!
;

\ Don't put this comment on line below yet. bootstrap interpreter makes word
\ visible on colon rather than on semicolon. I'll fix it.						\ \ CORE
: \																				
  #tib @ >in !
; immediate
 
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
internals set-current
: w,																			
  here 2 allot w!
;
forth-wordlist set-current
: , here 1 cells allot !  ;														\ \ CORE

: r>																			\ \ CORE
  [ opRFROM c, 
    opRFROM c, 
    opSWAP c, 
	opTOR c, ]
; opRFROM get-current @ >flag c!			\ set compile time behavior to lay opcode

: 2r>																			\ \ CORE EXT
  [ opRFROM c, 
    opRFROM c, 
	opRFROM c,	
    opSWAP c, 
	opROT c,
	opTOR c, ]
; 

: r@																			\ \ CORE
  [
	opRFROM c,
	opRFROM c,
    opDUP c,
    opSWAP c,
	opTOR c,
    opSWAP c,
	opTOR c,
  ]
; opRFETCH get-current @ >flag c!

: >r																			\ \ CORE
  [
	opRFROM c,
	opSWAP c,
	opTOR c,	
	opTOR c,	
  ]
; opTOR get-current @ >flag c!

: 2>r
  [	
	opRFROM c,	
	opROT c,
	opTOR c,
	opSWAP c,
	opTOR c,
	opTOR c,
  ]
;

: 2r@ 																			\ \ CORE-EXT
  [ 
	opRFROM c,
	opRFROM c,
	opRFROM c,		\ ret a b --
	opROT c,
	opTOR c,
	opSWAP c,
  ]
;

: negate 0 swap - ;																\ \ CORE

: true 1 ;																		\ \ CORE-EXT
: false 0 ;																		\ \ CORE-EXT

: bl 32 ;																		\ \ CORE
: cr 10 emit ;																	\ \ CORE

: 0< 0 < ;																		\ \ CORE

: 0<> 0= 0= ;																	\ \ CORE-EXT
: 0> 0 > ;																		\ \ CORE-EXT
: <> = 0= ;																		\ \ CORE-EXT

: within over - >r - r> u< ;													\ \ CORE-EXT

internals set-current
: resolv!		\ a-addr --
  here over - 2 - swap w!
;
: resolv,
  here - 2 - w,
;
forth-wordlist set-current

: ahead																			\ \ PROGRAMMING-TOOLS
  opBRANCH c, here 0 w,
; immediate

: if																			\ \ CORE
  opQBRANCH c,
  here 
  0 w,
; immediate

: else																			\ \ CORE
  opBRANCH c,
  here
  0 w,
  swap resolv!
; immediate

: then																			\ \ CORE
  resolv!
; immediate

: begin																			\ \ CORE
  here
; immediate

: until																			\ \ CORE
  opQBRANCH c,
  resolv,
; immediate

: while																			\ \ CORE
  opQBRANCH c,
  here swap
  0 w,
; immediate

: repeat																		\ \ CORE
  opBRANCH c,
  resolv,
  resolv!
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

get-order internals swap 1+ set-order

internals set-current

: [fake-variable]
  opCALL c, here 8 + , 0 , opRFROM c,
; immediate

: locals-count [fake-variable] ;
: locals-here  [fake-variable] ;

forth-wordlist set-current

internals set-current
: end-locals
  locals-count @ if
	opLPFETCH c,
	opDOLIT c, 0 ,
	opLFETCH c,
	opLPSTORE c,
	opRSPSTORE c,
    0 locals-count !
  then
;

: compile-l@
  opDOLIT c, ,	
  opLFETCH c,
;
forth-wordlist set-current

: exit end-locals opRET c, ; immediate											\ \ CORE

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
  A_LIST_OF_WORDLISTS @ ,
  here A_LIST_OF_WORDLISTS !
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

: count dup 1 + swap c@ ;														\ \ CORE

internals set-current
: ctype count type ;		
forth-wordlist set-current

internals set-current
: [literal]																		
  dup -1 = if	opLITM1 c, drop else
  dup 0=  if	opLIT0 c, drop else
  dup 1 = if	opLIT1 c, drop else
  dup 2 = if	opLIT2 c, drop else
  dup 3 = if	opLIT3 c, drop else
  dup 4 = if	opLIT4 c, drop else
  dup 5 = if	opLIT5 c, drop else
  dup 6 = if	opLIT6 c, drop else
  dup 7 = if	opLIT7 c, drop else
  dup 8 = if	opLIT8 c, drop else
  dup 0 256 within if
    opDOLIT_U8 c, c,
  else
    opDOLIT c, ,
  then
  then then then then then then then then then then 
;
forth-wordlist set-current
 
: literal [literal] ; immediate													\ \ CORE

: abs dup 0< if negate then ;													\ \ CORE

internals set-current
: should-skip	\ ( char delim -- flag )										
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
: (parse) \ delimiter skip-char -- c-addr u										
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
  >in @ #tib @ = 0= if 1 >in +! then	\ and the delimiter we hit goes too
;
forth-wordlist set-current

: parse 0 (parse) ;																\ \ CORE-EXT

: parse-name																	\ \ CORE-EXT
  bl bl (parse)
;

internals set-current
: ^word-buffer [fake-variable] ;
here SIZE_INPUT_BUFFER allot ^word-buffer !
forth-wordlist set-current

: word																			\ \ CORE
  ^word-buffer @ >r
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
  [char] ) word ctype
; immediate

internals set-current
: head>name			>flag 1 + ;													
forth-wordlist set-current

: search-wordlist	\ c-addr u wid -- 0 | xt 1 | xt -1 							\ \ SEARCH-ORDER
	@	
	?dup 0= if 2drop 0 exit then

	begin					
		over over head>name c@ =				
		if
			2 pick 2 pick						
			2 pick head>name 1 + swap				
			[ opCOMPARE c, ]
			0= if 
														\ c-addr u link --
				nip nip
				dup 
				head>name count + 						
				swap >flag c@ opIMMEDIATE = if
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

: forget-locals	0 locals-wordlist !	;											

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
: >name																			
  dup >r	\ p -- R: xt --
  begin
    1-
    dup count + r@ =
  until
  r> drop 
;

: >head																			
  >name
  1-
  1 cells -
;
forth-wordlist set-current

: compile,																		\ \ CORE-EXT
  dup >head >flag c@ dup opIMMEDIATE = swap opNONE = or if
	dup 65536 < if
		opSHORT_CALL c, w,
	else
	  	opCALL c, ,
	then
  else
    >head >flag c@ c,
  then
;

internals set-current
: (abort)																		
	0 sp!
   	0 rsp!
	0 state !
	forget-locals
    A_QUIT @	
	?dup if
		>r 			\ sneaky!!
	then
;
forth-wordlist set-current

internals set-current
: exception-handler	[fake-variable] ;
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
			cr here ctype 
			(abort)
		then
		cr [char] # emit . 
		(abort)
	then

    exception-handler @ rsp!
    r> exception-handler !
	r> swap >r
	sp! drop r>
  then
;

: [']																			\ \ CORE
	bl word find 0= if -13 throw then [literal]	
; immediate

: abort																			\ \ CORE EXCEPTION
  -1 throw
; 

: '																				\ \ CORE
	bl word 
	find
	0= if
		-13 throw
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

\ Obsolete and I don't need it either so not doing it
\ [compile]																		\ \ CORE-EXT

: postpone																		\ \ CORE
	bl word find ?dup 0= if		
		-13 throw
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

: c" 																			\ \ CORE
	postpone AHEAD
	[char] " parse
	here >r
	dup 1+ allot
	dup r@ c!
    r@ 1+ swap move
	postpone then
	r> [literal]
; immediate

internals set-current
: ^s"-buffer [fake-variable] ;
here SIZE_INPUT_BUFFER allot ^s"-buffer !
forth-wordlist set-current

: s"																			\ \ CORE / FILE-ACCESS
  state @ if
	postpone c"
	postpone count
  else
	  ^s"-buffer @
      [char] " word count			\ tmp c-addr u --
      swap 2 pick 2 pick			\ tmp u c-addr tmp u --
	  move
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
	opDOLIT c,
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
	postpone if
	
	opDOLIT c,					\ get the resolv address at runtime N bytes on from here
	here 14 + ,				\ depends on instruction count below!
	opFETCH c,
							\ limit idx jump-target --
	opDUP c, opTOR c,		\ push 3 numbers to return stack for unloop
	opSWAP c, opTOR c,
	opSWAP c, opTOR c,	
    opTOR c, opRET c,		\ >r-ret == jump direct
	
	postpone then
    postpone do
; immediate

: unloop																		\ \ CORE
  r>
  r> drop
  r> drop
  r> drop
  >r
;

internals set-current
: (+loop)		\ N -- | R: exit-addr idx limit return --
  r> swap			\ return N -- | exit-addr idx limit --
  r> r>				\ return N limit idx -- | exit-addr --
  rot +				\ return limit idx+N | exit-addr --
  2dup > 0=			\ return limit idx+N flag | exit-addr --
  swap >r			\ return limit flag | exit-addr idxN --
  swap >r			\ return flag | exit-addr idxN limit --
  swap >r			\ flag | exit-addr idxN limit flag --
; 
forth-wordlist set-current

: +loop
	postpone (+loop)
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
	opTOR c, opRET c,	\ IE jump
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
: >name 	 \ xt -- c-addr														
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
    [ opIN c, ]
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
  opNONE c,
  bl word 
  count dup c,			\ colon-sys c-addr u --
  here over allot		\ colon-sys c-addr u here --
  swap move
  1 state !
;

: ; 																			\ \ CORE
  end-locals
  opRET c,
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
  opNONE c,
  bl word count dup c,
  here over allot
  swap move

  opDOLIT c,			\ not sure I really need this lit, I can just fix >body
  here 0 ,

  opDOLIT c,
  here cell+ 1+ ,
  opTOR c,				\ lit>r otherwise known as branch :-)
  opRET c,

  here swap !
;

: >body 1+ @ ; 																	\ \ CORE

internals set-current
: (does>)																		
  get-current @ cell+ 1+ count + 1+ cell+ 1+ !	
;
forth-wordlist set-current

: does>																			\ \ CORE
  end-locals
  \ the '10' is the DOLIT and a CALL, we cannot let postpone use SHORT_CALL (via compile,)
  opDOLIT c, here 10 + ,
  opCALL c, ['] (does>) , 	\ *was* postpone (does>), see above
  opRET c,
; immediate

: constant create , does> @ ;													\ \ CORE
: variable create 0 , does> ;													\ \ CORE
: buffer: create allot ;														\ \ CORE-EXT
: value create , does> @ ;														\ \ CORE-EXT

256 buffer: pad																	\ \ CORE-EXT

\ a bit of a lie atm since we're technically including from a file
\ but for bootstrap purposes we pretend we're not
0 value source-id																\ \ CORE-EXT

: to																			\ \ CORE-EXT
	bl word 

	dup count locals-wordlist search-wordlist if
		nip
		1+ @		\ get the literal from the first instruction in the word
		opDOLIT c,
		,
		opLSTORE c,
		exit
	then

	find 0= if -13 throw then
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
  ?dup if
    begin
      dup head>name ctype bl emit	
      @
      dup 0 =
    until
    drop
    cr
  then
;

internals set-current

: aschar 
  dup bl < if drop [char] . else
  dup [char] z > if drop [char] . else
  then then
;

: .hex32	\ v --
  base @ >r hex 0 <# # # # # # # # # #> type r> base !
;

: .hex16	\ v --
  base @ >r hex 0 <# # # # # #> type r> base !
;

: .hex8		\ v --
  base @ >r hex 0 <# # # #> type r> base !
;
	
: .hex		\ v --
  base @ >r hex 0 <# #s #> type r> base !
;

forth-wordlist set-current

: dump		\ a-addr len --														\ \ PROGRAMMING-TOOLS
  over +	

  begin			\ ptr end --
	2dup <
  while
    cr
    over .hex32 ." : "

	16 0 do	
		over i + over < if over i + c@ .hex8 bl emit else 3 spaces then
		i 7 = if space then
	loop

	[char] | emit space

	16 0 do
	    over i + over < if over i + c@ aschar emit then
	loop

    swap 16 + swap 
  repeat
  2drop
  cr
;

internals set-current

: isconstantdef		\ head -- flag
  4 + 1 + count +	\ ptr
  dup c@ opDOLIT = if
	5 +
	c@ opRET = 
  else
    dup c@ opDOLIT_U8 = if 
	  2 +
	  c@ opRET = 
    else
      drop false 
    then
  then
;

: opcodename 		\ value -- caddr u | -- 0
  internals
  begin
    @ ?dup
  while
    dup 4 + 1 +			\ value head name --
    dup c@ 2 > if
		dup 1+ c@ [char] o = if	
			dup 2 + c@ [char] p = if	
				over isconstantdef if  	\ value head name --
					dup count + execute	\ value head name constant-value --
					3 pick = if
						nip nip count exit
					then
				then
			then
		then
    then
    drop
  repeat
  drop 0
;

: (disprefix) 5 spaces ." | " ;

: dis		\ a-addr len --														
  over + swap		\ end p --
  begin
    2dup >
  while
    cr dup .hex32 ." : " 
	\ I ned to process anything here that has inline data, anything else can be in opcodename
  	dup c@ opSHORT_CALL =   if (disprefix) dup 1+ w@ >name ctype 3 +	else
	dup c@ opCALL = 	    if (disprefix) dup 1+ @ >name ctype 5 + else
	dup c@ opDOLIT = 	    if (disprefix) dup 1+ @ .hex 5 + else
	dup c@ opDOLIT_U8 =     if (disprefix) dup 1+ c@ .hex8 2 + else
	dup c@ opRET = 		    if (disprefix) ." Ret" drop dup	else
	dup c@ opBRANCH =		if (disprefix) ."  branch" dup 1+ w@ [char] [ emit over + 3 + .hex16 [char] ] emit 3 + else
	dup c@ opQBRANCH =		if (disprefix) ." ?branch" dup 1+ w@ [char] [ emit over + 3 + .hex16 [char] ] emit 3 + else

	dup c@ .hex8 space dup c@ aschar emit space ." | " 

	dup c@ opcodename ?dup if type 1+ else
	dup c@ ." code " .hex 1+ 
    then then then then then then then then
  repeat
  2drop
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
  ?dup 0= if 
	cr 10 spaces ." (empty)" 
  else
    cr 13 spaces ." top"
    0 begin
      2dup <>
    while
      dup 2 + pick cr 16 .r
  	1+
    repeat
    2drop
  then
;

internals set-current
: islower [char] a [char] z 1+ within ;
: toupper dup islower if 32 - then ;
forth-wordlist set-current

: >number		\ ud c-addr u -- ud c-addr u									\ \ CORE
	begin
		dup 0= if exit then
		over c@ toupper

		\ ud c-addr u char --

		dup [char] 0 [char] Z 1+ within 0= if drop exit then
		dup [char] 9 1+ [char] A within if drop exit then
		[char] 0 - dup 9 > if 7 - then

		\ ud c-addr u digit --
        dup base @ < 0= if drop exit then
		rot rot
		\ ud digit c-addr u --
		1- >r
		1+ >r
		>r
		base @ [ opUMULT c, ]
		r> 0 [ opADD2 c, ]
		r> 
		r> 
	0 until
;

\ some folks call this 'interpret' :-)
internals set-current
: (evaluate)																	
  begin
    bl word 
    dup c@
  while
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
			if \	>number gave the interpreter a number too big for 1 cell and I don't handle that yet"
				-24 throw
			then
			r> *
			state @ if
				[literal] 
			then
		else
			r> drop
			2drop
			-13 throw
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
  repeat
  drop
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
: eof?		\ id -- flag														
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
	0= and
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

: s>d dup [ hex ] 80000000 [ decimal ] and if -1 else 0 then ;					\ \ CORE
: / swap s>d rot sm/rem nip ;													\ \ CORE
: mod swap s>d rot sm/rem drop ;												\ \ CORE
: /mod swap s>d rot sm/rem ;													\ \ CORE
: 2* 2 * ;																		\ \ CORE
: 2/ 2 / ;																		\ \ CORE

: max 2dup > if drop else nip then ;											\ \ CORE
: min 2dup > if nip else drop then ;											\ \ CORE

: 2@ dup cell+ @ swap @ ;														\ \ CORE
: 2! swap over ! cell+ ! ;														\ \ CORE

: */ 1 abort" */ not implemented"; immediate									\ \ CORE
: */MOD 1 abort" */MOD not implemented"; immediate								\ \ CORE
: FM/MOD  1 abort" FM/MOD  not implemented"; immediate							\ \ CORE

: INVERT 1 abort" INVERT not implemented"; immediate							\ \ CORE
: LSHIFT 1 abort" LSHIFT not implemented"; immediate							\ \ CORE
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
: FLOORED				0 ;
: MAX-CHAR				255 ;
: MAX-D					1 abort" max-d environment not done" ;
: MAX-N					1 abort" max-n environment not done" ;
: MAX-U					1 abort" max-u environment not done" ;
: MAX-UD				1 abort" max-ud environment not done" ;
: RETURN-STACK-CELLS	SIZE_RETURN_STACK ;
: STACK-CELLS			SIZE_DATA_STACK ;

internals forth-wordlist 2 set-order definitions

: environment?																	\ \ CORE
	ENVIRONMENT-wid search-wordlist if
	  execute true
    else
	  false
    then
;

\ ---------------------------------------------------------------------------------------------
\ ---------------------------------------------------------------------------------------------

: compare																		\ \ STRING
  rot			\ c-addr1 c-addr2 u2 u1
  over -		\ c-addr1 c-addr2 u2 diff --
  ?dup if
    nip nip nip
  else
    [ get-order internals swap 1+ set-order opCOMPARE get-order nip 1- set-order c, ]
  then
;

\ ---------------------------------------------------------------------------------------------
\ ---------------------------------------------------------------------------------------------

ENVIRONMENT-wid set-current
16 constant #LOCALS
forth-wordlist set-current

: (local)
  2dup or 0= if
	2drop
	0 locals-here !

	locals-count @ if
		['] rsp@ compile,
		opLPFETCH c, 
		['] >r compile,
		opLPSTORE c, 
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

	opIMMEDIATE over c!  1 +
	
	over over c!  1 +

	2dup 2>r
	swap move
	2r>							\ u lh --	
	+							\ locals here

	opDOLIT over c! 1+
	locals-count @ 1+ over ! 1 cells +		
	opCALL over c! 1+
	['] compile-l@ over ! 1 cells +

	opRET over c!  1+

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

internals set-current

12345 constant undefined-value
: match-or-end? 2 pick 0= >r compare 0= r> or ;

: scan-args 
  begin
    2dup s" |" match-or-end? 0= while
    2dup s" --" match-or-end? 0= while
    2dup s" :}" match-or-end? 0= while
    rot 1+ parse-name
  again then then then
;

: scan-locals 
  2dup s" |" compare 0= 0= if exit then
  2drop parse-name
  begin
    2dup s" --" match-or-end? 0= while
    2dup s" :}" match-or-end? 0= while
	rot 1+ parse-name
	postpone undefined-value
  again then then
;

: scan-end
  begin
    2dup s" :}" match-or-end? 0= while
    2drop parse-name
  repeat
;

forth-wordlist set-current

: {: 
   0 parse-name scan-args scan-locals scan-end 2drop
   0 ?do (local) loop 
   0 0 (local)
; immediate

\ ---------------------------------------------------------------------------------------------
\ Files
\ ---------------------------------------------------------------------------------------------

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

internals set-current
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

: (save-cell)		( ptr fd c-addr u -- ) 
  cr type space over @ hex . decimal
  1 cells swap write-file if -75 throw then ;

: save
  parse-name
  0 create-file if 
    -63 throw
  else
	\ fd --
	287454020 save-tmp !
	save-tmp over s" HDR" (save-cell)

	here unused + save-tmp ! 
	save-tmp over s" Dict# " (save-cell)

	[ get-order environment-wid swap 1+ set-order ]
	STACK-CELLS save-tmp !
	save-tmp over s" DStack#" (save-cell)

	RETURN-STACK-CELLS save-tmp !
	save-tmp over s" RStack#" (save-cell)
	[ get-order nip 1- set-order ]

	A_QUIT over s" boot" (save-cell)

	dup 0 here rot write-file if -75 throw then
	close-file if -62 throw then
  then
; 

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
	-2 of cr here ctype cr endof
	dup cr ." Exception #" . cr
	endcase
  repeat 
  source-id close-file drop
  restore-input
;

: included																		\ \ FILE
  r/o open-file if -69 throw then
  include-file
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
	-2 of cr here ctype cr endof
	dup cr ." Exception #" . cr
	endcase
  repeat
  bye	
; 

' quit A_QUIT !	
only definitions


