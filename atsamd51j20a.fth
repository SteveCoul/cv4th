
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

include atsamd51_flash.fth
include atsamd51_clock.fth
include atsamd51_gpio.fth
include extra/block.fth
include extra/vi.fth
include extra/toys.fth
include extra/bitbang_i2c.fth

ext-wordlist get-order 1+ set-order
PIN_D5 env-constant I2C_SDA_PIN
PIN_D6 env-constant I2C_SCL_PIN
87 env-constant AT24C32_ADDRESS
104 env-constant DS3231_ADDRESS
include extra/demo_i2c.fth

include extra/done.fth

ext-wordlist get-order 1+ set-order 
' bye ' save

[defined] done [if]
    done
	only forth definitions execute forth_platform.img execute
[else]
	drop execute
[then]


