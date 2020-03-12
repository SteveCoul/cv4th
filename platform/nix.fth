
\ include kernel/block.fth
include extra/vi.fth
include extra/toys.fth
\ include extra/bitbang_i2c.fth

include extra/done.fth

ext-wordlist get-order 1+ set-order 
' bye ' save

[defined] done [if]
    done
	only forth definitions execute forth_platform.img execute
[else]
	drop execute
[then]


