
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

include samd51_flash.fth
include samd51_clock.fth
include samd51_gpio.fth
include block.fth
include vi.fth
include toys.fth
include done.fth

ext-wordlist get-order 1+ set-order 
' bye ' save

[defined] done [if]
    done
	only forth definitions execute samd51j20a_kernel.img execute
[else]
	drop execute
[then]


