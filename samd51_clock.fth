
ext-wordlist forth-wordlist internals 3 set-order 
definitions

hex 
40001400 		constant OSC32KCTRL   
OSC32KCTRL 10 + constant OSC32KCTRL_RTCCTRL
00				constant OSC32KCTRL_RTCCTRL_ULP1K
01				constant OSC32KCTRL_RTCCTRL_ULP32K
04				constant OSC32KCTRL_RTCCTRL_XOSC1K
05				constant OSC32KCTRL_RTCCTRL_XOSC32K

40002400 constant RTC
RTC 00 + constant RTC_CTRLA
0002	 constant RTC_CTRLA_ENABLE_MASK
0002	 constant RTC_CTRLA_ENABLE
0F00	 constant RTC_CTRLA_PRESCALER_MASK
0000	 constant RTC_CTRLA_PRESCALER_OFF
0100	 constant RTC_CTRLA_PRESCALER_1
0200	 constant RTC_CTRLA_PRESCALER_2
( ... etc ... up to B which is 1024 )
0B00	 constant RTC_CTRLA_PRESCALER_1024
00C0	 constant RTC_CTRLA_MODE_MASK
0000	 constant RTC_CTRLA_MODE_COUNT32
0040	 constant RTC_CTRLA_MODE_COUNT16
0080   	 constant RTC_CTRLA_MODE_CLOCK
8000	 constant RTC_CTRLA_COUNT_SYNC_MASK
8000	 constant RTC_CTRLA_COUNT_SYNC
( 00C0 reserved )
RTC 18 + constant RTC_COUNT
decimal

onboot: rtcinit
  cr ." Init RTC"
  OSC32KCTRL_RTCCTRL_XOSC32K OSC32KCTRL_RTCCTRL s>d d8!
  RTC_CTRLA s>d d16@
  	RTC_CTRLA_ENABLE_MASK 
	RTC_CTRLA_PRESCALER_MASK and 
	RTC_CTRLA_MODE_MASK and 
	RTC_CTRLA_COUNT_SYNC_MASK and
  invert and
    RTC_CTRLA_ENABLE or
    RTC_CTRLA_PRESCALER_1 or
    RTC_CTRLA_MODE_COUNT32 or
    RTC_CTRLA_COUNT_SYNC or
  RTC_CTRLA s>d d16!
onboot;

: rtc@
  RTC_COUNT s>d d32@
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

forth-wordlist set-current

: ms			( ms -- )
  rtcTicksPerSecond * 1000 / 
  rtc@ + begin dup rtc@ < until drop
;

only forth definitions

