
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x40001800 register-bank SUPC
	32bit register INTENCLR
		1 bit bod33rdy
		1 bit bod33det
		1 bit b33srdy
		5 skip-bit
		1 bit vregrdy
		1 skip-bit
		1 bit vcorerdy
	end-register
	32bit register INTENSET
		1 bit bod33rdy
		1 bit bod33det
		1 bit b33srdy
		5 skip-bit
		1 bit vregrdy
		1 skip-bit
		1 bit vcorerdy
	end-register
	32bit register INTFLAG
		1 bit bod33rdy
		1 bit bod33det
		1 bit b33srdy
		5 skip-bit
		1 bit vregrdy
		1 skip-bit
		1 bit vcorerdy
	end-register
	32bit register STATUS
		1 bit bod33rdy
		1 bit bod33det
		1 bit b33srdy
		5 skip-bit
		1 bit vregrdy
		1 skip-bit
		1 bit vcorerdy
	end-register
	32bit register BOD33
		1 skip-bit
		1 bit enable
		2 bit action
		1 bit stdbycfg
		1 bit runstdby
		1 bit runhib
		1 bit runbkup
		4 bit hyst
		3 bit psel
		1 skip-bit
		8 bit level
		8 bit vbatlevel
	end-register
	4 skip-byte
	32bit register VREG
		1 skip-bit
		1 bit enable
		1 bit sel
		4 skip-bit
		1 bit runbkup
		8 skip-bit
		1 bit vsen
	end-register
	32bit register VREF
		1 skip-bit
		1 bit tsen
		1 bit vrefoe
		1 bit tssel
		2 skip-bit
		1 bit runstdby
		1 bit ondemand
		8 skip-bit
		4 bit sel
	end-register
	32bit register BBPS
		1 bit conf
		1 skip-bit
		1 bit wakeen
	end-register
	32bit register BKOUT
		1 bit en0
		1 bit en1
		6 skip-bit
		1 bit clr0
		1 bit clr1
		6 skip-bit
		1 bit set0
		1 bit set1
		6 skip-bit
		1 bit rtctgl0
		1 bit rtctgl1
	end-register
	32bit register BKIN
		1 bit bkin0
		1 bit bkin1
	end-register
end-register-bank

