
( Definitions for EIC - External Interrupt Controller )

require kernel/structure.fth
require platform/atsamd51/mclk.fth

ext-wordlist forth-wordlist 2 set-order

ext-wordlist set-current

hex

40002800 	constant  	EIC

begin-structure _EIC
	1 +field	CTRLA		\ 00
	1 +field	NMICTR		\ 01
	2 +field	NMIFLAG		\ 02
    4 +field	SYNCBUSY	\ 04
	4 +field	EVCTRL		\ 08
	4 +field	ITENCLR		\ 0C
	4 +field	ITENSET		\ 10
	4 +field	INTFLAG		\ 14
	4 +field	ASYNCH		\ 18
	4 +field	CONFIG0		\ 1C
	4 +field	CONFIG1		\ 20
	12 +field	reserved	\ 24
	4 +field	DEBOUNCEN	\ 30
	4 +field	DPRESCALER	\ 34
	4 +field	PINSTATE	\ 38
end-structure

decimal

0 constant SENSE_NONE
1 constant SENSE_RISE
2 constant SENSE_FALL
3 constant SENSE_BOTH
4 constant SENSE_HIGH
5 constant SENSE_LOW

: eicWait
  begin EIC SYNCBUSY s>d d32@ 2 and 0= until
;

: eicEnable 
  1 MCLK.APBAMASK.eic!

  EIC CTRLA s>d 2dup d8@ 2 or rot rot d8!
  eicWait
;

: eicDisable 
  EIC CTRLA s>d 2dup d8@ 2 invert and rot rot d8!
  eicWait
;

: eicDisableInterrupt
  1 swap lshift EIC ITENCLR s>d d32!
;

: eicEnableInterrupt
  1 swap lshift EIC ITENSET s>d d32!
;

\ I currently have no use for the ITENCLR because my isrs all do that in native

: andMASK			( idx -- idx mask )
  7 over 4 * lshift invert ;

: eicConfig			( index sense -- )
  swap dup 8 < if EIC CONFIG0 else 8 - EIC CONFIG1 then	( sense idx CONFIG -- )
  rot 7 and 	( idx CONFIG sense -- )
  rot andMASK	( config sense idx and-mask -- )
  >r 4 * lshift ( config ormask -- : R: and-mask )
  over s>d d32@ r> and or swap s>d d32!
;
 
: .config		( field idx -- )
  cr ."  config EXTINT " .
  cr ."    filten " dup 8 and if [char] Y else [char] n then emit
  ." , sense "
  7 and
  case
  0 of ." None" endof
  1 of ." Rising" endof
  2 of ." Falling" endof
  3 of ." Edge" endof
  4 of ." High" endof
  5 of ." Low" endof
  6 of ." reserved" endof
  7 of ." reserved" endof
  endcase
;

: .eic
  cr ." EIC"
  EIC CTRLA s>d d8@
  cr ."   clock " dup 16 and if ." CLK_ULP32K" else ." GCLK_EIC" then
  cr ."   enable " if [char] Y else [char] n then emit
  cr ."   Interrupt flags 0..15 " EIC INTFLAG s>d d32@ 16 0 do dup 1 and . 1 rshift loop drop
  EIC CONFIG0 s>d d32@ 
  dup 15 and 0 .config 4 rshift
  dup 15 and 1 .config 4 rshift
  dup 15 and 2 .config 4 rshift
  dup 15 and 3 .config 4 rshift
  dup 15 and 4 .config 4 rshift
  dup 15 and 5 .config 4 rshift
  dup 15 and 6 .config 4 rshift
      15 and 7 .config 4 rshift
  EIC CONFIG1 s>d d32@
  dup 15 and 8 .config 4 rshift
  dup 15 and 9 .config 4 rshift
  dup 15 and 10 .config 4 rshift
  dup 15 and 11 .config 4 rshift
  dup 15 and 12 .config 4 rshift
  dup 15 and 13 .config 4 rshift
  dup 15 and 14 .config 4 rshift
      15 and 15 .config 4 rshift
;

