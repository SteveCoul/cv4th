
include kernel/locals.fth
include kernel/dis.fth
include kernel/verbose_exceptions.fth
include kernel/structure.fth

include extra/toys.fth
include extra/thread.fth

include platform/esp8266/mini_gpio_pins.fth
include platform/arduino/digital.fth

PIN_D2 env-constant I2C_SDA_PIN
PIN_D1 env-constant I2C_SCL_PIN
include extra/bitbang_i2c.fth

ext-wordlist get-order 1+ set-order

3 env-constant AS3935_ADDRESS

include extra/demo_i2c.fth

include platform/done.fth

