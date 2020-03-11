
ext-wordlist get-order 1+ set-order

include extra/done.fth

ext-wordlist get-order 1+ set-order 
' bye ' save

[defined] done [if]
    done
	only forth definitions execute forth_platform.img execute
[else]
	drop execute
[then]


