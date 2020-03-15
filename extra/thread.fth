
(
	context:
			instruction-pointer
			datastack-pointer
			returnstack-pointer
			locals-pointer
			datastack-base
			returnstack-base
			base
						I'm not saving pictured numeric, just don't schedule whilst using!
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

A_QUIT @ threads !
0 threads 1 cells + !
0 threads 2 cells + !
0 threads 3 cells + !
A_DATASTACK @ threads 4 cells + !
A_RETURNSTACK @ threads 5 cells + !
10 threads 6 cells + !
1 to num_threads

variable threadone : thread1 begin 1 threadone +!  schedule again ; 
1024 buffer: d1 1024 buffer: r1 
' thread1 d1 r1 +thread

onboot: kickoff 
  ['] schedule is at-idle
  schedule
onboot;




