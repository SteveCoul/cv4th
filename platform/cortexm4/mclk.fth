
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x40000800 register-bank MCLK
	8bit register CTRLA
	end-register
	8bit register ITENCLR
		1 bit chkrdy
	end-register
	8bit register ITENSET
		1 bit chkrdy
	end-register
	8bit register INTFLAG
		1 bit chkrdy
	end-register
	8bit register HSDIV
	end-register
	8bit register CPUDIV
	end-register
	10 skip-byte
	32bit register AHBMASK
		1 bit hpbn0
		1 bit hpbn1
		1 bit hpbn2
		1 bit hpbn3
		1 bit dsu
		1 skip-bit
		1 bit nvmctrl
		1 skip-bit
		1 bit cmcc
		1 bit dmac
		1 bit usb
		1 skip-bit
		1 bit pac
		1 bit qspi
		1 bit gmac
		1 bit sdhcn0
		1 bit sdhcn1
		1 bit cann0
		1 bit cann1
		1 bit icm
		1 bit pukcc
		1 bit qspi_2x
		1 bit nvmctrl_smeeprom
		1 bit nvmctrl_cache
		8 skip-bit
	end-register
	32bit register APBAMASK
		1 bit pac
		1 bit pm
		1 bit mclk
		1 bit rstc
		1 bit oscctrl
		1 bit osc32kctrl
		1 bit supc
		1 bit gclk
		1 bit wdt
		1 bit rtc
		1 bit eic
		1 bit freqm
		1 bit sercom0
		1 bit sercom1
		1 bit tcn0
		1 bit tcn1
		16 skip-bit
	end-register
	32bit register APBBMASK
		1 bit usb
		1 bit dsu
		1 bit nvmctrl
		1 skip-bit
		1 bit port
		2 skip-bit
		1 bit evsys
		1 skip-bit
		1 bit sercom2
		1 bit sercom3
		1 bit tccn0
		1 bit tccn1
		1 bit tcn2
		1 bit tcn3
		1 skip-bit
		1 bit ramecc
		15 skip-bit
	end-register
	32bit register APBCMASK
		2 skip-bit	
		1 bit gmac
		1 bit tccn2
		1 bit tccn3
		1 bit tcn4
		1 bit tcn5
		1 bit pdec
		1 bit ac
		1 bit aes
		1 bit trng
		1 bit icm
		1 skip-bit
		1 bit qspi
		1 bit ccl
		17 skip-bit
	end-register
	32bit register APBDMASK	
		1 bit sercom4
		1 bit sercom5
		1 bit sercom6
		1 bit sercom7
		1 bit tcc4
		1 bit tc6
		1 bit tc7
		1 bit adc0
		1 bit adc1
		1 bit dac
		1 bit i2s
		1 bit pcc	
	end-register
end-register-bank


