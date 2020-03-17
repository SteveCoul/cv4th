
include kernel/locals.fth
include kernel/dis.fth
include kernel/verbose_exceptions.fth
include kernel/structure.fth

include extra/toys.fth
include extra/thread.fth

include platform/esp8266/mini_gpio_pins.fth
include platform/arduino/digital.fth

\ PIN_D2 env-constant I2C_SDA_PIN
\ PIN_D1 env-constant I2C_SCL_PIN
\ include extra/Wire_bitbang.fth
include platform/arduino/Wire.fth

ext-wordlist get-order 1+ set-order

\ 3 env-constant AS3935_ADDRESS
\ include extra/demo_i2c.fth

include extra/i2c_ssd1306_lcd.fth

include platform/done.fth

