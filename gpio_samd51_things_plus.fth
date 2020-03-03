
get-order internals swap 1+ set-order

: offset create , does> @ + ;

hex
41008000 constant PORT

00 offset PORTA
80 offset PORTB

00 offset DIR
04 offset DIRCLR
08 offset DIRSET
0C offset DIRTGL
10 offset OUT
14 offset OUTCLR
18 offset OUTSET
1C offset OUTTGL
20 offset IN
24 offset CTRL
28 offset WRCONFIG
2C offset EVCTRL
30 offset PMUX0
31 offset PMUX1
32 offset PMUX2
33 offset PMUX3
34 offset PMUX4
35 offset PMUX5
36 offset PMUX6
37 offset PMUX7
38 offset PMUX8
39 offset PMUX9
3A offset PMUXA
3B offset PMUXB
3C offset PMUXC
3D offset PMUXD
3E offset PMUXE
3F offset PMUXF
40 offset PINCFG
decimal


17 constant GPIO_D13
19 constant GPIO_D12
16 constant GPIO_D11
 7 constant GPIO_D9
20 constant GPIO_D6
15 constant GPIO_D5
 6 constant GPIO_D4
12 constant GPIO_D1
13 constant GPIO_D0

22 constant GPIO_D20_SDA
23 constant GPIO_D21_SCL

43 constant GPIO_D22_MISO
44 constant GPIO_D23_MOSI
45 constant GPIO_D24_SCK

34 constant GPIO_A5
 5 constant GPIO_A4
 4 constant GPIO_A3
41 constant GPIO_A2
40 constant GPIO_A1
 2 constant GPIO_A0

GPIO_D13 constant LED_BUILTIN

1 constant PIN_MODE_INPUT
2 constant PIN_MODE_INPUT_PULLUP
4 constant PIN_MODE_OUTPUT

: pinMode		\ mode pin --
  dup 0 64 within if
	dup 32 < if PORT PORTA else swap 32 - swap PORT PORTB then
	\ mode pin registers --
    swap 1 swap lshift swap
	\ mode registers mask --
    rot case				\ registers mask mode --
	PIN_MODE_INPUT 			of	swap rot DIRCLR s>d d32!	endof
	PIN_MODE_INPUT_PULLUP  	of  swap rot DIRCLR s>d d32!	endof	\ fixme
	PIN_MODE_OUTPUT			of 	swap rot DIRSET s>d d32!	endof
	nip nip
	endcase
  else
    2drop
  then
;

: writeDigital	\ flag pin --
  dup 0 64 within if
	dup 32 < if PORT PORTA else 32 - PORT PORTB then
	\ flag pin registers --
	swap 1 swap lshift		\ flag registers mask --
	swap
	rot if
		OUTSET
	else
		OUTCLR
	then
	s>d d32!
  else
    2drop
  then
;

