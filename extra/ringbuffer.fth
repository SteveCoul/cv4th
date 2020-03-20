
( Generic ring buffer API )

ext-wordlist forth-wordlist internals 3 set-order definitions

: RingBuffer.inc		\ rb-addr offset --
  over 0 cells + @		\ rb-addr offset size --
  rot rot +				\ size ^ptr --
  dup @ 1+ rot mod		\ size ^ptr ptr+1%size
  swap !
;

: RingBuffer.incW		\ rb-addr --
  2 cells RingBuffer.inc
;

: RingBuffer.incR		\ rb-addr --
  1 cells RingBuffer.inc
;

: RingBuffer.add		\ byte rb-addr --
  dup 2 cells + @ swap 4 cells + + c!
;

ext-wordlist set-current

: RingBuffer:			\ size "name" --
  create
	dup ,				\ size
	0 ,					\ read-ptr
    0 ,					\ write-ptr
	0 ,					\ available
	allot				\ buffer
  does>
;

: RingBuffer.show		\ rb-addr
  cr ." RingBuffer " dup .
  cr ."   size " dup 0 cells + @ .
  cr ."   rptr " dup 1 cells + @ .
  cr ."   wptr " dup 2 cells + @ .
  cr ."   aval " dup 3 cells + @ .
  dup 4 cells + swap 0 cells + @ dump
;

: RingBuffer.empty		\ rb-addr --
  0 swap
  2dup 1 cells + !
  2dup 2 cells + !
       3 cells + !
;

: RingBuffer.size		\ rb-addr -- n
  0 cells + @
;

: RingBuffer.available	\ rb-addr -- n
  3 cells + @
;

: RingBuffer.push		\ byte rb-addr -- 0 | 1
  dup RingBuffer.size over RingBuffer.available = if 2drop 0 else
	tuck RingBuffer.add
	dup RingBuffer.incW	
    1 swap 3 cells + +!
	1
  then
;

: RingBuffer.pop		\ rb-addr -- v | 0
  dup RingBuffer.available 0= if
	drop 0
  else 			( rb-addr -- )
	dup 1 cells + @ over 4 cells + +	( rb-addr readaddr -- )
	c@ swap
	dup RingBuffer.incR
	-1 swap 3 cells + +!
  then
;

