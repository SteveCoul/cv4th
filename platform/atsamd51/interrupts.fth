
require kernel/locals.fth

internals ext-wordlist forth-wordlist 3 set-order 

internals set-current

SENSE_RISE constant RISING

: attachInterrupt	{: pin xt mode | int -- :}
  pin 0 setMux ( peripheral A is EIC )
  pin enableMux
  eicDisable
  pin digitalPinToInterrupt dup 0< abort" not an interrupt pin" to int
  int mode eicConfig
  int eicEnableInterrupt
  eicEnable
  cr ." For now I'm not using xt just running the vector"
;

onboot: interrupts

	16 0 do 
		EIC_0_IRQn i + 
		dup nvicDisableIRQ
		dup nvicClearPending
			nvicEnableIRQ
	loop
	eic-gclk
	eicEnable

onboot;
