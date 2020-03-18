
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
	A_SIZE_DATASTACK	  +field	tc.ds
	A_SIZE_RETURNSTACK	  +field	tc.rs
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
  drop
  r> base !
;

: .threads num_threads 0 ?do threads i ThreadContext * + .thread loop ; 

: inc_cur
  1 cur_thread + to cur_thread
  cur_thread num_threads = if 0 to cur_thread then
;

: schedule 
  num_threads if
	threads cur_thread ThreadContext * + tc.system
	inc_cur
	threads cur_thread ThreadContext * + tc.system
	swap
	[ opCONTEXT_SWITCH c, ] 
  then
;

: +thread	\ xt dstack rstack -- 
  threads num_threads ThreadContext * + >r
  r@ tc.system sc.RS !
  r@ tc.system sc.DS !
  0 r@ tc.system sc.LP !
  0 r@ tc.system sc.RP !
  0 r@ tc.system sc.DP !
  r> tc.system sc.IP !
  1 num_threads + to num_threads
;

variable threadone 
variable trigger 0 trigger !
: thread1 
  cr ." Thread 1 start"
  begin 
    1 threadone +!  
    schedule 
    trigger @ 0 trigger ! ?dup if cr ." thread1 throwing" throw then
  again 
; 

1024 buffer: d1 1024 buffer: r1 
' thread1 d1 r1 +thread

: boot
  threads @ A_QUIT !	\ put quit vector back so if we same image it'll work again
  ['] schedule is at-idle
  threads 0 [ opCONTEXT_SWITCH c, ] 
  cr cr ." How did we get here?" cr cr
;

internals ext-wordlist forth-wordlist 3 set-order 

onboot: kickoff 
  A_QUIT @ A_DATASTACK @ A_RETURNSTACK @ +thread
  ['] boot A_QUIT !
onboot;




