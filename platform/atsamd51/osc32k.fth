
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x40001400 register-bank OSC32KCTRL
	32bit register ITENCLR
		1 bit xosc32krdy
		1 skip-bit
		1 bit xosc32kfail
	end-register
	32bit register ITENSET
		1 bit xosc32krdy
		1 skip-bit
		1 bit xosc32kfail
	end-register
	32bit register INTFLAG
		1 bit xosc32krdy
		1 skip-bit
		1 bit xosc32kfail
	end-register
	32bit register STATUS
		1 bit xosc32krdy
		1 skip-bit
		1 bit xosc32kfail
		1 bit xosc32ksw
	end-register
	8bit register RTCCTRL
		3 bit rtcsel
	end-register
	3 skip-byte
	16bit register XOSC32K
		1 skip-bit
		1 bit enable
		1 bit xtalen
		1 bit en32k
		1 bit en1k
		1 skip-bit
		1 bit runstdby
		1 bit ondemand
		3 bit startup
		1 skip-bit
		1 bit wrtlock
		2 bit cgm
	end-register
	8bit register CFDCTRL
		1 bit cfden
		1 bit swback
		1 bit cfdpresc
	end-register
	8bit register EVCTRL
		1 bit cfdeo
	end-register
	4 skip-byte
	32bit register OSCULP32K
		1 skip-bit
		1 bit en32k
		1 bit en1k
		5 skip-bit
		6 bit calib
		1 skip-bit
		1 bit wrtlock
	end-register
end-register-bank


