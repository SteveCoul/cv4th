
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

include platform/atsamd51/flash.fth
include platform/atsamd51/clock.fth
include platform/atsamd51/gpio.fth
include platform/atsamd51/vector_table.fth
include kernel/block.fth
include kernel/verbose_exceptions.fth
include kernel/structure.fth
include extra/ringbuffer.fth
include extra/vi.fth
include extra/toys.fth
require extra/thread.fth


\ PIN_D5 env-constant I2C_SDA_PIN
\ PIN_D6 env-constant I2C_SCL_PIN
\ include extra/Wire_bitbang.fth
include platform/arduino/Wire.fth

ext-wordlist get-order 1+ set-order
87 env-constant AT24C32_ADDRESS
include extra/i2c_at24c32_eeprom.fth

ext-wordlist get-order 1+ set-order
104 env-constant DS3231_ADDRESS
include extra/i2c_ds3231_rtc.fth

ext-wordlist get-order 1+ set-order
60 env-constant SSD1306_ADDRESS
include extra/i2c_ssd1306_lcd.fth

include platform/done.fth

