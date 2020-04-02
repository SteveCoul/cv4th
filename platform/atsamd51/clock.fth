
require platform/cortexm4/osc32k.fth
require platform/cortexm4/rtc.fth

forth-wordlist ext-wordlist 2 set-order 

ext-wordlist set-current

\ FIXME - Need to configure/enable external oscillator before I can use it
onboot: clock 
  1 OSC32KCTRL.RTCCTRL.rtcsel!		( 0= 1.024Khz int, 1= 32.768Khz int, 4= 1.024Khz extosc, 5= 32.768Khz extosc )
  1 RTCmode0.CTRLA.swrst!
  begin RTCmode0.SYNCBUSY.swrst@ 0= until
  1 RTCmode0.CTRLA.countsync!
  1 RTCmode0.CTRLA.enable!
  begin RTCmode0.SYNCBUSY.enable@ 0= until
onboot;

: rtc@
  RTCmode0.COUNT.reg@
;

32768 constant rtcTicksPerSecond

: benchmark
  parse-name $find if
	rtc@ swap execute rtc@ swap -
	s>d rtcTicksPerSecond sm/rem
	cr cr . [char] . emit
	100 * rtcTicksPerSecond / . ."  seconds"
  then
;

get-order internals swap 1+ set-order
forth-wordlist set-current

: ms			( ms -- )
  rtcTicksPerSecond * 1000 / 
  rtc@ + begin at-idle dup rtc@ < until drop	 ( not schedule because we may not have thread.fth )
;

only forth definitions

