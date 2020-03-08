
ext-wordlist get-order 1+ set-order

include done.fth

ext-wordlist get-order 1+ set-order 
' bye ' save

[defined] done [if]
    done
	only forth definitions execute atsamd21g18_kernel.img execute
[else]
	drop execute
[then]


