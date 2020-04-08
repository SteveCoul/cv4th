
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x40001C00 register-bank GCLK
	8bit register CTRLA
		1 bit swrst
	end-register
	3 skip-byte
	32bit register SYNCBUSY
		1 bit swrst
		1 skip-bit
		1 bit genctrl0
		1 bit genctrl1
		1 bit genctrl2
		1 bit genctrl3
		1 bit genctrl4
		1 bit genctrl5
		1 bit genctrl6
		1 bit genctrl7
		1 bit genctrl8
		1 bit genctrl9
		1 bit genctrl10
		1 bit genctrl11
	end-register
	24 skip-byte
	12 element 32bit register-array GENCTRLn
		5 bit src
		3 skip-bit
		1 bit genen
		1 bit idc
		1 bit oov
		1 bit oe
		1 bit divsel
		1 bit runstdby
		2 skip-bit
		16 bit div
	end-register-array
	48 skip-byte
	48 element 32bit register-array PCHCTRLn
		4 bit gen
		2 skip-bit
		1 bit chen
		1 bit wrtlock	
	end-register-array
end-register-bank

4 constant GCLK_GENCTRL_SRC_OSCULP32K
6 constant GCLK_GENCTRL_SRC_DFLL
7 constant GCLK_GENCTRL_SRC_DPLL0
8 constant GCLK_GENCTRL_SRC_DPLL1

10 constant USB_GCLK_ID

