
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x40001000 register-bank OSCCTRL
	8bit register EVCTRL
		1 bit cfdeo0
		1 bit cfdeo1
	end-register
	3 skip-byte
	32bit register ITENCLR
		1 bit xoscrdy0
		1 bit xoscrdy1
		1 bit xoscfail0
		1 bit xoscfail1
		4 skip-bit
		1 bit dfllrdy
		1 bit dflloob
		1 bit dflllckf
		1 bit dflllckc
		1 bit dfllrcs
		3 skip-bit
		1 bit dpll0lckr
		1 bit dpll0lckf
		1 bit dpll0lto
		1 bit dpll0ldrto
		4 skip-bit
		1 bit dpll1lckr
		1 bit dpll1lckf
		1 bit dpll1lto
		1 bit dpll1ldrto
		4 skip-bit
	end-register
	32bit register ITENSET
		1 bit xoscrdy0
		1 bit xoscrdy1
		1 bit xoscfail0
		1 bit xoscfail1
		4 skip-bit
		1 bit dfllrdy
		1 bit dflloob
		1 bit dflllckf
		1 bit dflllckc
		1 bit dfllrcs
		3 skip-bit
		1 bit dpll0lckr
		1 bit dpll0lckf
		1 bit dpll0lto
		1 bit dpll0ldrto
		4 skip-bit
		1 bit dpll1lckr
		1 bit dpll1lckf
		1 bit dpll1lto
		1 bit dpll1ldrto
		4 skip-bit
	end-register
	32bit register INTFLAG
		1 bit xoscrdy0
		1 bit xoscrdy1
		1 bit xoscfail0
		1 bit xoscfail1
		4 skip-bit
		1 bit dfllrdy
		1 bit dflloob
		1 bit dflllckf
		1 bit dflllckc
		1 bit dfllrcs
		3 skip-bit
		1 bit dpll0lckr
		1 bit dpll0lckf
		1 bit dpll0lto
		1 bit dpll0ldrto
		4 skip-bit
		1 bit dpll1lckr
		1 bit dpll1lckf
		1 bit dpll1lto
		1 bit dpll1ldrto
		4 skip-bit
	end-register
	32bit register STATUS
		1 bit xoscrdy0
		1 bit xoscrdy1
		1 bit xoscfail0
		1 bit xoscfail1
		4 skip-bit
		1 bit dfllrdy
		1 bit dflloob
		1 bit dflllckf
		1 bit dflllckc
		1 bit dfllrcs
		3 skip-bit
		1 bit dpll0lckr
		1 bit dpll0lckf
		1 bit dpll0lto
		1 bit dpll0ldrto
		4 skip-bit
		1 bit dpll1lckr
		1 bit dpll1lckf
		1 bit dpll1lto
		1 bit dpll1ldrto
		4 skip-bit
	end-register
	32bit register XOSCCTRL0
		1 skip-bit
		1 bit enable
		1 bit xtalen
		3 skip-bit
		1 bit runstdby
		1 bit ondemand
		1 bit lowbufgain
		2 bit iptat
		4 bit imult
		1 bit enalc
		1 bit cfden
		1 bit swben
		2 skip-bit
		4 bit startup
		4 bit cfdpresc
	end-register
	32bit register XOSCCTRL1
		1 skip-bit
		1 bit enable
		1 bit xtalen
		3 skip-bit
		1 bit runstdby
		1 bit ondemand
		1 bit lowbufgain
		2 bit iptat
		4 bit imult
		1 bit enalc
		1 bit cfden
		1 bit swben
		2 skip-bit
		4 bit startup
		4 bit cfdpresc
	end-register
	8bit register DFLLCTRLA
		1 skip-bit
		1 bit enable
		4 skip-bit
		1 bit runstdby
		1 bit ondemand
	end-register
	3 skip-byte
	8bit register DFLLCTRLB
		1 bit mode
		1 bit stable
		1 bit llaw
		1 bit usbcrm
		1 bit ccdis
		1 bit qldis
		1 bit bplckc
		1 bit waitlock
	end-register
	3 skip-byte
	32bit register DFLLVAL
		8 bit fine
		2 skip-bit
		6 bit coarse
		16 bit diff
	end-register
	32bit register DFLLMUL
		16 bit mul
		8 bit fstep
		2 skip-bit
		6 bit cstep
	end-register
	8bit register DFLLSYNC
		1 skip-bit
		1 bit enable
		1 bit dfllctrlb
		1 bit dfllval
		1 bit dfllmul
	end-register
	3 skip-byte
	8bit register DPLL0CTRLA
		1 skip-bit
		1 bit enable
		4 skip-bit
		1 bit runstdby
		1 bit ondemand
	end-register
	3 skip-byte
	32bit register DPLL0RATIO
		13 bit ldr
		3 skip-bit
		5 bit ldrfrac
	end-register
	32bit register DPLL0CTRLB
		4 bit filter
		1 bit wuf
		3 bit refclk
		3 bit ltime
		1 bit lbypass
		3 bit dcofilter
		1 bit dcoen
		11 bit div
	end-register
	32bit register DPLL0SYNCBUSY
		1 skip-bit
		1 bit enable
		1 bit dpllratio
	end-register
	32bit register DPLL0STATUS
		1 bit lock
		1 bit clkrdy
	end-register
	8bit register DPLL1CTRLA
		1 skip-bit
		1 bit enable
		4 skip-bit
		1 bit runstdby
		1 bit ondemand
	end-register
	3 skip-byte
	32bit register DPLL1RATIO
		13 bit ldr
		3 skip-bit
		5 bit ldrfrac
	end-register
	32bit register DPLL1CTRLB
		4 bit filter
		1 bit wuf
		3 bit refclk
		3 bit ltime
		1 bit lbypass
		3 bit dcofilter
		1 bit dcoen
		11 bit div
	end-register
	32bit register DPLL1SYNCBUSY
		1 skip-bit
		1 bit enable
		1 bit dpllratio
	end-register
	32bit register DPLL1STATUS
		1 bit lock
		1 bit clkrdy
	end-register
end-register-bank


