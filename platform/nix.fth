
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
0 env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE

include platform/flashfile.fth
include platform/gpio_dummy.fth

include kernel/block.fth
include kernel/locals.fth
include kernel/dis.fth
include kernel/verbose_exceptions.fth
include kernel/structure.fth

include extra/vi.fth
include extra/toys.fth
include extra/thread.fth
include extra/ringbuffer.fth

ext-wordlist get-order 1+ set-order
0 env-constant I2C_SDA_PIN
0 env-constant I2C_SCL_PIN
include extra/Wire_bitbang.fth

ext-wordlist get-order 1+ set-order
104 env-constant DS3231_ADDRESS
include extra/i2c_ds3231_rtc.fth

ext-wordlist get-order 1+ set-order
3 env-constant AS3935_ADDRESS
include extra/i2c_as3935_lightning_detector.fth

ext-wordlist get-order 1+ set-order
60 env-constant SSD1306_ADDRESS
include extra/i2c_ssd1306_lcd.fth

ext-wordlist get-order 1+ set-order
87 env-constant AT24C32_ADDRESS
include extra/i2c_at24c32_eeprom.fth

include platform/done.fth

