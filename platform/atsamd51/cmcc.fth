
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x41006000 register-bank CMCC
	32bit register TYPE
		1 bit ap
		1 bit gclk
		1 bit randp
		1 bit lrup
		1 bit rrp
		2 bit waynum
		1 bit lckdown
		3 bit csize
		3 bit clsize
		2 skip-bit
	end-register
	32bit register CFG
		1 skip-bit
		1 bit icdis
		1 bit dcdis
		1 skip-bit
		3 bit csizesw
	end-register
	32bit register CTRL
		1 bit cen
	end-register
	32bit register SR
		1 bit csts
	end-register
	32bit register LCKWAY
		4 bit lckway
	end-register
	12 skip-byte
	32bit register MAINT0
		1 bit invall
	end-register
	32bit register MAINT1
		4 skip-bit
		8 bit index
		16 skip-bit
		4 bit way
	end-register
	32bit register MCFG
		2 bit mode
	end-register
	32bit register MEN
		1 bit menable
	end-register
	32bit register MCTRL
		1 bit swrst
	end-register
end-register-bank

