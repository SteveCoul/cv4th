
ext-wordlist forth-wordlist 2 set-order
ext-wordlist set-current

 0 constant INPUT
 1 constant OUTPUT
 2 constant INPUT_PULLUP

 1 constant HIGH
 0 constant LOW

: pinMode		( pin mode -- )
  swap
  s>d <# #s S" digital:/" holds #> r/w bin open-file if
	2drop
  else
	\ the INPUT/OUTPUT/INPUT_PULLUP constants match the seek offsets to configure
	( mode fd -- )
	swap s>d 2 pick reposition-file if
		\ error
	then
	close-file drop
  then
;

: writeDigital	( pin level -- )
  LOW = if 0 here c! else 1 here c! then
  s>d <# #s S" digital:/" holds #> r/w bin open-file if
	drop
  else
	here 1 2 pick write-file if
		\ error
	then
	close-file drop
  then
;

: readDigital	( pin -- value )
  s>d <# #s S" digital:/" holds #> r/w bin open-file if
	drop 0
  else
	here 1 2 pick read-file if
		drop -1
	else
		drop here c@
	then
	swap close-file drop
  then
;

only forth definitions


