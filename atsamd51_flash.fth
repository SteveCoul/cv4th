
ext-wordlist forth-wordlist internals 3 set-order definitions

1 cells 4 = 0= [IF] cr .( Driver assumes 32bit build ) abort [THEN]
S" /FLASH_BASE" environment? 0= [IF]  cr .( /FLASH_BASE not in environment ) abort [THEN] constant FLASH_BASE
S" /FLASH_SIZE" environment? 0= [IF]  cr .( /FLASH_SIZE not in environment ) abort [THEN] constant FLASH_SIZE
S" /FLASH_PAGE_SIZE" environment? 0= [IF]  cr .( /FLASH_PAGE_SIZE not in environment ) abort [THEN] constant FLASH_PAGE_SIZE

\ This chip can only erase 16 pages at a time
FLASH_PAGE_SIZE 16 * constant FLASH_BLOCK_SIZE
FLASH_BLOCK_SIZE buffer: flash_block

hex
41004000 constant NVMCTRL			\ Warning samd51j20a actually.

41004000 constant NVMCTRL_CTRLA

41004004 constant NVMCTRL_CTRLB
00000001 constant NVMCTRL_CTRLB_CMD_EB
00000015 constant NVMCTRL_CTRLB_CMD_PBC
0000A500 constant NVMCTRL_CTRLB_CMDEX_KEY

41004008 constant NVMCTRL_PARAM

41004010 constant NVMCTRL_INTFLAG
00000001 constant NVMCTRL_INTFLAG_DONE

41004012 constant NVMCTRL_STATUS
00000001 constant NVMCTRL_STATUS_READY

41004014 constant NVMCTRL_ADDR
decimal

: flash_read		( dest flash-address len -- errorflag )
  rot >r
  begin
    ?dup
  while
    over s>d d32@ 
	r@ !
	swap cell+ swap
	 r> cell+ >r
	1 cells -
  repeat
  r> drop
  drop
  0
;

: waitReady	
  begin
    NVMCTRL_STATUS s>d d32@ NVMCTRL_STATUS_READY and 
  until
;

: waitDone
  begin
    NVMCTRL_INTFLAG s>d d32@ NVMCTRL_INTFLAG_DONE and
  until
;

: clearDone
  NVMCTRL_INTFLAG s>d d32@ NVMCTRL_INTFLAG_DONE or NVMCTRL_INTFLAG s>d d32!
;

: setCommand		( cmd -- )
  NVMCTRL_CTRLB_CMDEX_KEY or
  NVMCTRL_CTRLB s>d d32!
;

: erase_block		( block-addr -- )
  NVMCTRL_ADDR s>d d32!
  waitReady
  clearDone
  NVMCTRL_CTRLB_CMD_EB setCommand
  waitDone
;

: flash_page		( source flash -- )
\ automatic page write
  NVMCTRL_CTRLA s>d d32@ 48 or NVMCTRL_CTRLA s>d d32!	
  waitReady
  clearDone
  NVMCTRL_CTRLB_CMD_PBC setCommand
  waitDone
  clearDone
  FLASH_PAGE_SIZE 4 / 0 do
    over @ over s>d d32!
    4 + swap 4 + swap
  loop
  2drop
  waitDone
;

: allset
  0 ?do 
   dup c@ 255 <> if drop false unloop exit then
   1+
  loop
  drop
  true
;

: write_page		( flash-address source len -- )	
  rot s>d FLASH_BLOCK_SIZE um/mod FLASH_BLOCK_SIZE * swap		

  flash_block 2 pick FLASH_BLOCK_SIZE flash_read drop

  ( source len block-addr block-offset -- )

  3 pick 3 pick flash_block 3 pick + over compare 0= if
    2drop 2drop
  else
	dup flash_block + 4 pick allset 0= if
		over erase_block
		( source len block-addr block-offset -- )
		swap >r flash_block + swap move r>
		( block-addr -- )
		flash_block swap FLASH_BLOCK_SIZE	\ need to write all 16 pages
	else
		( source len block-addr block-offset -- )
		+ swap
	then
	( source flash-addr len -- )
	0 ?do
		2dup flash_page
		FLASH_PAGE_SIZE + swap FLASH_PAGE_SIZE + swap
	FLASH_PAGE_SIZE +loop
	2drop
  then
;

: flash_write		( flash-address source len -- errorflag )
  begin
    dup FLASH_PAGE_SIZE min >r	( fa s l -- : R: todo -- )
    2 pick 2 pick r@
	write_page
	r@ - rot r@ + rot r> + rot	
	?dup 0=
  until
  2drop 0
;

only forth definitions

