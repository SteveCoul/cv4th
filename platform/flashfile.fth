
ext-wordlist forth-wordlist internals 3 set-order definitions

1 cells 4 = 0= [IF] cr .( Driver assumes 32bit build ) abort [THEN]
S" /FLASH_BASE" environment? 0= [IF]  cr .( /FLASH_BASE not in environment ) abort [THEN] constant FLASH_BASE
S" /FLASH_SIZE" environment? 0= [IF]  cr .( /FLASH_SIZE not in environment ) abort [THEN] constant FLASH_SIZE

variable flash_fd

: flash_read		( dest flash-address len -- errorflag )
  swap s>d flash_fd @ reposition-file if
	2drop 1
  else
	flash_fd @ read-file nip 
  then
;

: flash_write		( flash-address source len -- errorflag )
  rot s>d flash_fd @ reposition-file if
	2drop 1
  else
	flash_fd @ write-file 
  then
;

onboot: flashfileinit
	S" flashfile" r/w bin open-file 0= if 
		flash_fd !
	else
		drop
		S" flashfile" 0 create-file 0= if
			flash_fd !
		else
			drop
			-1 flash_fd !
			cr ." Failed to open/create flashfile"
		then
	then

	flash_fd @ 0> if
		flash_fd @ file-size 2drop FLASH_SIZE < if
			cr ." Resizing flashfile storage"
			here 16 255 fill
			flash_size 0 ?do
				here 16 flash_fd @ write-file drop
			16 +loop
        then	
    then
onboot;

