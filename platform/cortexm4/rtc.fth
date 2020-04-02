
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x40002400 register-bank RTCmode0
	16bit register CTRLA
		1 bit swrst
		1 bit enable
		2 bit mode
		3 skip-bit
		1 bit matchclr
		4 bit prescaler
		1 skip-bit
		1 bit bktrst
		1 bit gptrst
		1 bit countsync
	end-register
	16bit register CTRLB
		1 bit gp0en
		1 bit gp2en
		2 skip-bit
		1 bit debmaj
		1 bit debasync
		1 bit rtcout
		1 bit dmaen
		3 bit debf
		1 skip-bit
		3 bit actf
		1 skip-bit
	end-register
	32bit register EVCTRL
		1 bit pereo0
		1 bit pereo1
		1 bit pereo2
		1 bit pereo3
		1 bit pereo4
		1 bit pereo5
		1 bit pereo6
		1 bit pereo7
		1 bit cmpeo0
		1 bit cmpeo1
		4 skip-bit
		1 bit tampereo
		1 bit ovfeo
		1 bit tampevei	
	end-register
	16bit register ITENCLR
		1 bit pereo0
		1 bit pereo1
		1 bit pereo2
		1 bit pereo3
		1 bit pereo4
		1 bit pereo5
		1 bit pereo6
		1 bit pereo7
		1 bit cmpeo0
		1 bit cmpeo1
		4 skip-bit
		1 bit tampereo
		1 bit ovfeo
	end-register	
	16bit register ITENSET
		1 bit pereo0
		1 bit pereo1
		1 bit pereo2
		1 bit pereo3
		1 bit pereo4
		1 bit pereo5
		1 bit pereo6
		1 bit pereo7
		1 bit cmpeo0
		1 bit cmpeo1
		4 skip-bit
		1 bit tampereo
		1 bit ovfeo
	end-register	
	16bit register INTFLAG
		1 bit pereo0
		1 bit pereo1
		1 bit pereo2
		1 bit pereo3
		1 bit pereo4
		1 bit pereo5
		1 bit pereo6
		1 bit pereo7
		1 bit cmpeo0
		1 bit cmpeo1
		4 skip-bit
		1 bit tampereo
		1 bit ovfeo
	end-register	
	8bit register DBGCTRL
		1 bit dbgrun
	end-register
	1 skip-byte
	32bit register SYNCBUSY
		1 bit swrst
		1 bit enable
		1 bit freqcorr
		1 bit count
		1 skip-bit
		1 bit comp0
		1 bit comp1
		8 skip-bit
		1 bit countsync
		1 bit gp0
		1 bit gp1
		1 bit gp2
		1 bit gp3
	end-register
	8bit register FREQCORR
		7 bit value
		1 bit sign
	end-register
	3 skip-byte
	32bit register COUNT
	end-register
	4 skip-byte
	32bit register COMP0
	end-register
	32bit register COMP1
	end-register
	24 skip-byte
	32bit register GP0
	end-register
	32bit register GP1
	end-register
	32bit register GP2
	end-register
	32bit register GP3
	end-register
	16 skip-byte
	32bit register TAMPCTRL
		2 bit in0act
		2 bit in1act
		2 bit in2act
		2 bit in3act
		2 bit in4act
		6 skip-bit
		1 bit tamlvl0
		1 bit tamlvl1
		1 bit tamlvl2
		1 bit tamlvl3
		1 bit tamlvl4
		3 skip-bit
		1 bit debnc0
		1 bit debnc1
		1 bit debnc2
		1 bit debnc3
		1 bit debnc4
	end-register
	32bit register TIMESTAMP
	end-register
	32bit register TAMPID
		1 bit tampid0
		1 bit tampid1
		1 bit tampid2
		1 bit tampid3
		1 bit tampid4
		26 skip-bit
		1 bit tampevt
	end-register
	20 skip-byte
	32bit register BKUP0
	end-register
	32bit register BKUP1
	end-register
	32bit register BKUP2
	end-register
	32bit register BKUP3
	end-register
	32bit register BKUP4
	end-register
	32bit register BKUP5
	end-register
	32bit register BKUP6
	end-register
	32bit register BKUP7
	end-register
end-register-bank

only forth definitions

