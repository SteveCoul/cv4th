\ 15677
\ ---------------------------------------------------------------------------------------------

\ These words are defined in the native wrapper 

\ compare																		\ \ STRING
\ ?dup																			\ \ CORE
\ 1+																			\ \ CORE
\ 1-																			\ \ CORE
\ du<																			\ \ DOUBLE
\ d<																			\ \ DOUBLE
\ d-																			\ \ DOUBLE
\ d+																			\ \ DOUBLE
\ cells																			\ \ CORE
\ lshift																		\ \ CORE
\ rshift																		\ \ CORE
\ xor																			\ \ CORE
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
\ invert																		\ \ CORE
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
\ d8@																			\ \ INTERNAL
\ d16@																			\ \ INTERNAL
\ d32@																			\ \ INTERNAL
\ d8!																			\ \ INTERNAL
\ d16!																			\ \ INTERNAL
\ d32!																			\ \ INTERNAL
\ A_LIST_OF_WORDLISTS															\ \ INTERNAL
\ locals-wordlist																\ \ INTERNAL
\ IMAGE_HEADER_ID																\ \ INTERNAL
\ A_SIZE_DATASTACK																\ \ INTERNAL
\ A_SIZE_RETURNSTACK															\ \ INTERNAL
\ A_DICTIONARY_SIZE																\ \ INTERNAL
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
\ [																				\ \ CORE
\ ] 																			\ \ CORE

\ ---------------------------------------------------------------------------------------------

: get-current																	\ \ SEARCH-ORDER
  A_CURRENT @ 
;

: set-current																	\ \ SEARCH-ORDER
  A_CURRENT !
;

\ ---------------------------------------------------------------------------------------------

: unused																		\ \ CORE-EXT
  A_DICTIONARY_SIZE @ here -
;

\ throwing places exception information at HERE so don't get too close
\ to the edge of dictionary before doing this throw. yuk.
\ todo - also need space for locals dict (modify unused above? )
: allot																			\ \ CORE
  -8 over unused 512 - u< 0= [ opQTHROW here c! 1 A_HERE +! ]
  A_HERE +!	
;

: c, here 1 allot c!  ;															\ \ CORE

ext-wordlist set-current
: w,																			
  here 2 allot w!
;
forth-wordlist set-current
: , here 1 cells allot !  ;														\ \ CORE

\ ---------------------------------------------------------------------------------------------
internals set-current

: link>flag			1 cells + ;
: link>name			link>flag 1+ ;													
: link>xt			link>name dup c@ + 1+ ;
: flag>link 		-1 cells + ;
: name>flag 		1- ;

: >name
  dup [ opTOR c, ]
  [ here ]							\ begin
    1-
    dup dup 1+ swap c@ + [ opRFETCH c, ]  =
  [ opQBRANCH c, here - 2 - w, ]	\ until
	[ opRFROM c, ] drop
;

: >link >name name>flag flag>link ;

forth-wordlist set-current
\ ---------------------------------------------------------------------------------------------


ext-wordlist set-current
: cells+ cells + ;
forth-wordlist set-current

: cell+ 1 cells+ ;																\ \ CORE

: immediate																		\ \ CORE
  opIMMEDIATE
  get-current @ link>flag
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

: chars ;																		\ \ CORE
: char+ 1+ ;																	\ \ CORE

: r>																			\ \ CORE
  [ opRFROM c, 
    opRFROM c, 
    opSWAP c, 
	opTOR c, ]
; opRFROM get-current @ link>flag c!			\ set compile time behavior to lay opcode

: 2r>																			\ \ CORE EXT
  [ opRFROM c, 
    opRFROM c, 
	opRFROM c,	
    opSWAP c, 
	opROT c,
	opTOR c, ]
; op2RFROM get-current @ link>flag c!

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
; opRFETCH get-current @ link>flag c!

: >r																			\ \ CORE
  [
	opRFROM c,
	opSWAP c,
	opTOR c,	
	opTOR c,	
  ]
; opTOR get-current @ link>flag c!

: 2>r
  [	
	opRFROM c,	
	opROT c,
	opTOR c,
	opSWAP c,
	opTOR c,
	opTOR c,
  ]
; op2TOR get-current @ link>flag c!

: 2r@ 																			\ \ CORE-EXT
  [ 
	opRFROM c,
	opRFROM c,
	opDUP c,
	opRFROM c,		\ ret a b --
	opDUP c,		\ ret a a b b --
	opTOR c,		\ ret a a b
	opROT c,		\ ret a b a
	opTOR c,		\ ret a b
	opROT c,
	opTOR c,
	opSWAP c,
  ]
