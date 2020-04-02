
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

require platform/cortexm4/eic.fth
require platform/cortexm4/nvic.fth
require platform/cortexm4/gclk.fth
require platform/cortexm4/mclk.fth
require platform/cortexm4/osc32k.fth
require platform/cortexm4/oscctrl.fth
require platform/cortexm4/rtc.fth
require platform/atsamd51/flash.fth
require platform/atsamd51/clock.fth
require platform/atsamd51/gpio.fth
require platform/atsamd51/irqs.fth
require platform/atsamd51/peripherals.fth
require platform/atsamd51/vector_table.fth
require platform/atsamd51/interrupts.fth
require platform/atsamd51/startup.fth
require kernel/block.fth
require kernel/verbose_exceptions.fth
require kernel/structure.fth
require extra/ringbuffer.fth
require extra/vi.fth
require extra/toys.fth
require extra/thread.fth

\ PIN_D5 env-constant I2C_SDA_PIN
\ PIN_D6 env-constant I2C_SCL_PIN
\ require extra/Wire_bitbang.fth

\ require platform/arduino/Wire.fth

require platform/atsamd51/Wire.fth

ext-wordlist get-order 1+ set-order
87 env-constant AT24C32_ADDRESS
require extra/i2c_at24c32_eeprom.fth

ext-wordlist get-order 1+ set-order
104 env-constant DS3231_ADDRESS
require extra/i2c_ds3231_rtc.fth

ext-wordlist get-order 1+ set-order
60 env-constant SSD1306_ADDRESS
require extra/i2c_ssd1306_lcd.fth

3 env-constant AS3935_ADDRESS
require extra/i2c_as3935_lightning_detector.fth

require platform/done.fth

