
ext-wordlist forth-wordlist internals 3 set-order 
\ definitions

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
PORTA 00 +	constant	PORTA_DIR
PORTA 04 +	constant	PORTA_DIRCLR
PORTA 08 +	constant	PORTA_DIRSET
PORTA 0C +	constant	PORTA_DIRTGL
PORTA 10 +	constant	PORTA_OUT
PORTA 14 +	constant	PORTA_OUTCLR
PORTA 18 +	constant	PORTA_OUTSET
PORTA 1C +	constant	PORTA_OUTTGL
PORTA 20 +	constant	PORTA_IN
PORTA 24 +	constant	PORTA_CTRL
PORTA 28 +	constant	PORTA_WRCONFIG
PORTA 2C +	constant	PORTA_EVCTRL
PORTA 30 +	constant	PORTA_PMUXn
( .. 16 of these )
PORTA 40 +	constant	PORTA_PINCFGn
( .. 32 of these )
PORT 80 +	constant	PORTB
PORTB 00 +	constant	PORTB_DIR
PORTB 04 +	constant	PORTB_DIRCLR
PORTB 08 +	constant	PORTB_DIRSET
PORTB 0C +	constant	PORTB_DIRTGL
PORTB 10 +	constant	PORTB_OUT
PORTB 14 +	constant	PORTB_OUTCLR
PORTB 18 +	constant	PORTB_OUTSET
PORTB 1C +	constant	PORTB_OUTTGL
PORTB 20 +	constant	PORTB_IN
PORTB 24 +	constant	PORTB_CTRL
PORTB 28 +	constant	PORTB_WRCONFIG
PORTB 2C +	constant	PORTB_EVCTRL
PORTB 30 +	constant	PORTB_PMUXn
( .. 16 of these )
PORTB 40 +	constant	PORTB_PINCFGn
( .. 32 of these )
decimal

ext-wordlist set-current

only forth definitions

