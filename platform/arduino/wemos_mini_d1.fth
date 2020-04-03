
include kernel/locals.fth
include kernel/dis.fth
include kernel/verbose_exceptions.fth
include kernel/structure.fth

include extra/toys.fth
include extra/thread.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

16 constant PIN_D0
5 constant PIN_D1
4 constant PIN_D2
0 constant PIN_D3
2 constant PIN_D4
14 constant PIN_D5
12 constant PIN_D6
13 constant PIN_D7
15 constant PIN_D8

1 constant PIN_TX
3 constant PIN_RX
PIN_D1 constant PIN_SDL
PIN_D2 constant PIN_SDA
PIN_D4 constant LED_BUILTIN
PIN_D5 constant PIN_SCLK
PIN_D6 constant PIN_MISO
PIN_D7 constant PIN_MOSI
PIN_D8 constant PIN_CS

forth-wordlist set-current

include platform/arduino/digital.fth

include platform/arduino/Wire.fth

include platform/done.fth

