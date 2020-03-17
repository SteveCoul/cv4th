
ext-wordlist forth-wordlist internals 3 set-order definitions             

-1 value wire_fd
0 variable wire_tmp

(
 	lseek is used to configure/send commands
	Seek 0..7F will set i2c address
	seek 80 means 'dont send end after Tx/Rx'
	Seek 81 means 'send end after Tx/Rx'
    Seek 82 means 'begin transmission'
	Seek 83 means 'endTransmission'
	
	write is used to send data bytes between begin/end transmission the ior in this case
	is num bytes written 
	
	read +ve amount performs a requestFrom for the given amount +ve

	read -ve read and return 1 byte as ior

	fileSize returns availble Rx bytes
)

ext-wordlist set-current

: Wire.delay				( n -- )
  drop
;

: Wire.reset				( -- )
;

: Wire.begin				(  -- )
  wire_fd 0 < if
  	S" wire:/" r/w open-file abort" failed to open wire:/" to wire_fd
  then
;

: Wire.beginTransmission	( i2c-address -- )
  0 wire_fd reposition-file drop
  130 0 wire_fd reposition-file drop
;

: Wire.write				( u -- 0|1 )
  wire_tmp c!
  wire_tmp 1 wire_fd write-file 
;

: Wire.endTransmission		( flag -- )
  if 129 else 128 then 0 wire_fd reposition-file drop
  131 0 wire_fd reposition-file drop
;

: Wire.requestFrom			( i2c-address count doend? -- num )
  if 129 else 128 then 0 wire_fd reposition-file drop
  swap
  0 wire_fd reposition-file drop
  0 swap wire_fd read-file abort" failed i2c read"
;
 
: Wire.read					( -- u )
  wire_tmp 0 wire_fd read-file 2drop wire_tmp c@
;

: Wire.available			( -- n )
  wire_fd file-size 2drop
;

onboot: setwire -1 to wire_fd onboot;

only forth definitions

