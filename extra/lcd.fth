
ext-wordlist forth-wordlist 2 set-order definitions

60 constant LCD_I2C

128 constant width
64 constant height

width height * 8 / buffer: display_memory

: lcd_init
  S" I2C_SDA_PIN" environment? drop
  S" I2C_SCL_PIN" environment? drop
  Wire.begin
  Wire.reset

  display_memory width height * 8 / 255 fill
;

: sendcommand
  LCD_I2C Wire.BeginTransmission 0= abort" failed to send command"
  0 Wire.sendByte 0= abort" failed"
  Wire.sendByte 0= abort" failed"
  true Wire.endTransmission
;

hex
20 constant _MEMORYMODE

AE constant _DISPLAYOFF
A8 constant _SETMULTIPLEX
40 constant _SETSTARTLINE
8D constant _CHARGEPUMP
A0 constant _SEGREMAP
C8 constant _COMSCANDEC
81 constant _SETCONTRAST
A4 constant _DISPLAYALLON_RESUME
A6 constant _NORMALDISPLAY
2E constant _DEACTIVATE_SCROLL
AF constant _DISPLAYON


D3 constant _SETDISPLAYOFFSET
D5 constant _SETDISPLAYCLOCKDIV
D9 constant _SETPRECHARGE
DA constant _SETCOMPINS
DB constant _SETVCOMDETECT
decimal

: init
  _DISPLAYOFF sendcommand
  _SETDISPLAYCLOCKDIV sendcommand 128 sendcommand
  _SETMULTIPLEX sendcommand height 1- sendcommand
  _CHARGEPUMP sendcommand 20 sendCommand		\ internal vcc

  _SETDISPLAYOFFSET sendcommand 0 sendcommand
  _SETSTARTLINE sendcommand
  _MEMORYMODE sendcommand 0 sendcommand			\ 0 = horiz addr mode, 1 = vertical, 2 =  page addressing
  _SEGREMAP 1 or sendcommand
  _COMSCANDEC sendcommand
  _SETCOMPINS sendcommand 18 sendcommand
  _SETCONTRAST sendcommand 207 sendcommand
  _SETPRECHARGE sendcommand 241 sendcommand
  _SETVCOMDETECT sendcommand 64 sendcommand
  _DISPLAYALLON_RESUME sendcommand
  _NORMALDISPLAY sendcommand
  _DEACTIVATE_SCROLL sendcommand
  _DISPLAYON sendcommand
;

22 constant _PAGEADDR

: display
  0 sendcommand
  127 sendcommand
  _PAGEADDR sendcommand 0 sendcommand height 8 / 1 - sendcommand	\ we're going to send page0..7 (IE all)

  display_memory
  width height * 8 / 0 do
    LCD_I2C Wire.beginTransmission drop	   
	64 wire.sendbyte drop
	16 0 do
	 dup c@ wire.sendbyte drop 1+	
    loop
	true Wire.endTransmission
  16 +loop
  drop
;

: clear display_memory 1024 0 fill display ;

: setpixel		( x y -- )
  dup 8 / 128 *			( x y row-offset -- )
  rot +					( y offset -- )
  swap 7 and 1 swap lshift	( offset mask -- )
  swap display_memory +		( mask address -- )
  dup c@ rot or swap c!	
;

: .bits
  8 0 do
    dup 1 and if [char] * emit else space then
	1 rshift
  loop
  drop
;

: ddump
  display_memory
  64 0 ?do
	cr 16 0 ?do
	  dup c@ .bits 1+
	loop
  loop
  drop
;

