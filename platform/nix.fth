
ext-wordlist get-order 1+ set-order
3 env-constant #BLOCK_BUFFERS
0 env-constant /FLASH_BASE
1024 16 * env-constant /FLASH_SIZE

include platform/flashfile.fth
include kernel/block.fth
include kernel/locals.fth
include kernel/dis.fth
include kernel/verbose_exceptions.fth
include kernel/structure.fth

include extra/vi.fth
include extra/toys.fth
include extra/thread.fth
include extra/ringbuffer.fth
include platform/done.fth

