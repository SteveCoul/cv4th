
( todo reduce flash writes. when doing save buffers do them in order. also issue a flush call 
  to flash driver when done. this will allow the flash driver to put multiple blocks into
  what ever minimum size page it can handle an erase for )
	

ext-wordlist forth-wordlist internals 3 set-order definitions

[UNDEFINED] flash_read [IF]	
	cr .( You have not included a suitable flash driver yet, cannot build block without it ) abort [THEN]

S" #BLOCK_BUFFERS" environment? 0= [IF]  cr .( #BLOCK_BUFFERS not in environment ) abort [THEN]

constant #BLOCK_BUFFERS

#BLOCK_BUFFERS 1024 * buffer: block_buffers
#BLOCK_BUFFERS buffer: update_flags
#BLOCK_BUFFERS cells buffer: block_id

0 value current

: showblocks
  cr ." b-addr : "
  #BLOCK_BUFFERS 0 ?do
	block_buffers i 1024 * + 8 .r space
  loop
  cr ." assign : "
  #BLOCK_BUFFERS 0 ?do
	block_id i cells+ @ 8 .r space
  loop
  cr ." update?: "
  #BLOCK_BUFFERS 0 ?do
	update_flags i + c@ 8 .r space
  loop
;

: check#				( n -- n | throw-35 ) dup 1 FLASH_SIZE 1024 / 1+ within 0= if -35 throw then ;

: block_addr_to_idx		( b-addr -- u )
  block_buffers - 1024 /
;

: >current				( u -- )
  to current
;

: find-block			( u -- block-addr | 0 )
  #BLOCK_BUFFERS 0 ?do
     block_id i cells + @ over = if 
       drop block_buffers i 1024 * + 
	   unloop exit 
     then
  loop drop 0
;

: isupdated?				( u -- flag ) 
  update_flags + c@ 
;

\ FIXME dont always return same, prefer to unassign an unmodified block
: pick-block-to-unassign	( -- u )
  0
;

: readblock				( idx -- )
  dup 1024 * block_buffers + swap
  cells block_id + @ 1- 1024 * FLASH_BASE + 
  1024 flash_read if -33 throw then
;

: writeblock			( n -- )
  dup 1- 1024 * FLASH_BASE +
  swap find-block 1024 flash_write if -34 throw then
;

: assign				( block idx -- )
  cells block_id + !
;

: unassign				( idx -- )
  -1 swap cells block_id + !
;

: (buffer)
  check# >r
  r@ find-block ?dup if r> >current else
	-1 find-block ?dup if
	  dup block_addr_to_idx
	  r@ swap assign
	  r> >current
    else
	  pick-block-to-unassign
	  dup isupdated? if
		dup writeblock
		0 over update_flags + c!
	  then
      unassign
	  r> recurse
    then
  then
; 

: (block)
  (buffer) dup block_addr_to_idx readblock
; 

: (update)
  current check# 
  find-block ?dup if
	block_addr_to_idx update_flags + -1 swap c!
  then
; 

: (empty-buffers)
  update_flags #BLOCK_BUFFERS 0 fill
  block_Id #BLOCK_BUFFERS cells 255 fill
  -1 to current
;

: (save-buffers)
  #BLOCK_BUFFERS 0 ?do
	update_flags i + c@ if
	  block_id i cells + @ writeblock
    then
  loop
  update_flags #BLOCK_BUFFERS 0 fill
; 

' (empty-buffers) ' empty-buffers defer!
' (save-buffers) ' save-buffers defer!
' (block) ' block defer!
' (buffer) ' buffer defer!
' (update) ' update defer!

\ This is the init code for this module, I need some mechanism in the core
\ to add this to a chain of things to be called on startup to reset the
\ buffer control information (FIXME/TODO)
:noname				( -- )
  empty-buffers
; execute

only forth definitions

