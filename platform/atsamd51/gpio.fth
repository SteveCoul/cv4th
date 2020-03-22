
require platform/cortexm4/port.fth

ext-wordlist forth-wordlist internals 3 set-order 

internals set-current

: pinToMaskAndPort	( n -- mask port )
  dup 32 < if 1 swap lshift PORT_A else 32 - 1 swap lshift PORT_B then
;

: pinToIndexAndPort	( n -- index port )
  dup 32 < if PORT_A else 32 - PORT_B then
;

: makeOutput		( n -- )
  pinToMaskAndPort PORT_DIRSET s>d d32!
;

: makeInput			( n -- )
  pinToMaskAndPort PORT_DIRCLR s>d d32!
;

: setHigh			( n -- )
  pinToMaskAndPort PORT_OUTSET s>d d32!
;

: setLow			( n -- )
  pinToMaskAndPort PORT_OUTCLR s>d d32!
;

: get				( n -- )
  pinToMaskAndPort PORT_IN s>d d32@ and 0= 0=
;

: enableInput		( n -- )
  pinToIndexAndPort swap PORT_PINCFGn + s>d	( ad-addr -- )
  2dup d8@ 2 or rot rot d8!
;

: disableInput		( n -- )
  pinToIndexAndPort swap PORT_PINCFGn + s>d	( ad-addr -- )
  2dup d8@ 2 invert and rot rot d8!
;

: enablePull		( n -- )
  pinToIndexAndPort swap PORT_PINCFGn + s>d	( ad-addr -- )
  2dup d8@ 4 or rot rot d8!
;

: disablePull		( n -- )
  pinToIndexAndPort swap PORT_PINCFGn + s>d	( ad-addr -- )
  2dup d8@ 4 invert and rot rot d8!
;

: enableMux		( n -- )
  pinToIndexAndPort swap PORT_PINCFGn + s>d	( ad-addr -- )
  2dup d8@ 1 or rot rot d8!
;

: disableMux		( n -- )
  pinToIndexAndPort swap PORT_PINCFGn + s>d	( ad-addr -- )
  2dup d8@ 1 invert and rot rot d8!
;

: setMux			( n v -- )
  swap pinToIndexAndPort PORT_PMUXn		( v idx0..31 PORTMUXn -- )
  over 1 rshift +						( v idx0..31 PORTMUX -- )
  swap 1 and if ( v PORTMUX -- )
	\ odd
    dup s>d d8@ 15 and
	rot 15 and 4 lshift or
  else
	\ even
	dup s>d d8@ 240 and
    rot 15 and or
  then
  swap s>d d8!
;

ext-wordlist set-current

\ Arduino Names

PA13 constant PIN_D0
PA13 constant PIN_RX
PA12 constant PIN_D1
PA12 constant PIN_TX
 PA6 constant PIN_D4
PA15 constant PIN_D5
PA20 constant PIN_D6
 PA7 constant PIN_D9
PA18 constant PIN_D10
PA16 constant PIN_D11
PA19 constant PIN_D12
PA17 constant PIN_D13
 PA2 constant PIN_A0
 PB8 constant PIN_A1
 PB9 constant PIN_A2
 PA4 constant PIN_A3
 PA5 constant PIN_A4
 PB2 constant PIN_A5
PA22 constant PIN_SDA
PA23 constant PIN_SCL
PB11 constant PIN_MISO
PB12 constant PIN_MOSI
PB13 constant PIN_SCK

PIN_D13 constant LED_BUILTIN

 \ These defines match the digital arduino driver
 0 constant INPUT
 1 constant OUTPUT
 2 constant INPUT_PULLUP
 3 constant INPUT_PULLDOWN

 1 constant HIGH
 0 constant LOW

: pinMode		( pin mode -- )
  swap >r
  case
	OUTPUT of r@ makeOutput r@ enableInput endof
	INPUT  of R@ makeInput r@ disablePull endof
	INPUT_PULLUP of r@ makeInput r@ enablePull r@ setHigh endof
	INPUT_PULLDOWN of r@ makeInput r@ enablePull r@ setLow endof
  endcase
  r> drop
;

: writeDigital	( pin level -- )
  \ TODO if pin is an output writing HIGH enables pullup, writing LOW disables pullup
  case
	HIGH of swap setHigh endof
	LOW of swap setLow endof
    swap drop
  endcase
;

: readDigital	( pin -- )
  get
;

only forth definitions


