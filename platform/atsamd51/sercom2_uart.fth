
require extra/register.fth

ext-wordlist get-order 1+ set-order

ext-wordlist set-current

0x41012000 register-bank SERCOM2_UART
	32bit register CTRLA
		1 bit swrst
		1 bit enable
		3 bit mode
		2 skip-bit
		1 bit runstdby
		1 bit ibon
		1 bit txinv
		1 bit rxinv
		2 skip-bit
		3 bit sampr
		2 bit txpo
		2 skip-bit
		2 bit rxpo
		2 bit sampa
		4 bit form
		1 bit cmode
		1 bit cpol
		1 bit dord
	end-register
	32bit register CTRLB
		3 bit chsize
		3 skip-bit
		1 bit sbmode
		1 skip-bit
		1 bit colden
		1 bit sfde
		1 bit enc
		2 skip-bit
		1 bit pmode
		2 skip-bit
		1 bit txen
		1 bit rxen
		6 skip-bit
		2 bit lincmd
	end-register
	32bit register CTRLC
		3 bit gtime
		5 skip-bit
		2 bit brklen
		2 bit hdrdly
		4 skip-bit
		1 bit inack
		1 bit dsnak
		2 skip-bit
		3 bit maxiter
		1 skip-bit
		2 bit data32b
	end-register
	16bit register BAUD
		13 bit baud
		3 bit frac
	end-register
	8bit register rxpl
	end-register
	5 skip-byte
	8bit register ITENCLR
		1 bit dre
		1 bit txc
		1 bit rxc
		1 bit rxs
		1 bit ctsic
		1 bit rxbrk
		1 skip-bit
		1 bit error
	end-register
	1 skip-byte
	8bit register ITENSET
		1 bit dre
		1 bit txc
		1 bit rxc
		1 bit rxs
		1 bit ctsic
		1 bit rxbrk
		1 skip-bit
		1 bit error
	end-register
	1 skip-byte
	8bit register INTFLAG
		1 bit dre
		1 bit txc
		1 bit rxc
		1 bit rxs
		1 bit ctsic
		1 bit rxbrk
		1 skip-bit
		1 bit error
	end-register
	1 skip-byte
	16bit register STATUS
		1 bit perr
		1 bit ferr
		1 bit bufovf
		1 bit cts
		1 bit isf
		1 bit coll
		1 bit txe
		1 bit iter
	end-register
	32bit register SYNCBUSY
		1 bit swrst
		1 bit enable
		1 bit ctrlb
		1 bit rxerrcnt
		1 bit length
	end-register
	8bit register RXERRCNT
	end-register
	1 skip-byte
	16bit register LENGTH
		8 bit len
		2 bit lenen
	end-register
	4 skip-byte
	32bit register DATA
		8 bit byte
	end-register
	4 skip-byte
end-register-bank

