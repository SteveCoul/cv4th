
require extra/register.fth

ext-wordlist get-order 1+ set-order
ext-wordlist set-current

0x41004000 register-bank NVMCTRL
	16bit register CTRLA
		2 skip-bit
		1 bit autows
		1 bit suspen
		2 bit wmode
		2 bit prm
		3 bit rws
		1 bit ahbns0
		1 bit ahbns1
		1 bit cachedis0
		1 bit cachedis1
	end-register
	2 skip-byte
	16bit register CTRLB
		7 bit cmd
		1 skip-bit
		8 bit cmdex
	end-register
	2 skip-byte
	32bit register PARAM
		16 bit nvmp
		3 bit psz
		12 skip-bit
		1 bit see
	end-register
	16bit register INTENCLR
		1 bit done
		1 bit addre
		1 bit proge
		1 bit locke
		1 bit eccse
		1 bit eccde
		1 bit nvme
		1 bit susp
		1 bit seesfull
		1 bit seesovf
		1 bit seewrc
	end-register
	16bit register INTENSET
		1 bit done
		1 bit addre
		1 bit proge
		1 bit locke
		1 bit eccse
		1 bit eccde
		1 bit nvme
		1 bit susp
		1 bit seesfull
		1 bit seesovf
		1 bit seewrc
	end-register
	16bit register INTFLAG
		1 bit done
		1 bit addre
		1 bit proge
		1 bit locke
		1 bit eccse
		1 bit eccde
		1 bit nvme
		1 bit susp
		1 bit seesfull
		1 bit seesovf
		1 bit seewrc
	end-register
	16bit register STATUS
		1 bit ready
		1 bit prm
		1 bit load
		1 bit susp
		1 bit afirst
		1 bit bpdis
		2 skip-bit
		4 bit bootprot
	end-register
	32bit register ADDR
		24 bit addr
	end-register
	32bit register RUNLOCK
	end-register
	32bit register PBLDATAn0
	end-register
	32bit register PBLDATAn1
	end-register
	32bit register ECCERR
		24 bit addr
		4 skip-bit
		2 bit typel
		2 bit typeh
	end-register
	8bit register DBGCTRL
		1 bit eccdis
		1 bit eccelog
	end-register
	1 skip-byte
	8bit register SEECFG
		1 bit wmode
		1 bit aprdis
	end-register
	1 skip-byte
	32bit register SEESTAT	
		1 bit asees
		1 bit load
		1 bit busy
		1 bit lock
		1 bit rlock
		3 skip-bit
		4 bit sblk
		4 skip-bit
		3 bit psz
	end-register
end-register-bank

0x0000A500 constant NVMCTRL_CTRLB_CMDEX_KEY
0x00000001 constant NVMCTRL_CTRLB_CMD_EB
0x00000015 constant NVMCTRL_CTRLB_CMD_PBC

only forth definitions

