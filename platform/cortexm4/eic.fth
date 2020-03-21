
( Definitions for EIC - External Interrupt Controller )

require kernel/structure.fth

internals ext-wordlist forth-wordlist 3 set-order

internals set-current

hex

40002800 	constant  	EIC

begin-structure _EIC
	1 +field	CTRLA
	1 +field	NMICTR
	2 +field	NMIFLAG
    4 +field	SYNCBUSY
	4 +field	EVCTRL
	4 +field	ITENCLR
	4 +field	ITENSET
	4 +field	INTFLAG
	4 +field	ASYNCH
	4 +field	CONFIG0
	4 +field	CONFIG1
	12 +field	reserved
	4 +field	DEBOUNCEN
	4 +field	DPRESCALER
	4 +field	PINSTATE
end-structure

decimal

: eicWait
  begin EIC SYNCBUSY s>d d32@ 2 and 0= until
;

: eicEnable 
  EIC CTRLA s>d 2dup d8@ 2 or rot rot d8!
  eicWait
;

: eicDisableInterrupt
  1 swap lshift EIC ITENCLR s>d d32!
;

: eicEnableInterrupt
  1 swap lshift EIC ITENSET s>d d32!
;

\ I currently have no use for the ITENCLR because my isrs all do that in native

: eicConfigAllForRisingEdge \ I havne't figure out all this yet
  153 EIC CONFIG0 s>d d32!
  153 EIC CONFIG1 s>d d32!
;

