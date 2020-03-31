
require kernel/locals.fth
require platform/cortexm4/gclk.fth

internals ext-wordlist forth-wordlist 3 set-order 

internals set-current

4 constant EIC_GCLK_ID

SENSE_RISE constant RISING

: noop ;

: detachInterrupt	( pin -- )
  digitalPinToInterrupt 
  dup eicDisableInterrupt
  case
   0 of ['] EXTINT0  swap endof
   1 of ['] EXTINT1  swap endof
   2 of ['] EXTINT2  swap endof
   3 of ['] EXTINT3  swap endof
   4 of ['] EXTINT4  swap endof
   5 of ['] EXTINT5  swap endof
   6 of ['] EXTINT6  swap endof
   7 of ['] EXTINT7  swap endof
   8 of ['] EXTINT8  swap endof
   9 of ['] EXTINT9  swap endof
  10 of ['] EXTINT10 swap endof
  11 of ['] EXTINT11 swap endof
  12 of ['] EXTINT12 swap endof
  13 of ['] EXTINT13 swap endof
  14 of ['] EXTINT14 swap endof
  15 of ['] EXTINT15 swap endof
  endcase
  ['] noop swap defer!
;

: attachInterrupt	{: pin xt mode | int -- :}
  pin 0 setMux ( peripheral A is EIC )
  pin enableMux
  eicDisable
  pin digitalPinToInterrupt dup 0< abort" not an interrupt pin" to int
  int mode eicConfig
  int eicEnableInterrupt
  eicEnable
  int case
   0 of ['] EXTINT0  swap endof
   1 of ['] EXTINT1  swap endof
   2 of ['] EXTINT2  swap endof
   3 of ['] EXTINT3  swap endof
   4 of ['] EXTINT4  swap endof
   5 of ['] EXTINT5  swap endof
   6 of ['] EXTINT6  swap endof
   7 of ['] EXTINT7  swap endof
   8 of ['] EXTINT8  swap endof
   9 of ['] EXTINT9  swap endof
  10 of ['] EXTINT10 swap endof
  11 of ['] EXTINT11 swap endof
  12 of ['] EXTINT12 swap endof
  13 of ['] EXTINT13 swap endof
  14 of ['] EXTINT14 swap endof
  15 of ['] EXTINT15 swap endof
  endcase
  xt swap defer!
;

onboot: interrupts

	16 0 do 
		EIC_0_IRQn i + 
		dup nvicDisableIRQ
		dup nvicClearPending
			nvicEnableIRQ
	loop

	\ enable clock for EIC
	2 EIC_GCLK_ID GCLK.PCHCTRLn.gen!
	1 EIC_GCLK_ID GCLK.PCHCTRLn.chen!

	eicEnable

onboot;
