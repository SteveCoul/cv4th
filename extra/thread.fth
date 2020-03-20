
( MultiThreading support cooperative scheduler 

  All threads must call 'schedule' as often as possible.

  - Only one thread should access pictured numeric buffer.
  - PAD is not thread safe.
  - Only one thread should perform any dictionary operations.
  - Invoking a MARKER which removes a thread definition will blow up.

)

forth-wordlist ext-wordlist internals 3 set-order
internals set-current

( The system context is defined in the virtual machine and is
  swapped with the opCONTEXT opcode between two threads.

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
	\ per-thread variables
	field: tc.base
	field: tc.exception-handler
	field: tc.^except
	\ thread data
	field: tc.entrypoint
	field: tc.link
end-structure

variable thread_list 0 thread_list !

0 value cthread

ext-wordlist set-current

: .thread		( thread -- )
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
  cr ."   exception-handler " dup tc.exception-handler @ .
  cr ."	  ^except " dup tc.^except @ .
  cr ."	  entrypoint " dup tc.entrypoint @ .
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
	exception-handler @ over tc.exception-handler !
	^except @ over tc.^except !
  then

  over tc.base @ base !
  over tc.exception-handler @ exception-handler !
  over tc.^except @ ^except !
  [ opCONTEXT_SWITCH c, ] 
;

ext-wordlist set-current

: schedule 
  cthread tc.system
  cthread tc.link @ ?dup if to cthread else thread_list @ to cthread then
  cthread tc.system 
  swap (schedule)
;

\ TODO when I have flags, we'll have one for 'restart on exception'
: thread-runner
  begin
	cthread tc.entrypoint @ catch >except
	cr ." Thread " cthread . ."  exiting" .except
	0 cthread tc.system sc.DP !
	0 cthread tc.system sc.RP !
  again
;

internals set-current

: (thread:)		( xt exceptbuffer ds rs -- )
  create
	here >r
	ThreadContext allot
	dup 0= if drop here A_SIZE_RETURNSTACK @ cells allot then
	over 0= if nip here A_SIZE_DATASTACK @ cells allot swap then
    2 pick 0= if rot drop here #except allot rot rot then
	( xt except-buffer rs ds -- : R: context^ -- )
	r@ tc.system >r
	( xt except-buffer rs ds -- R: context^ syscontext^ -- )
	['] thread-runner r@ sc.IP !
	0 r@ sc.DP !
	0 r@ sc.RP !
	0 r@ sc.LP !
    r@ sc.DS !
    r> sc.RS !

	r@ tc.^except !
	r@ tc.entrypoint !
	10 r@ tc.base !
    0 r@ tc.exception-handler !
	thread_list @ r@ tc.link !
	r> thread_list !
;

ext-wordlist set-current

: thread:		( xt -- )
  0 0 0 (thread:)
;

0 ^except @ A_DATASTACK @ A_RETURNSTACK @ (thread:) main-thread

internals set-current

: boot
  \ Get the QUIT vector out of main thread that we stored during boot setup
  \ to trigger this word and put it back so if I save an image it'll do the
  \ same thing again
  main-thread tc.entrypoint @ A_QUIT !
  main-thread to cthread					\ make this thread current
  ['] schedule is at-idle					\ enable idle scheduler
  main-thread 0 (schedule)								\ and off we go
  cr cr ." How did we get here?" cr cr
;

internals ext-wordlist forth-wordlist 3 set-order 

onboot: kickoff 
  A_QUIT @ main-thread tc.entrypoint !
  ['] boot A_QUIT !
onboot;

only forth definitions

