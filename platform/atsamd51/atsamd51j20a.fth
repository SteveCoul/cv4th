
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

\ First onboot - do chip specific startup
private-namespace
defer (chipstartup) :noname ; is (chipstartup)
onboot: chipstartup	
	(chipstartup)
onboot;

require extra/dmesg.fth
require platform/atsamd51/flash.fth
require platform/atsamd51/clock.fth
require platform/atsamd51/gpio.fth
require platform/atsamd51/irqs.fth
require platform/atsamd51/peripherals.fth
require platform/atsamd51/vector_table.fth
require platform/atsamd51/interrupts.fth
require platform/atsamd51/startup.fth
require platform/atsamd51/usb.fth
require kernel/block.fth
require kernel/verbose_exceptions.fth
require kernel/structure.fth
require kernel/dis.fth
require extra/ringbuffer.fth
require extra/vi.fth
require extra/toys.fth
require extra/thread.fth

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

1 [IF]
require platform/atsamd51/uart_console.fth
[THEN]

require platform/atsamd51/usb_cdc.fth

require platform/done.fth

