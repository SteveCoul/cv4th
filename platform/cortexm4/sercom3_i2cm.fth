
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x41014000 register-bank SERCOM3_I2CM
	32bit register CTRLA
		1 bit swrst
		1 bit enable
		3 bit mode
		2 skip-bit
		1 bit runstdby
		8 skip-bit
		1 bit pinout
		3 skip-bit
		2 bit sdahold
		1 bit mexttoen
		1 bit sexttoen
		2 bit speed
		1 skip-bit
		1 bit sclsm
		2 bit inactout
		1 bit lowtout		
		1 skip-bit
	end-register
	32bit register CTRLB
		8 skip-bit
		1 bit smen
		1 bit qcen
		6 skip-bit
		2 bit cmd
		1 bit ackact
	end-register
	32bit register CTRLC
		24 skip-bit
		1 bit data32b
	end-register
	32bit register BAUD
		8 bit baud
		8 bit baudlow
		8 bit hsbaud
		8 bit hsbaudlow
	end-register
	4 skip-byte
	8bit register ITENCLR
		1 bit mb
		1 bit sb
		5 skip-bit
		1 bit error
	end-register
	1 skip-byte
	8bit register ITENSET
		1 bit mb
		1 bit sb
		5 skip-bit
		1 bit error
	end-register
	1 skip-byte
	8bit register INTFLAG
		1 bit mb
		1 bit sb
		5 skip-bit
		1 bit error
	end-register
	1 skip-byte
	16bit register STATUS
		1 bit buserr
		1 bit arblost
		1 bit rxnack
		1 skip-bit
		2 bit busstate
		1 bit lowtout
		1 bit clkhold
		1 bit mextout
		1 bit sextout
		1 bit lenerr
	end-register
	32bit register SYNCBUSY
		1 bit swrst
		1 bit enable
		1 bit sysop
	end-register
	4 skip-byte
	32bit register ADDR
		11 bit addr
		2 skip-bit
		1 bit lenen
		1 bit hs
		1 bit tenbiten
		8 bit len
	end-register
	32bit register DATA
		8 bit byte
	end-register
	4 skip-byte
	32bit register DBGCTRL
		1 bit dbgstop
	end-register
end-register-bank

