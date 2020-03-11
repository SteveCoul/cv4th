
ext-wordlist forth-wordlist internals 3 set-order 
definitions

(				Arduino
  Pin	Port	Default		Interrupt	Sercom		SercomAlt	
	0	PA13	RX			13			S2:P1		S4:P0
	1	PA12	TX			12			S2:P0		S4:P1
	4	PA06	GPIO		6						S0:P2
	5	PA15	GPIO		15			S5:P3		S0:P3
	6	PA20	GPIO		4			S5:P2		S3:P2
	9	PA07	GPIO		7						S0:P3
   10	PA18	GPIO		2			S1:P2		S3:P2
   11	PA16	GPIO		0			S1:P0		S3:P1
   12	PA19	GPIO		3			S1:P3		S3:P3
   13	PA17	GPIO		1			S1:P1		S3:P0
   A0	PA02	ADC/DAC		2			
   A1	PB08	ADC			8						S4:P0
   A2	PB09	ADC			9						S4:P1
   A3	PA04	ADC			4						S0:P0
   A4	PA05	ADC			5						S0:P1
   A5	PB02	ADC			2						S5:P0
   20	PA22	SDA			6			S3:P0		S5:P1
   21	PA23	SCL			7			S3:P1		S5:P0
   22	PB11	MISO		11						S4:P3
   23	PB12	MOSI		12			S4:P0
   24	PB13	SCK			13			S4:P1
		PA30	SWDCLK		14			S7:P2		S1:P2
		PA31	SWDIO		15			S7:P3		S1:P3 )

hex
41008000 	constant  	PORT
PORT 00 + 	constant	PORTA
PORT 80 + 	constant	PORTB

: offset create , does> @ + ;

00 	offset	DIR
04 	offset	DIRCLR
08 	offset	DIRSET
0C 	offset	DIRTGL
10 	offset	OUT
14 	offset	OUTCLR
18 	offset	OUTSET
1C 	offset	OUTTGL
20 	offset	IN
24 	offset	CTRL
28 	offset	WRCONFIG
2C 	offset	EVCTRL
30 	offset	PMUXn
( .. 16 of these )
40 	offset	PINCFGn
( .. 32 of these )
decimal

: pinToMaskAndPort	( n -- mask port )
  dup 32 < if 1 swap lshift PORTA else 32 - 1 swap lshift PORTB then
;

: makeOutput		( n -- )
  pinToMaskAndPort DIRSET s>d d32!
;

: makeInput			( n -- )
  pinToMaskAndPort DIRCLR s>d d32!
;

: setHigh			( n -- )
  pinToMaskAndPort OUTSET s>d d32!
;

: setLow			( n -- )
  pinToMaskAndPort OUTCLR s>d d32!
;

: get				( n -- )
  pinToMaskAndPort IN s>d d32@ and 0= 0=
;
ext-wordlist set-current

\ SAMD PIN Names

 2 constant PA2
 4 constant PA4
 5 constant PA5
 6 constant PA6
 7 constant PA7
12 constant PA12
13 constant PA13
15 constant PA15
16 constant PA16
17 constant PA17
18 constant PA18
19 constant PA19
20 constant PA20
22 constant PA22
23 constant PA23
34 constant PB2
40 constant PB8
41 constant PB9
43 constant PB11
44 constant PB12
45 constant PB13

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

 1 constant OUTPUT
 2 constant INPUT

 1 constant HIGH
 0 constant LOW

: pinMode		( pin mode -- )
  case
	OUTPUT of swap makeOutput endof
	INPUT  of swap makeInput endof
    swap drop
  endcase
;

: writeDigital	( pin level -- )
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


