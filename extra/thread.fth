
(
	system-context:
			instruction-pointer
			datastack-pointer
			returnstack-pointer
			locals-pointer
			datastack-base
			returnstack-base
)

internals get-order 1+ set-order

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
end-structure

3 constant max_threads
max_threads ThreadContext * buffer: threads

0 value num_threads
0 value cur_thread

: .thread
  base @ >r
  cr ." Thread " dup .
  cr ."   IP   " dup tc.system sc.IP @ .
  cr ."   DP   " dup tc.system sc.DP @ .
  cr ."   RP   " dup tc.system sc.RP @ .
  cr ."   LP   " dup tc.system sc.LP @ .
  cr ."   DS   " dup tc.system sc.DS @ .
  cr ."   RS   " dup tc.system sc.RS @ .
  cr ."   Base " dup tc.base @ .
  drop
  r> base !
;

: .threads num_threads 0 ?do threads i ThreadContext * + .thread loop ; 

: inc_cur
  1 cur_thread + to cur_thread
  cur_thread num_threads = if 0 to cur_thread then
;

: (schedule)				\ next prev --
  dup if
	base @ over tc.base !
  then

  over tc.base @ base !
  [ opCONTEXT_SWITCH c, ] 
;

: schedule 
  num_threads if
	threads cur_thread ThreadContext * + tc.system
	inc_cur
	threads cur_thread ThreadContext * + tc.system
	swap
    (schedule)
  then
;

: +thread	\ xt ds rs -- 
  threads num_threads ThreadContext * + >r
  base @ r@ tc.base !
  r@ tc.system sc.RS !
  r@ tc.system sc.DS !
  0 r@ tc.system sc.LP !
  0 r@ tc.system sc.RP !
  0 r@ tc.system sc.DP !
  r> tc.system sc.IP !
  1 num_threads + to num_threads
;

1024 buffer: ds
1024 buffer: rs
: thread begin schedule hex again ;
' thread ds rs +thread

variable boot-thread-context

: boot
  boot-thread-context @ tc.system sc.IP @ A_QUIT !	\ put quit vector back so if we save image it'll work again
  ['] schedule is at-idle
  boot-thread-context @ 0 
  0 to cur_thread
  begin
    threads cur_thread ThreadContext * + boot-thread-context @ <>
  while
    1 cur_thread + to cur_thread
  repeat
  (schedule)
  cr cr ." How did we get here?" cr cr
;

internals ext-wordlist forth-wordlist 3 set-order 

onboot: kickoff 
  A_QUIT @ A_DATASTACK @ A_RETURNSTACK @ +thread
  threads num_threads 1- ThreadContext * + boot-thread-context !
  ['] boot A_QUIT !
onboot;


