
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


3 constant max_threads
max_threads context-size cells * buffer: threads
0 value num_threads
0 value cur_thread

: inc_cur
  1 cur_thread + to cur_thread
  cur_thread num_threads = if 0 to cur_thread then
;

: schedule 
  num_threads if
	threads cur_thread context-size cells * +
	inc_cur
	threads cur_thread context-size cells * +
	swap
	[ opCONTEXT_SWITCH c, ] 
  then
;

: +thread	\ xt dstack rstack -- 
  threads num_threads context-size cells * + >r
  base @ r@ 6 cells + !
  r@ 5 cells + !
  r@ 4 cells + !
  0 r@ 3 cells + !
  0 r@ 2 cells + !
  0 r@ 1 cells + !
  r> !
  1 num_threads + to num_threads

;

variable threadone : thread1 begin 1 threadone +!  schedule again ; 
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




