
get-order internals swap 1+ set-order
 
: ?	@ . ;																		\ \ PROGRAMMING-TOOLS
: [defined] bl word find nip 0<> ; immediate									\ \ PROGRAMMING-TOOLS
: [undefined] bl word find nip 0= ; immediate									\ \ PROGRAMMING-TOOLS
: [then] ; immediate															\ \ PROGRAMMING-TOOLS
: [else]																		\ \ PROGRAMMING-TOOLS
  1 begin
    begin bl word count dup while
      2dup s" [if]" compare 0= if		\ FIXME case sensitivity
        2drop 1+
	  else
        2dup s" [else]" compare 0= if
	      2drop 1- dup if 1+ then
		else
		  s" [then]" compare 0= if 1- then
		then
	  then ?dup 0= if exit then
	repeat 2drop
  refill 0= until drop
; immediate
: [if] 0= if postpone [else] then ; immediate									\ \ PROGRAMMING-TOOLS
: n>r dup begin dup while rot r> swap >r >r 1- repeat drop r> swap >r >r ;		\ \ PROGRAMMING-TOOLS
: nr> r> r> swap >r dup begin dup while r> r> swap >r rot rot 1- repeat drop ;	\ \ PROGRAMMING-TOOLS

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
	?dup if 
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
  ['] (words) get-current @ traverse-wordlist
;  

