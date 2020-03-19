
forth-wordlist ext-wordlist internals 3 set-order
internals set-current

(
	system-context:
			instruction-pointer
			datastack-pointer
			returnstack-pointer
			locals-pointer
			datastack-base
			returnstack-base
)

begin-structure SystemContext
	field: sc.IP
	field: sc.DP
	field: sc.RP
	field: sc.LP
	field: sc.DS
	field: sc.RS
end-structure

begin-structure	ThreadContext
	aligned SystemContext +field	tc.system
	field: tc.base
	field: tc.link
end-structure

variable thread_list 0 thread_list !

0 value cthread

ext-wordlist set-current

: .thread
  base @ >r
  cr ." Thread " dup .
  dup cthread = if ."  (Current)" then
  cr ."   IP   " dup tc.system sc.IP @ .
  cr ."   DP   " dup tc.system sc.DP @ .
  cr ."   RP   " dup tc.system sc.RP @ .
  cr ."   LP   " dup tc.system sc.LP @ .
  cr ."   DS   " dup tc.system sc.DS @ .
  cr ."   RS   " dup tc.system sc.RS @ .
  cr ."   Base " dup tc.base @ .
  cr ."   Link " dup tc.link @ .
  drop
  r> base !
;

: .threads
  thread_list @
  begin
    ?dup
  while
	dup .thread
	tc.link @
  repeat
;

internals set-current

: (schedule)				\ next prev --
  dup if
	base @ over tc.base !
  then

  over tc.base @ base !
  [ opCONTEXT_SWITCH c, ] 
;

ext-wordlist set-current

: schedule 
  cthread tc.system
  cthread tc.link @ ?dup if to cthread else thread_list @ to cthread then
  cthread tc.system 
  swap (schedule)
;

internals set-current

: (thread:)		( xt ds rs -- )
  create
	here >r
	ThreadContext allot
	dup 0= if drop here A_SIZE_RETURNSTACK @ cells allot then
	over 0= if nip here A_SIZE_DATASTACK @ cells allot swap then
	( xt rs ds -- : R: context^ -- )
	r@ tc.system >r
	( xt rs ds -- R: context^ syscontext^ -- )
	rot r@ sc.IP !
	0 r@ sc.DP !
	0 r@ sc.RP !
	0 r@ sc.LP !
    r@ sc.DS !
    r> sc.RS !

	10 r@ tc.base !
	thread_list @ r@ tc.link !
	r> thread_list !
;

ext-wordlist set-current

: thread:		( xt -- )
  0 0 (thread:)
;

0 A_DATASTACK @ A_RETURNSTACK @ (thread:) main-thread

internals set-current

: boot
  \ Get the QUIT vector out of main thread that we stored during boot setup
  \ to trigger this word and put it back so if I save an image it'll do the
  \ same thing again
  main-thread tc.system sc.IP @ A_QUIT !
  main-thread to cthread					\ make this thread current
  ['] schedule is at-idle					\ enable idle scheduler
  main-thread 0 (schedule)								\ and off we go
  cr cr ." How did we get here?" cr cr
;

internals ext-wordlist forth-wordlist 3 set-order 

onboot: kickoff 
  A_QUIT @ main-thread tc.system sc.IP !
  ['] boot A_QUIT !
onboot;

only forth definitions