; op2RFETCH get-current @ link>flag c!

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

: dnegate																		\ \ DOUBLE
  0 0 2swap d-
;

internals set-current

: resolvok?			\ d -- d | throw
  2dup  32768 0 dnegate d< >r
  2dup 32767 0 2swap d<
  r> or
  -100 swap 
  [ opQTHROW c, ]	
;

: resolv!		\ store a-addr --
  dup 0 here 0 2swap d- 2 0 d-
  resolvok? drop
  swap w!
;

: resolv, 		\ a-addr --
  0 here 0 d- 2 0 d-
  resolvok? drop
  w,
;
forth-wordlist set-current

\ TODO - consider an opcode ?DUP?BRANCH and words using it ?dupif ?dupwhile

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

: compile,																		\ \ CORE-EXT
  dup >link link>flag c@ dup opIMMEDIATE = swap opNONE = or if
	dup 65536 < if
		opSHORT_CALL c, w,
	else
	  	opCALL c, ,
	then
  else
    >link link>flag c@ c,
  then
;

: get-order																		\ \ SEARCH-ORDER
  0 0 begin
    dup SIZE_ORDER <>
  while						\ widN .. wid1 N i --
	A_ORDER over cells+ @	\ widN .. wid1 N i ? --
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

: [fake-variable]
  opCALL c, here 2 cells+ , 0 , opRFROM c,
; immediate

: [fake-defer]	
  here 6 + 2 cells + opDOLIT c, ,	\ 0	
  opFETCH c,						\ 1 + cell 
  here 3 + cell+ opDOLIT c, ,		\ 2 + cell
  opTOR c,							\ 3 + 2cells
  opTOR c,							\ 4 + 2cells
  opRET c,							\ 5 + 2cells
  here 1- ,							\ 6 + 2cells
; immediate

forth-wordlist set-current

: >body 1+ @ ; 																	\ \ CORE
: defer! >body ! ;																\ \ CORE-EXT
: defer@ >body @ ;																\ \ CORE-EXT

internals set-current
: end-locals [fake-defer] ;
: forget-locals [fake-defer] ;
forth-wordlist set-current

: exit end-locals opRET c, ; immediate											\ \ CORE

: also																			\ \ SEARCH-ORDER
  get-order over swap 1+ set-order
;

: forth																			\ \ SEARCH-ORDER
  get-order nip forth-wordlist swap set-order
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
	1+ swap 1-
  repeat
  2drop
;

: count dup 1+ swap c@ ;														\ \ CORE

ext-wordlist set-current
: ctype count type ;		
forth-wordlist set-current

internals set-current
: litops
  opLITM1 -1
  opLIT0 0
  opLIT1 1
  opLIT2 2
  opLIT3 3
  opLIT4 4
  opLIT5 5
  opLIT6 6
  opLIT7 7
  opLIT8 8
  10
;

: [literal]
  >r litops
  begin
    ?dup 
  while					\ pairs count -- | R: lookfor --
    1- rot rot r@ =	
	if 
		c,
		begin
		  ?dup
		while
		  nip nip
		  1-
		repeat
		r> drop
		exit
   else
	 drop
   then
  repeat
  r>
  dup 0 65536 within if
	opDOLIT_U16 c, w,
  else
    dup 0 256 within if
      opDOLIT_U8 c, c,
    else
      opDOLIT c, ,
    then
  then
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

: char																			\ \ CORE
  parse-name 0= if
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
  begin
	?dup
  while
	r> emit
    1-
  repeat
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
  [char] ) parse type
; immediate

: search-wordlist	\ c-addr u wid -- 0 | xt 1 | xt -1 							\ \ SEARCH-ORDER
  begin
    ?dup
  while
    over over link>name c@ =			\ c-addr u wid --
	if
	  2 pick 2 pick						\ c-addr u wid c-addr u wid 
	  2 pick link>name count
	  [ opICOMPARE c, ]
	  0= if \ c-addr u link --
        nip nip
		dup 
		link>xt 
		swap link>flag c@ opIMMEDIATE = if
		  1
		else
	      -1
		then
	    exit
	  then
	then
	@
  repeat
  2drop 0
;

: $find		\ c-addr u -- 0 | xt 1 | xt -1 
  2>r
  get-order locals-wordlist swap 1+ 
  begin
    dup
  while
	1- swap
	2r@ rot search-wordlist ?dup if
		2r> 2drop
		2>r
		begin ?dup while nip 1- repeat
		2r>
		exit
	then
  repeat
  2r> 2drop
