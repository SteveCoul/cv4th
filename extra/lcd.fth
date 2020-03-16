
ext-wordlist forth-wordlist 2 set-order definitions

60 constant LCD_I2C

128 constant width
64 constant height

here 
hex
00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 00 c, F8 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 33 c, 30 c, 00 c, 00 c, 00 c, 
00 c, 10 c, 0C c, 06 c, 10 c, 0C c, 06 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
40 c, C0 c, 78 c, 40 c, C0 c, 78 c, 40 c, 00 c, 04 c, 3F c, 04 c, 04 c, 3F c, 04 c, 04 c, 00 c, 
00 c, 70 c, 88 c, FC c, 08 c, 30 c, 00 c, 00 c, 00 c, 18 c, 20 c, FF c, 21 c, 1E c, 00 c, 00 c, 
F0 c, 08 c, F0 c, 00 c, E0 c, 18 c, 00 c, 00 c, 00 c, 21 c, 1C c, 03 c, 1E c, 21 c, 1E c, 00 c, 
00 c, F0 c, 08 c, 88 c, 70 c, 00 c, 00 c, 00 c, 1E c, 21 c, 23 c, 24 c, 19 c, 27 c, 21 c, 10 c, 
10 c, 16 c, 0E c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 00 c, E0 c, 18 c, 04 c, 02 c, 00 c, 00 c, 00 c, 00 c, 07 c, 18 c, 20 c, 40 c, 00 c, 
00 c, 02 c, 04 c, 18 c, E0 c, 00 c, 00 c, 00 c, 00 c, 40 c, 20 c, 18 c, 07 c, 00 c, 00 c, 00 c, 
40 c, 40 c, 80 c, F0 c, 80 c, 40 c, 40 c, 00 c, 02 c, 02 c, 01 c, 0F c, 01 c, 02 c, 02 c, 00 c, 
00 c, 00 c, 00 c, F0 c, 00 c, 00 c, 00 c, 00 c, 01 c, 01 c, 01 c, 1F c, 01 c, 01 c, 01 c, 00 c, 
00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 80 c, B0 c, 70 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 01 c, 01 c, 01 c, 01 c, 01 c, 01 c, 01 c, 
00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 30 c, 30 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 00 c, 00 c, 80 c, 60 c, 18 c, 04 c, 00 c, 60 c, 18 c, 06 c, 01 c, 00 c, 00 c, 00 c, 
00 c, E0 c, 10 c, 08 c, 08 c, 10 c, E0 c, 00 c, 00 c, 0F c, 10 c, 20 c, 20 c, 10 c, 0F c, 00 c, 
00 c, 10 c, 10 c, F8 c, 00 c, 00 c, 00 c, 00 c, 00 c, 20 c, 20 c, 3F c, 20 c, 20 c, 00 c, 00 c, 
00 c, 70 c, 08 c, 08 c, 08 c, 88 c, 70 c, 00 c, 00 c, 30 c, 28 c, 24 c, 22 c, 21 c, 30 c, 00 c, 
00 c, 30 c, 08 c, 88 c, 88 c, 48 c, 30 c, 00 c, 00 c, 18 c, 20 c, 20 c, 20 c, 11 c, 0E c, 00 c, 
00 c, 00 c, C0 c, 20 c, 10 c, F8 c, 00 c, 00 c, 00 c, 07 c, 04 c, 24 c, 24 c, 3F c, 24 c, 00 c, 
00 c, F8 c, 08 c, 88 c, 88 c, 08 c, 08 c, 00 c, 00 c, 19 c, 21 c, 20 c, 20 c, 11 c, 0E c, 00 c, 
00 c, E0 c, 10 c, 88 c, 88 c, 18 c, 00 c, 00 c, 00 c, 0F c, 11 c, 20 c, 20 c, 11 c, 0E c, 00 c, 
00 c, 38 c, 08 c, 08 c, C8 c, 38 c, 08 c, 00 c, 00 c, 00 c, 00 c, 3F c, 00 c, 00 c, 00 c, 00 c, 
00 c, 70 c, 88 c, 08 c, 08 c, 88 c, 70 c, 00 c, 00 c, 1C c, 22 c, 21 c, 21 c, 22 c, 1C c, 00 c, 
00 c, E0 c, 10 c, 08 c, 08 c, 10 c, E0 c, 00 c, 00 c, 00 c, 31 c, 22 c, 22 c, 11 c, 0F c, 00 c, 
00 c, 00 c, 00 c, C0 c, C0 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 30 c, 30 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 00 c, 80 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 80 c, 60 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 80 c, 40 c, 20 c, 10 c, 08 c, 00 c, 00 c, 01 c, 02 c, 04 c, 08 c, 10 c, 20 c, 00 c, 
40 c, 40 c, 40 c, 40 c, 40 c, 40 c, 40 c, 00 c, 04 c, 04 c, 04 c, 04 c, 04 c, 04 c, 04 c, 00 c, 
00 c, 08 c, 10 c, 20 c, 40 c, 80 c, 00 c, 00 c, 00 c, 20 c, 10 c, 08 c, 04 c, 02 c, 01 c, 00 c, 
00 c, 70 c, 48 c, 08 c, 08 c, 08 c, F0 c, 00 c, 00 c, 00 c, 00 c, 30 c, 36 c, 01 c, 00 c, 00 c, 
C0 c, 30 c, C8 c, 28 c, E8 c, 10 c, E0 c, 00 c, 07 c, 18 c, 27 c, 24 c, 23 c, 14 c, 0B c, 00 c, 
00 c, 00 c, C0 c, 38 c, E0 c, 00 c, 00 c, 00 c, 20 c, 3C c, 23 c, 02 c, 02 c, 27 c, 38 c, 20 c, 
08 c, F8 c, 88 c, 88 c, 88 c, 70 c, 00 c, 00 c, 20 c, 3F c, 20 c, 20 c, 20 c, 11 c, 0E c, 00 c, 
C0 c, 30 c, 08 c, 08 c, 08 c, 08 c, 38 c, 00 c, 07 c, 18 c, 20 c, 20 c, 20 c, 10 c, 08 c, 00 c, 
08 c, F8 c, 08 c, 08 c, 08 c, 10 c, E0 c, 00 c, 20 c, 3F c, 20 c, 20 c, 20 c, 10 c, 0F c, 00 c, 
08 c, F8 c, 88 c, 88 c, E8 c, 08 c, 10 c, 00 c, 20 c, 3F c, 20 c, 20 c, 23 c, 20 c, 18 c, 00 c, 
08 c, F8 c, 88 c, 88 c, E8 c, 08 c, 10 c, 00 c, 20 c, 3F c, 20 c, 00 c, 03 c, 00 c, 00 c, 00 c, 
C0 c, 30 c, 08 c, 08 c, 08 c, 38 c, 00 c, 00 c, 07 c, 18 c, 20 c, 20 c, 22 c, 1E c, 02 c, 00 c, 
08 c, F8 c, 08 c, 00 c, 00 c, 08 c, F8 c, 08 c, 20 c, 3F c, 21 c, 01 c, 01 c, 21 c, 3F c, 20 c, 
00 c, 08 c, 08 c, F8 c, 08 c, 08 c, 00 c, 00 c, 00 c, 20 c, 20 c, 3F c, 20 c, 20 c, 00 c, 00 c, 
00 c, 00 c, 08 c, 08 c, F8 c, 08 c, 08 c, 00 c, C0 c, 80 c, 80 c, 80 c, 7F c, 00 c, 00 c, 00 c, 
08 c, F8 c, 88 c, C0 c, 28 c, 18 c, 08 c, 00 c, 20 c, 3F c, 20 c, 01 c, 26 c, 38 c, 20 c, 00 c, 
08 c, F8 c, 08 c, 00 c, 00 c, 00 c, 00 c, 00 c, 20 c, 3F c, 20 c, 20 c, 20 c, 20 c, 30 c, 00 c, 
08 c, F8 c, F8 c, 00 c, F8 c, F8 c, 08 c, 00 c, 20 c, 3F c, 00 c, 3F c, 00 c, 3F c, 20 c, 00 c, 
08 c, F8 c, 30 c, C0 c, 00 c, 08 c, F8 c, 08 c, 20 c, 3F c, 20 c, 00 c, 07 c, 18 c, 3F c, 00 c, 
E0 c, 10 c, 08 c, 08 c, 08 c, 10 c, E0 c, 00 c, 0F c, 10 c, 20 c, 20 c, 20 c, 10 c, 0F c, 00 c, 
08 c, F8 c, 08 c, 08 c, 08 c, 08 c, F0 c, 00 c, 20 c, 3F c, 21 c, 01 c, 01 c, 01 c, 00 c, 00 c, 
E0 c, 10 c, 08 c, 08 c, 08 c, 10 c, E0 c, 00 c, 0F c, 18 c, 24 c, 24 c, 38 c, 50 c, 4F c, 00 c, 
08 c, F8 c, 88 c, 88 c, 88 c, 88 c, 70 c, 00 c, 20 c, 3F c, 20 c, 00 c, 03 c, 0C c, 30 c, 20 c, 
00 c, 70 c, 88 c, 08 c, 08 c, 08 c, 38 c, 00 c, 00 c, 38 c, 20 c, 21 c, 21 c, 22 c, 1C c, 00 c, 
18 c, 08 c, 08 c, F8 c, 08 c, 08 c, 18 c, 00 c, 00 c, 00 c, 20 c, 3F c, 20 c, 00 c, 00 c, 00 c, 
08 c, F8 c, 08 c, 00 c, 00 c, 08 c, F8 c, 08 c, 00 c, 1F c, 20 c, 20 c, 20 c, 20 c, 1F c, 00 c, 
08 c, 78 c, 88 c, 00 c, 00 c, C8 c, 38 c, 08 c, 00 c, 00 c, 07 c, 38 c, 0E c, 01 c, 00 c, 00 c, 
F8 c, 08 c, 00 c, F8 c, 00 c, 08 c, F8 c, 00 c, 03 c, 3C c, 07 c, 00 c, 07 c, 3C c, 03 c, 00 c, 
08 c, 18 c, 68 c, 80 c, 80 c, 68 c, 18 c, 08 c, 20 c, 30 c, 2C c, 03 c, 03 c, 2C c, 30 c, 20 c, 
08 c, 38 c, C8 c, 00 c, C8 c, 38 c, 08 c, 00 c, 00 c, 00 c, 20 c, 3F c, 20 c, 00 c, 00 c, 00 c, 
10 c, 08 c, 08 c, 08 c, C8 c, 38 c, 08 c, 00 c, 20 c, 38 c, 26 c, 21 c, 20 c, 20 c, 18 c, 00 c, 
00 c, 00 c, 00 c, FE c, 02 c, 02 c, 02 c, 00 c, 00 c, 00 c, 00 c, 7F c, 40 c, 40 c, 40 c, 00 c, 
00 c, 0C c, 30 c, C0 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 01 c, 06 c, 38 c, C0 c, 00 c, 
00 c, 02 c, 02 c, 02 c, FE c, 00 c, 00 c, 00 c, 00 c, 40 c, 40 c, 40 c, 7F c, 00 c, 00 c, 00 c, 
00 c, 00 c, 04 c, 02 c, 02 c, 02 c, 04 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 
00 c, 02 c, 02 c, 04 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 00 c, 19 c, 24 c, 22 c, 22 c, 22 c, 3F c, 20 c, 
08 c, F8 c, 00 c, 80 c, 80 c, 00 c, 00 c, 00 c, 00 c, 3F c, 11 c, 20 c, 20 c, 11 c, 0E c, 00 c, 
00 c, 00 c, 00 c, 80 c, 80 c, 80 c, 00 c, 00 c, 00 c, 0E c, 11 c, 20 c, 20 c, 20 c, 11 c, 00 c, 
00 c, 00 c, 00 c, 80 c, 80 c, 88 c, F8 c, 00 c, 00 c, 0E c, 11 c, 20 c, 20 c, 10 c, 3F c, 20 c, 
00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 00 c, 1F c, 22 c, 22 c, 22 c, 22 c, 13 c, 00 c, 
00 c, 80 c, 80 c, F0 c, 88 c, 88 c, 88 c, 18 c, 00 c, 20 c, 20 c, 3F c, 20 c, 20 c, 00 c, 00 c, 
00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 6B c, 94 c, 94 c, 94 c, 93 c, 60 c, 00 c, 
08 c, F8 c, 00 c, 80 c, 80 c, 80 c, 00 c, 00 c, 20 c, 3F c, 21 c, 00 c, 00 c, 20 c, 3F c, 20 c, 
00 c, 80 c, 98 c, 98 c, 00 c, 00 c, 00 c, 00 c, 00 c, 20 c, 20 c, 3F c, 20 c, 20 c, 00 c, 00 c, 
00 c, 00 c, 00 c, 80 c, 98 c, 98 c, 00 c, 00 c, 00 c, C0 c, 80 c, 80 c, 80 c, 7F c, 00 c, 00 c, 
08 c, F8 c, 00 c, 00 c, 80 c, 80 c, 80 c, 00 c, 20 c, 3F c, 24 c, 02 c, 2D c, 30 c, 20 c, 00 c, 
00 c, 08 c, 08 c, F8 c, 00 c, 00 c, 00 c, 00 c, 00 c, 20 c, 20 c, 3F c, 20 c, 20 c, 00 c, 00 c, 
80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 80 c, 00 c, 20 c, 3F c, 20 c, 00 c, 3F c, 20 c, 00 c, 3F c, 
80 c, 80 c, 00 c, 80 c, 80 c, 80 c, 00 c, 00 c, 20 c, 3F c, 21 c, 00 c, 00 c, 20 c, 3F c, 20 c, 
00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 00 c, 1F c, 20 c, 20 c, 20 c, 20 c, 1F c, 00 c, 
80 c, 80 c, 00 c, 80 c, 80 c, 00 c, 00 c, 00 c, 80 c, FF c, A1 c, 20 c, 20 c, 11 c, 0E c, 00 c, 
00 c, 00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 0E c, 11 c, 20 c, 20 c, A0 c, FF c, 80 c, 
80 c, 80 c, 80 c, 00 c, 80 c, 80 c, 80 c, 00 c, 20 c, 20 c, 3F c, 21 c, 20 c, 00 c, 01 c, 00 c, 
00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 80 c, 00 c, 00 c, 33 c, 24 c, 24 c, 24 c, 24 c, 19 c, 00 c, 
00 c, 80 c, 80 c, E0 c, 80 c, 80 c, 00 c, 00 c, 00 c, 00 c, 00 c, 1F c, 20 c, 20 c, 00 c, 00 c, 
80 c, 80 c, 00 c, 00 c, 00 c, 80 c, 80 c, 00 c, 00 c, 1F c, 20 c, 20 c, 20 c, 10 c, 3F c, 20 c, 
80 c, 80 c, 80 c, 00 c, 00 c, 80 c, 80 c, 80 c, 00 c, 01 c, 0E c, 30 c, 08 c, 06 c, 01 c, 00 c, 
80 c, 80 c, 00 c, 80 c, 00 c, 80 c, 80 c, 80 c, 0F c, 30 c, 0C c, 03 c, 0C c, 30 c, 0F c, 00 c, 
00 c, 80 c, 80 c, 00 c, 80 c, 80 c, 80 c, 00 c, 00 c, 20 c, 31 c, 2E c, 0E c, 31 c, 20 c, 00 c, 
80 c, 80 c, 80 c, 00 c, 00 c, 80 c, 80 c, 80 c, 80 c, 81 c, 8E c, 70 c, 18 c, 06 c, 01 c, 00 c, 
decimal
constant font

