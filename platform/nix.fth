
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
0 env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE

include platform/flashfile.fth
include kernel/block.fth
include kernel/locals.fth
include kernel/dis.fth
include extra/vi.fth
include extra/toys.fth
\ include extra/bitbang_i2c.fth

include platform/done.fth