;

forth-wordlist set-current

: find																			\ \ CORE SEARCH-WORDLIST
  dup >r count $find dup if
	r> drop
  else
	r> swap
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
: exception-info [fake-variable] ;
: line# [fake-variable] ;
: file$ [fake-variable] ;
forth-wordlist set-current

0 exception-info !

: cmove>																		\ \ STRING
  ?dup if
    		\ a1 a2 l --
    rot over + 1-		\ a2 l A1 --
    rot	2 pick + 1-		\ l A1 A2 --
    rot
	begin
	  ?dup 0>
    while
      2 pick c@ 2 pick c!
  	  1- rot 1- rot 1- rot
    repeat
	2drop
  else
    2drop
  then
;

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

: /string																		\ \ STRING
  ?dup if
    tuck - rot rot + swap
  then
;

internals set-current

\ Exception information is stored at HERE
\		offset			use
\		0				exception code
\		4				>in value
\		8				#tib value
\		12				line# value
\		16				file$ value
\		20+				input-text
\
\ ( for abort" the input-text is actually the abort" )

: >except
  ?dup if
	exception-info @ if
	  drop 
	else
	  here >r
  	  \ abort" is a special case, it already has a string at here that I need to move
	  dup -2 = if
		r@ count					\ except# c-addr u --
		swap over					\ except# u c-addr u --
		r@ 5 cells+ swap cmove>		\ except# u -- ; u is #tib
		0 swap						\ code toin htib --
	  else
		tib @ r@ 5 cells+ #tib @ cmove>
		>in @ #tib @
	  then

	  r@ 2 cells+ !
	  r@ cell+ !
	  r@ !

	  file$ @ r@ 4 cells+ !
	  line# @ r> 3 cells+ !
	  1 exception-info !
    then
  then
;

: ab"
  [ ahead 
    7 c, char a c, char b c, char o c, char r c, char t c, char " c, bl c, 
    then 
    here 8 - literal ]
;

: "ue"
  [ ahead
    21 c, char U c, char n c, char h c, char a c, char n c, char d c, char l c,
    char e c, char d c, bl c, char E c, char x c, char c c, char e c, char p c,
    char t c, char i c, char o c, char n c, bl c, char # c,
    then
    here 22 - literal ]
;

