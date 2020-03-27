
ext-wordlist forth-wordlist 2 set-order

private-namespace

: wait 1000 0 do i drop loop ;

onboot: startup
	PIN_D13 OUTPUT pinMode
	begin	
		PIN_D13 LOW writeDigital
		wait
		PIN_D13 HIGH writeDigital
		wait
	again
onboot;

