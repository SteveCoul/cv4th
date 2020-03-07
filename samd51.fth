
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
1024 1008 * env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE
512 env-constant /FLASH_PAGE_SIZE

include samd51_flash.fth
include block.fth

ext-wordlist get-order 1+ set-order ' bye ' save only forth definitions execute samd51_kernel.img execute