: .exception [fake-defer] ;
here ] . [ opRET c, parse-name .exception $find drop defer!

: .except
  exception-info @ if
	0 exception-info !
	here >r

    r@ @ -2 = if
 	  cr ab" ctype 
 	  r@ 5 cells+ r@ 2 cells+ @ type 
      [char] " emit
    else
      cr "ue" ctype here @ .exception 
	  cr r@ 5 cells+ r@ 2 cells+ @ type
	  cr

	  r@ 5 cells+
	  r@ 1 cells+ @ 

	  begin
		?dup
	  while
		over c@
		rot 1+ rot rot
		9 <> if bl else 9 then
	    emit
		1-
	  repeat
	  drop [char] ^ emit
    then
	r@ 3 cells+ @ 0 > if
		4 spaces [char] @ emit r@ 3 cells+ @ .
		r@ 4 cells + @ ?dup if
		  2 spaces [char] [ emit ctype [char] ] emit
	    then
 	then
	r> drop
  then
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
		.except
		(abort)
	then

    exception-handler @ rsp!
    r> exception-handler !
	r> swap >r
	sp! drop r>
  then
;

: [']																			\ \ CORE
  parse-name $find 0= if -13 throw then [literal]
; immediate

: abort																			\ \ CORE EXCEPTION
  -1 throw
; 

: '																				\ \ CORE
  parse-name $find 0= if -13 throw then 
;

' throw A_THROW !

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
	parse-name $find ?dup 0= if
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

: again																			\ \ CORE-EXT
  0 postpone literal
  postpone until
; immediate

: c"																			\ \ CORE
	[char] " parse			\ c-addr u --
	dup 255 > if -18 throw then
	opDOCSTR c, 
	dup c,					\ c-addr u --
	here over allot		
	swap move
; immediate

internals set-current
: the-s"buffer [fake-variable] ;
here SIZE_INPUT_BUFFER 3 * allot the-s"buffer !
: which-s"buffer [fake-variable] ;
0 which-s"buffer !

: ^s"-buffer 
  the-s"buffer @ which-s"buffer @ SIZE_INPUT_BUFFER * +
  which-s"buffer @ 1+
  dup 3 = if
    drop 0
  then
  which-s"buffer !
;

forth-wordlist set-current

: s"																			\ \ CORE / FILE-ACCESS
  state @ if
	postpone c"				\ Warning! assumes 255 chars max for S"
	postpone count
  else
	  ^s"-buffer 
      [char] " parse				\ tmp c-addr u --
      swap 2 pick 2 pick			\ tmp u c-addr tmp u --
	  move
  then
; immediate

: abort"																		\ \ CORE EXCEPTION
	postpone ?dup
	postpone if
	postpone s"
    postpone dup
    postpone here	
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
	here cell+ 10 + ,			\ depends on instruction count below! ( and 1 byte fr the opDOLIT in do )

	opFETCH c,
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
  dup 0 > if
    r> r>				\ return N limit idx -- | exit-addr --
    rot +				\ return limit idx+N | exit-addr --
    2dup > 0=			\ return limit idx+N flag | exit-addr --
  else
    r> r>				\ return N limit idx -- | exit-addr --
    rot +				\ return limit idx+N | exit-addr --
    2dup > 		\ return limit idx+N flag | exit-addr --
  then
  swap >r			\ return limit flag | exit-addr idxN --
  swap >r			\ return flag | exit-addr idxN limit --
  swap >r			\ flag | exit-addr idxN limit return --
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
  r> r> r>		\ todo rpick would be nice
  dup >r
  swap >r
  swap >r
;

: j																				\ \ CORE
  r> r> r> r> r> r>
  dup >r
  swap >r
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

\ consider an opcode for OVER=QBRANCH and use

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

: n>r dup begin dup while rot r> swap >r >r 1- repeat drop r> swap >r >r ;		\ \ PROGRAMMING-TOOLS
: nr> r> r> swap >r dup begin dup while r> r> swap >r rot rot 1- repeat drop ;	\ \ PROGRAMMING-TOOLS

\ Really might be better to have the word linked on create but invisible until ;
\ so I can do away with the extra flag on colon-sys and this variable.
\ maybe setting high bit of the name could be used as making a work invisible?
internals set-current
: current-xt [fake-variable] ;		\ for recurse
0 current-xt !
forth-wordlist set-current

: :noname																		\ \ CORE-EXT
  0 here 		
  1 state !
  here current-xt !		\ for recurse
;

: :																				\ \ CORE
  here 0				\ colon-sys --
  get-current @ ,
  opNONE c,
  parse-name 
  dup c,			\ colon-sys c-addr u --
  here over allot		\ colon-sys c-addr u here --
  swap move
  1 state !
  here current-xt !		\ for recurse
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

: recurse																		\ \ CORE
  current-xt @ opCALL c, , 
; immediate

internals set-current
: last [fake-variable] ;

: ($create)
  2>r
  here  dup last !
  get-current @ ,
  get-current !					\ warning, I don't really want the definition on the wordlist until it's complete !
  opNONE c,
  2r> dup c,
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

forth-wordlist set-current

: create																		\ \ CORE
  parse-name ($create)
;

internals set-current
: (does>)																		
  last @ link>xt 
  1+ cell+ 1+		\ skip DOLIT val, opDOLIST (see create above)
  !					\ and patch the call target ( the lit pushed as >r ret jump )
;
forth-wordlist set-current

: does>																			\ \ CORE
  end-locals
  opDOLIT c, 
  here cell+ 1+ cell+ 1+  ,		\ HERE + lit + CALL + address + RET
  opCALL c, ['] (does>) , 	\ *was* postpone (does>), see above
  opRET c,
; immediate

: constant create , does> @ ;													\ \ CORE
: variable create 0 , does> ;													\ \ CORE
: buffer: create allot ;														\ \ CORE-EXT
: value create , does> @ ;														\ \ CORE-EXT
: 2constant create , , does> dup cell+ @ swap @ ;								\ \ DOUBLE
: 2variable create 0 , 0 , ;													\ \ DOUBLE

variable blk																	\ \ BLOCK

\ See also the environment string for the size of this buffer
84 buffer: pad																	\ \ CORE-EXT

\ a bit of a lie atm since we're technically including from a file
\ but for bootstrap purposes we pretend we're not
0 value source-id																\ \ CORE-EXT

: to																			\ \ CORE-EXT
	parse-name

	2dup locals-wordlist search-wordlist if
		\ TODO - move as a factor to locals.fth
		nip nip
		1+ @		\ get the literal from the first instruction in the word
		opDOLIT c,
		,
		opLSTORE c,
		exit
	then

	$find 0= if -13 throw then
	state @ if
		[literal]
		postpone >body
		postpone !
	else	
		>body !
	then
; immediate

: defer create ['] abort , does> @ execute ;									\ \ CORE-EXT

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

: align	;																		\ \ CORE
: aligned ;																		\ \ CORE

: save-input																	\ \ CORE-EXT
  line# @
  file$ @
  tib @
  #tib @
  >in @
  blk @
  source-id
  7
;

: restore-input																	\ \ CORE-EXT
  7 <> if -12 throw then
  to source-id
  blk !
  >in !
  #tib !
  tib !
  file$ !
  line# !
;

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

ext-wordlist set-current
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
		r> 0 d+
		r> 
		r> 
	0 until
;

: 2literal swap postpone literal postpone literal ; immediate					\ \ DOUBLE

internals set-current
: [2literal] postpone 2literal ;
forth-wordlist set-current

\ some folks call this 'interpret' :-)
internals set-current
: (evaluate)																	
  begin
	parse-name ?dup
  while
	2dup $find ?dup if
		rot drop rot drop
		1 = if
			execute
		else
			state @ if compile, else execute then
		then
	else
		over c@ dup	[char] - = if drop -1 >r 1 /string else [char] + = if 1 /string then 1 >r then

		0 0 2swap >number ?dup 0= if
			drop
			if -24 throw then
			r> * state @ if [literal] then
		else
			S" ." compare if
				2drop
				-13 throw
			then
			r> -1 = if dnegate then
			state @ if [2literal] then
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
  0 blk !
  -1 to source-id
  -1 line# !
  0 file$ !
  ['] (evaluate) catch >r
  restore-input r> throw
;

: source																		\ \ CORE
  tib @ #tib @
;

\ Key values from my mac

127 constant k-delete															\ \ FACILITY-EXT
23361 constant k-up																\ \ FACILITY-EXT
23362 constant k-down															\ \ FACILITY-EXT
23363 constant k-right															\ \ FACILITY-EXT
23364 constant k-left															\ \ FACILITY-EXT

: at-xy	27 emit [char] [ emit 1+ . [char] ; emit 1+ . [char] H emit ;			\ \ FACILITY

internals set-current
defer at-idle
:noname ; is at-idle
forth-wordlist set-current

: ekey																			\ \ FACILITY-EXT
  begin
	[ opEKEY c, ]	
    dup 0< 
  while
    drop
	at-idle
  repeat
;

: key																			\ \ CORE
  begin
    ekey dup 255 > if
		drop 0
	else
		1
	then
  until
;

: accept		\ addr max -- count												\ \ CORE
  swap 0		\ max addr count --
  begin
    key
	case			\ max addr count key --
       8 of  8 emit bl emit 8 emit rot 1- rot 1- rot endof
      127 of 8 emit bl emit 8 emit rot 1- rot 1- rot endof
	  13 of endof
	  10 of emit nip nip exit endof
	  dup emit
	  dup 3 pick c!
	  rot 1+ rot 1+ rot
	endcase
    2 pick over =
  until
  nip nip	
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

: refill																		\ \ CORE-EXT FILE BLOCK
  blk @ if -21 throw then

  source-id
  case
  -1 of false swap endof
  0 of tib @ SIZE_INPUT_BUFFER accept #tib ! 0 >in ! true swap endof

  drop 

  1 line# +!

  tib @ SIZE_INPUT_BUFFER 2 - source-id read-line 
  if 
	2drop false 
	exit
  then

  false = if
	drop false
    exit
  then

  dup SIZE_INPUT_BUFFER 2 - = if -18 throw then

  #tib !
  0 >in !
  true
  0 endcase
;

: ( 																			\ \ CORE FILE
  source-id 0> if
    begin
	  begin
	    source nip >in @ <>
	  while
	    source drop >in @ + c@ 
		1 >in +!
		[char] ) = if exit then
	  repeat
	  refill
	  0=
	until
  else
    [char] ) parse 2drop
  then
; immediate	

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

: d0< 0 0 d< ;																	\ \ DOUBLE
: s>d dup 1 1 cells 8 * 1- lshift and if -1 else 0 then ;						\ \ CORE
: d>s drop ;																	\ \ DOUBLE
: / >r s>d r> sm/rem nip ;														\ \ CORE		
: mod >r s>d r> sm/rem drop ;	 												\ \ CORE
: /mod >r s>d r> sm/rem ;														\ \ CORE
: 2* 2 * ;																		\ \ CORE
: 2/ 2 / ;																		\ \ CORE

: max 2dup > if drop else nip then ;											\ \ CORE
: min 2dup > if nip else drop then ;											\ \ CORE

: 2@ dup cell+ @ swap @ ;														\ \ CORE
: 2! swap over ! cell+ ! ;														\ \ CORE

: fm/mod																		\ \ CORE
  dup >r sm/rem		
  over dup 0< swap 0> -
  r@   dup 0< swap 0> -
  negate = if
	1- swap r> + swap
  else
    r> drop
  then
;

: */  >r m* r> sm/rem nip ;														\ \ CORE
: */mod >r m* r> sm/rem ;														\ \ CORE

ext-wordlist set-current
: stub:
  create
    immediate
	get-current @ ,
    parse-name 
    dup c,
    here over allot
    swap move
  does>
	cr dup @ link>name ctype 
    space [char] ( emit 
    cell+ ctype 
    ." ) not implemented." cr
	-1 throw
;
forth-wordlist set-current

\ ---------------------------------------------------------------------------------------------
\ environment support
\ ---------------------------------------------------------------------------------------------

internals set-current
wordlist constant ENVIRONMENT-wid
ENVIRONMENT-wid set-current

: /COUNTED_STRING		255 ;
: /HOLD					SIZE_PICTURED_NUMERIC ;
: /PAD					84 ;										\ FIXME should be a bootstrap const. see alsoPAD
: ADDRESS-UNIT-BITS		1 cells 8 * ;									
: FLOORED				0 ;
: MAX-CHAR				255 ;
stub: MAX-D
stub: MAX-N
stub: MAX-U
stub: MAX-UD
: RETURN-STACK-CELLS	A_SIZE_RETURNSTACK @ ;
: STACK-CELLS			A_SIZE_DATASTACK @ ;

forth-wordlist set-current

: environment?																	\ \ CORE
	ENVIRONMENT-wid search-wordlist if
	  execute true
    else
	  false
    then
;

ext-wordlist set-current
: env-constant
  get-current environment-wid set-current
  create
    set-current
    ,
  does>
    @
;

forth-wordlist set-current

\ ---------------------------------------------------------------------------------------------
\ ---------------------------------------------------------------------------------------------

: -trailing																		\ \ STRING
  begin
    dup 0= if exit then
    2dup 1- + c@ bl <> if exit then
	1-
  again
;

: blank bl fill ;																\ \ STRING

: cmove 																		\ \ STRING
  begin
    ?dup 0>
  while
    \ a1 a2 l --
    2 pick c@ 2 pick c!
	1- rot 1+ rot 1+ rot
  repeat
  2drop
;

: sliteral																		\ \ STRING
  2>r
  postpone ahead 
  2r>
  dup >r
  here >r
  dup allot
  r@ swap move
  postpone then
  r> [literal]
  r> [literal]
; immediate

\ ---------------------------------------------------------------------------------------------
\ ---------------------------------------------------------------------------------------------

ENVIRONMENT-wid set-current
0 value #LOCALS
forth-wordlist set-current

defer (local)
defer locals| immediate
defer {: immediate

:noname 1 abort" locals.fth not included" ;
dup is (local)
dup is locals|
    is {:

\ ---------------------------------------------------------------------------------------------
\ Files
\ ---------------------------------------------------------------------------------------------

forth-wordlist set-current

: bin ;																			\ \ FILE

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

ext-wordlist set-current
: save
  parse-name
  0 create-file if 
    -63 throw
  else
	\ fd --
	dup 0 here rot write-file if -75 throw then
	close-file if -62 throw then
  then
; 

internals set-current

wordlist constant wid-files

: +file
  get-current >r
  wid-files set-current
  ($create) 
	0 ,
	r> set-current
  does>
	@
;

: (include-file)					\ caddr u -- descriptor --
  save-input n>r 
  to source-id
  0 line# !

  2dup cr ." Including " type
  +file

  wid-files @ link>name file$ !

  begin 
	refill 
  while
	['] (evaluate) catch
	?dup if
		dup >except
		source-id close-file drop
		nr> restore-input
		throw
	then
  repeat 
  source-id close-file drop

  here file$ @ - file$ @ count + >body !

  nr> restore-input
;

forth-wordlist set-current

: include-file																	\ \ FILE
  0 0 rot (include-file)
;

: included																		\ \ FILE
  2dup r/o open-file if -69 throw then
  (include-file)
;

: include																		\ \ FILE
  parse-name included
;

: required																		\ \ FILE
  2dup wid-files search-wordlist if 
    drop
    2drop
  else
    included
  then
;

: require																		\ \ FILE
  parse-name required
;

\ ---------------------------------------------------------------------------------------------
\ 
\ ---------------------------------------------------------------------------------------------

stub: s\"	CORE-EXT,FILE
stub: d. 	DOUBLE
stub: d.r	DOUBLE
stub: d0=	DOUBLE
stub: d2*	DOUBLE
stub: d2/	DOUBLE
stub: d=	DOUBLE
stub: dabs	DOUBLE
stub: dmax	DOUBLE
stub: dmin	DOUBLE
stub: m*/	DOUBLE
stub: m+	DOUBLE
stub: search 	STRING

\ ---------------------------------------------------------------------------------------------

internals set-current
: [icompare]
  opICOMPARE c, 
; immediate

forth-wordlist set-current

: ?	@ . ;																		\ \ PROGRAMMING-TOOLS
: [defined] parse-name $find if drop true else false then ; immediate			\ \ PROGRAMMING-TOOLS
: [undefined] parse-name $find if drop false else true then ; immediate			\ \ PROGRAMMING-TOOLS
: [then] ; immediate															\ \ PROGRAMMING-TOOLS
: [else]																		\ \ PROGRAMMING-TOOLS
  1 begin
    begin 
      parse-name 
	  dup
    while
      2dup s" [if]" [icompare] 0= if	
        2drop 1+
	  else
        2dup s" [else]" [icompare] 0= if
	      2drop 1- dup if 1+ then
		else
		  s" [then]" [icompare] 0= if 1- then
		then
	  then ?dup 0= if exit then
	repeat 2drop
  refill 0= until drop
; immediate
: [if] 0= if postpone [else] then ; immediate									\ \ PROGRAMMING-TOOLS

\ no intention of supporting
stub: assembler PROGRAMMING-TOOLS
stub: code PROGRAMMING-TOOLS
stub: ;code	PROGRAMMING-TOOLS

\ do not need
stub: cs-pick PROGRAMMING-TOOLS
stub: cs-roll PROGRAMMING-TOOLS

\ do not like
stub: forget PROGRAMMING-TOOLS
stub: synonym PROGRAMMING-TOOLS

: name>string																	\ \ PROGRAMMING-TOOLS
  link>name count
;

\ N.B this does not include the knowledge that some words can at compile time lay an opcode
\ that bit of knowledge only currently exists in the core

: name>compile																	\ \ PROGRAMMING-TOOLS
  dup link>xt swap
  link>flag c@ opIMMEDIATE = if ['] execute else ['] compile, then
;

: name>interpret																\ \ PROGRAMMING-TOOLS
  dup link>xt swap
  link>flag c@ opIMMEDIATE = if 0 else ['] execute then
;

\ To maximize the use of this, I consider a NT to be the start of header
: traverse-wordlist 															\ \ PROGRAMMING-TOOLS
  swap >r @
  begin
	dup if 
	  dup r@ execute if @ else drop 0 then
    then
    ?dup 0=
  until
  r> drop
;

internals set-current
: (words) name>string type space true ;
forth-wordlist set-current

: words																			\ \ PROGRAMMING-TOOLS
  ['] (words) get-current traverse-wordlist 
;  

ext-wordlist set-current

: aschar 
  dup bl < if drop [char] . else
  dup [char] z > if drop [char] . else
  then then
;

internals set-current
: .8		\ v --
  0 <# # # # # # # # # #> type
;

: .4		\ v --
  0 <# # # # # #> type
;

: .2		\ v --
  0 <# # # #> type
;
	
: .N		\ v --
  0 <# #s #> type
;

forth-wordlist set-current

: dump		\ a-addr len --														\ \ PROGRAMMING-TOOLS
  base @ >r hex
  over +	

  begin			\ ptr end --
	2dup <
  while
    cr
    over .8 ." : "

	16 0 do	
		over i + over < if over i + c@ .2 bl emit else 3 spaces then
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
  r> base !
;

defer dis :noname 1 abort" disassembler not built (dis.fth)" ; is dis
forth-wordlist set-current

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

: see parse-name $find if 20000 dis then ;										\ \ PROGRAMMING-TOOLS

ext-wordlist set-current
: .rs
  cr
  rsp@ >r nr> 
    dup
    1- 0 begin
      2dup <>
    while
      dup 3 + pick cr 10 .r
  	  1+
    repeat
    2drop 
	."  top"
  n>r r> drop
;
forth-wordlist set-current

internals set-current
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

: traverse-all-wordlists
  >r
  \ get all wordlists 1st word pointer
  0 A_LIST_OF_WORDLISTS >r
  begin
    r@ @ ?dup
  while		
	@ swap 1+
    r> @ -1 cells+ >r
  repeat  
  r> drop
  \ N...1 count --
  begin
    drop-empty
    ?dup
  while			\ widN .. wid1 n --
	get-highest	dup >r 
	pick 
    r> r@ swap >r
    execute 0= if 
		r> drop
		begin dup while nip 1- repeat 
	else
    	r> 
		n>r @ nr> drop 
	then
  repeat
  r> drop
;

ext-wordlist set-current

: allwords ['] (words) traverse-all-wordlists ;
forth-wordlist set-current

\ ---------------------------------------------------------------------------------------------

internals set-current
: noblock 1 abort" block.fth not built" ;
forth-wordlist set-current
0 blk !

variable scr																	\ \ BLOCK
0 scr !

defer empty-buffers																\ \ BLOCK
defer save-buffers																\ \ BLOCK
defer block																		\ \ BLOCK
defer buffer																	\ \ BLOCK
defer update																	\ \ BLOCK

' noblock is empty-buffers
' noblock is save-buffers
' noblock is block
' noblock is buffer
' noblock is update

: flush		save-buffers empty-buffers ;										\ \ BLOCK

: list 																			\ \ BLOCK
  dup scr !
  block
  16 0 do
    cr 
	64 0 do
		dup c@ 32 127 within if dup c@ else [char] . then emit
		1+
    loop	
  loop
  drop
;

internals set-current
: (load) 
  dup >r 
  block tib ! 1024 #tib ! 0 >in ! 
  r> blk !
  (evaluate) 
  0 blk !
;
forth-wordlist set-current

: load																			\ \ BLOCK
  save-input n>r
  ['] (load) catch 
  dup >except
  nr> restore-input
  throw
;

: thru	1+ swap ?do i load loop ; 												\ \ BLOCK

\ ---------------------------------------------------------------------------------------------

internals set-current
: (trim)		\ list cut-off --
  over @ 0= if 2drop exit then		\ empty list, nothing to do
  over 
  begin		\ list cut-off next --
	@ 2dup >
  until
  nip swap !
;
forth-wordlist set-current

: marker																		\ \ CORE-EXT
  here
  create
	,
	get-current ,
    here SIZE_ORDER cells allot
	A_ORDER swap SIZE_ORDER cells move
  does>
	>r
	A_LIST_OF_WORDLISTS @
	begin
		dup r@ @ (trim) 
		-1 cells+ @
		?dup 0=
	until

	begin
		A_LIST_OF_WORDLISTS @ r@ @ 
		>
    while
		A_LIST_OF_WORDLISTS @ -1 cells+ @ A_LIST_OF_WORDLISTS !
	repeat

	r@ cell+ @ set-current
	r@ cell+ cell+ A_ORDER SIZE_ORDER cells move

	r> @ 
    A_HERE !
;

internals set-current
: ^word-buffer [fake-variable] ;
here 33 allot ^word-buffer !
forth-wordlist set-current

: word																			\ \ CORE
  ^word-buffer @ >r
  bl (parse) dup 33 > if -18 throw then
  dup r@ c!
  r@ 1+ swap move
  r>
;

\ ---------------------------------------------------------------------------------------------
\
\ ---------------------------------------------------------------------------------------------

internals set-current

wordlist constant wid-onboot

: (onboot)
  link>xt
  ['] execute catch if cr ." Warning exceptions in boot code" then
  true
;

: onboot
  ['] (onboot) wid-onboot traverse-wordlist
  cr
;

' onboot A_SETUP !

ext-wordlist set-current
: onboot: 
  get-current 
  wid-onboot set-current 
  : 
;

: onboot;
  postpone ;
  set-current
; immediate

\ ---------------------------------------------------------------------------------------------
\
\ Now we'll build a proper Forth interpreter and patch it in as entry point. 
\
\ ---------------------------------------------------------------------------------------------

internals set-current
: prompt?
  state @ 0= if
	cr 27 emit ." [0m" [char] [ emit depth . ." ] Ok. " cr
  then
;
forth-wordlist set-current

: quit																			\ \ CORE
  0 rsp!
  0 to source-id
  0 blk !
  -1 line# !
  0 file$ !
  postpone [
  begin
    refill 
  while
	['] (evaluate) catch
    dup >except
	0= if prompt? else
	.except postpone [ prompt? then
  repeat
  bye	
; 

' quit A_QUIT !	
only forth definitions


