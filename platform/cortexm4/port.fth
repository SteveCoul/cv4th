
( Definitions for PORT - I/O Pin Controller )

require kernel/structure.fth

internals ext-wordlist forth-wordlist 3 set-order

internals set-current

hex

41008000 	constant  	PORT
PORT 00 + 	constant	PORT_A
PORT 80 + 	constant	PORT_B

: PORT_DIR		00 + ;
: PORT_DIRCLR	04 + ;
: PORT_DIRSET	08 + ;
: PORT_DIRTGL	0C + ;
: PORT_OUT		10 + ;
: PORT_OUTCLR	14 + ;
: PORT_OUTSET	18 + ;
: PORT_OUTTGL	1C + ;
: PORT_IN		20 + ;
: PORT_CTRL		24 + ;
: PORT_WRCONFIG	28 + ;
: PORT_EVCTRL	2C + ;
: PORT_PMUXn	30 + ;
: PORT_PINCFGn	40 + ;

decimal

 0 constant PA0 	 1 constant PA1 	 2 constant PA2 	 3 constant PA3
 4 constant PA4 	 5 constant PA5 	 6 constant PA6 	 7 constant PA7 	 
 8 constant PA8 	 9 constant PA9 	10 constant PA10 	11 constant PA11 	
12 constant PA12 	13 constant PA13 	14 constant PA14 	15 constant PA15 	
16 constant PA16 	17 constant PA17 	18 constant PA18 	19 constant PA19 	
20 constant PA20 	21 constant PA21 	22 constant PA22 	23 constant PA23 	
24 constant PA24 	25 constant PA25 	26 constant PA26 	27 constant PA27 	
28 constant PA28 	39 constant PA29 	30 constant PA30 	31 constant PA31
32 constant PB0 	33 constant PB1 	34 constant PB2 	35 constant PB3
36 constant PB4 	37 constant PB5 	38 constant PB6 	39 constant PB7
40 constant PB8 	41 constant PB9 	42 constant PB10 	43 constant PB11
44 constant PB12 	45 constant PB13 	46 constant PB14 	47 constant PB15
48 constant PB16 	49 constant PB17 	50 constant PB18 	51 constant PB19
52 constant PB20 	53 constant PB21 	54 constant PB22 	55 constant PB23
56 constant PB24 	57 constant PB25 	58 constant PB26 	59 constant PB27
60 constant PB28 	61 constant PB2 	62 constant PB30 	63 constant PB31

: >port			( n -- n' port )
  dup 32 < if PORT_A else 32 - PORT_B then ;

: .dir			( n -- )
  >port PORT_DIR s>d d32@ 1 rot lshift and if [char] O else [char] I then space space emit ;

: .out			( n -- )
  >port PORT_OUT s>d d32@ 1 rot lshift and if [char] H else [char] L then space space emit ;

: .in			( n -- )
  >port PORT_IN s>d d32@ 1 rot lshift and if [char] H else [char] L then space emit ;

: .pmux			( n -- )
  >port PORT_PMUXn						
  over 1 rshift + s>d d8@
  swap 1 and if 4 rshift then 15 and
  4 .r ;

: .pmuxen		( n -- )
  >port PORT_PINCFGn + s>d d8@ 1 and if [char] Y else [char] n then 5 spaces emit ;

: .inen			( n -- )
  >port PORT_PINCFGn + s>d d8@ 2 and if [char] Y else [char] n then 3 spaces emit ;

: .drv			( n -- )
  >port PORT_PINCFGn + s>d d8@ 64 and if ." strong" else ." normal" then ;

: .port			( n -- )
  cr 
  dup 2 .r [char] : emit space
  dup .dir space
  dup .out space
  dup .in space
  dup .pmux space
  dup .pmuxen space
  dup .inen space
  dup .drv space
  drop
;

: .banner cr ."     DIR OUT IN PMUX PMUXen INen DrvStr " ;

: .portA .banner 32 0 do i .port loop ;
: .portB .banner 32 0 do i 32 + .port loop ;

ext-wordlist set-current

