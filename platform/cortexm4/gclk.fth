
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
		12 bit genctrl
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


\ FIXME - use the registerAPI
hex
40001C00 constant GCLK
80 constant PCHCTRL0
 4 constant EIC_GCLK_ID
decimal

: eic-gclk
  [ hex ] 42 [ decimal ] GCLK PCHCTRL0 + EIC_GCLK_ID cells + s>d d32!
;