width height * 8 / buffer: display_memory

: lcd_init
  S" I2C_SDA_PIN" environment? drop
  S" I2C_SCL_PIN" environment? drop
  Wire.begin
  Wire.reset

  display_memory width height * 8 / 255 fill
;

: senddata
  LCD_I2C Wire.BeginTransmission 0= abort" failed to send command"
  64 Wire.sendByte 0= abort" failed"
  Wire.sendByte 0= abort" failed"
  true Wire.endTransmission
;

: sendcommand
  LCD_I2C Wire.BeginTransmission 0= abort" failed to send command"
  0 Wire.sendByte 0= abort" failed"
  Wire.sendByte 0= abort" failed"
  true Wire.endTransmission
;

: send1 sendcommand ;
: send2 swap sendcommand sendcommand ;
: send3 rot sendcommand send2 ;

hex
: init
  AE send1			\ display off ( af is on )
  A8 3F send2		\ set mux ratio
  d3 00 send2		\ display offset
  40 send1			\ start line
  A1 send1			\ seg remap
  C8 send1			\ com scan direction normal
  a6 send1			\ normal display ( A7 would be inverse )
  d5 80 send2		\ oscillator freq
  DA 12 send2		\ com pins ( alternate, no remap )
  81 7F send2		\ contrast control
  A4 send1			\ entire display ( A4 show ram, A5 ignore ram )
  d9 F1 send2		\ precharge period
  db 40 send2		\ VCOMMH deselect level
  8d 14 send2		\ charge pump  
  0 send1
  16 send1
  B0 send1
  20 0 send2		\ memory mode ( 0 = horiz, 1 = vert, 2 = page )
  21 0 7F send3		\ column address, start and stop
  22 0 7 send3		\ page address
  2e send1			\ deactivate any scrolling
  af send1			\ display on ( ae is off )
;
decimal

22 constant _PAGEADDR

: display
\  _PAGEADDR sendcommand 0 sendcommand height 8 / 1 - sendcommand	\ we're going to send page0..7 (IE all)

  display_memory
  width height * 8 / 0 do
	 dup c@ senddata 1+
  loop
  drop
;

: clear display_memory 1024 0 fill display ;

: clearF display_memory 1024 255 fill display ;

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

: drawchar	\ x y char --
  32 - 16 * font +		( x y ptr-char -- )

  rot 8 * rot 256 * + 
  display_memory +	( ptr-char ptr-disp -- )
  2dup 8 cmove>
  128 + swap 8 + swap 8 cmove>
;

: drawline 	\ x y c-addr u --
  0 ?do
	dup c@		( x y c-addr c -- )
 	3 pick 3 pick rot drawchar
    1+ rot 1+ rot rot
  loop
  2drop drop
;

