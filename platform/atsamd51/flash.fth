
require platform/atsamd51/nvmctrl.fth

ext-wordlist forth-wordlist 2 set-order

ext-wordlist set-current

1 cells 4 = 0= [IF] cr .( Driver assumes 32bit build ) abort [THEN]
S" /FLASH_BASE" environment? 0= [IF]  cr .( /FLASH_BASE not in environment ) abort [THEN] constant FLASH_BASE
S" /FLASH_SIZE" environment? 0= [IF]  cr .( /FLASH_SIZE not in environment ) abort [THEN] constant FLASH_SIZE
S" /FLASH_PAGE_SIZE" environment? 0= [IF]  cr .( /FLASH_PAGE_SIZE not in environment ) abort [THEN] constant FLASH_PAGE_SIZE

private-namespace

\ This chip can only erase 16 pages at a time
FLASH_PAGE_SIZE 16 * constant FLASH_BLOCK_SIZE
FLASH_BLOCK_SIZE buffer: flash_block

ext-wordlist set-current

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

private-namespace

: waitReady	begin NVMCTRL.STATUS.ready@ until ;

: waitDone begin NVMCTRL.INTFLAG.done@ until ;

: clearDone 0 NVMCTRL.INTFLAG.done!  ;

: setCommand		( cmd -- ) NVMCTRL_CTRLB_CMDEX_KEY or NVMCTRL.CTRLB.reg!  ;

: erase_block		( block-addr -- )
  NVMCTRL.ADDR.addr!
  waitReady
  clearDone
  NVMCTRL_CTRLB_CMD_EB setCommand
  waitDone
;

: flash_page		( source flash -- )
  3 NVMCTRL.CTRLA.wmode!	\ automatic page write
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

ext-wordlist set-current

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

