
ext-wordlist forth-wordlist internals 3 set-order definitions

: locals-count [fake-variable] ;
: locals-here  [fake-variable] ;

1024 value local_dict_size

: compile-l@
  opDOLIT c, ,	
  opLFETCH c,
;

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

: (end-locals)
  locals-count @ if
	opLPFETCH c,
	opDOLIT c, 0 ,
	opLFETCH c,
	opLPSTORE c,
	opRSPSTORE c,
    0 locals-count !
  then
;
' (end-locals) is end-locals

: (forget-locals)	0 locals-wordlist !	;											
' (forget-locals) is forget-locals

: ((local))
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
		unused local_dict_size < abort" Not enough space for locals"
		0 locals-count !
		here unused + local_dict_size - locals-here !		
		\ build our locals words at end of dictionary so we can drop them 
	then

	locals-here @				\ c-addr u lh --

	locals-wordlist @ over ! 
    dup locals-wordlist !
	1 cells+

	opIMMEDIATE over c!  1+
	
	over over c!  1+

	2dup 2>r
	swap move
	2r>							\ u lh --	
	+							\ locals here

	opDOLIT over c! 1+
	locals-count @ 1+ over ! 1 cells+		
	opCALL over c! 1+
	['] compile-l@ over ! 1 cells+

	opRET over c!  1+

	locals-here !

	1 locals-count +!
  then
; 
' ((local)) is (local)

: (locals|)
  begin
  	parse-name
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
' (locals|) is locals|

: ({:) 
   0 parse-name scan-args scan-locals scan-end 2drop
   0 ?do (local) loop 
   0 0 (local)
; immediate

' ({:) is {: 

ENVIRONMENT-wid get-order 1+ set-order
16 to #LOCALS

only forth definitions

