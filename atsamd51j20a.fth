
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

include atsamd51_flash.fth
include atsamd51_clock.fth
include atsamd51_gpio.fth
include block.fth
include vi.fth
include toys.fth
include bitbang_i2c.fth

include demo_rtc_i2c.fth

include done.fth

ext-wordlist get-order 1+ set-order 
' bye ' save

[defined] done [if]
    done
	only forth definitions execute forth_platform.img execute
[else]
	drop execute
[then]


