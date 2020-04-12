
require extra/register.fth
require kernel/structure.fth

forth-wordlist ext-wordlist 2 set-order definitions

0x41000000 register-bank UsbHost
	8bit register CTRLA
		1 bit swrst
		1 bit enable
		1 bit runstdby
		4 skip-bit
		1 bit mode
	end-register
	1 skip-byte
	8bit register SYNCBUSY
		1 bit swrst
		1 bit enable
	end-register
	8bit register QOSCTRL
		2 bit cqos
		2 bit dqos
	end-register
	4 skip-byte
	16bit register CTRLB
		1 skip-bit
		1 bit resume
		2 bit spdconf
		1 skip-bit
		1 bit tstj
		1 bit tstk
		1 skip-bit
		1 bit sofe
		1 bit busreset
		1 bit vbusok
		1 bit l1resume
	end-register
	8bit register HSOFC
		4 bit flenc
		3 skip-bit
		1 bit flence
	end-register
	1 skip-byte
	8bit register STATUS
		2 skip-bit
		2 bit speed
		2 skip-bit
		2 bit linestate
	end-register
	8bit register FSMSTATUS
	end-register
	2 skip-byte
	16bit register FNUM
		3 skip-bit
		11 bit fnum
	end-register
	8bit register FLENHIGH
	end-register
	1 skip-byte
	16bit register INTENCLR
		2 skip-bit
		1 bit hsof
		1 bit rst
		1 bit wakeup
		1 bit dnrsm
		1 bit uprsm
		1 bit ramacer
		1 bit dconn
		1 bit ddisc
	end-register
	2 skip-byte
	16bit register INTENSET
		2 skip-bit
		1 bit hsof
		1 bit rst
		1 bit wakeup
		1 bit dnrsm
		1 bit uprsm
		1 bit ramacer
		1 bit dconn
		1 bit ddisc
	end-register
	2 skip-byte
	16bit register INTFLAG
		2 skip-bit
		1 bit hsof
		1 bit rst
		1 bit wakeup
		1 bit dnrsm
		1 bit uprsm
		1 bit ramacer
		1 bit dconn
		1 bit ddisc
	end-register
	2 skip-byte
	16bit register PINTSMRY
	end-register
	2 skip-byte
	32bit register DESCADD
	end-register
	16bit register PADCAL
		5 bit transp
		1 skip-bit
		5 bit transn
		1 skip-bit
		3 bit trim
	end-register
	\ At this point there are 8 Host Pipe structures. I don't have the
	\ ability to embed structure definitions in register bank definitions
	\ and I don't need these anyhow atm.
end-register-bank

0x41000000 register-bank UsbDevice
	8bit register CTRLA			\ 0x00
		1 bit swrst
		1 bit enable
		1 bit runstdby
		4 skip-bit
		1 bit mode
	end-register
	1 skip-byte
	8bit register SYNCBUSY		\ 0x02
		1 bit swrst
		1 bit enable
	end-register
	8bit register QOSCTRL		\ 0x03
		2 bit cqos
		2 bit dqos
	end-register
	4 skip-byte
	16bit register CTRLB		\ 0x08
		1 bit detach
		1 bit uprsm
		2 bit spdconf
		1 bit nreply
		4 skip-bit
		1 bit gnak
		2 bit lpmhdsk
  	end-register
	8bit register DADD			\ 0x0A
		7 bit dadd
		1 bit adden
	end-register
	1 skip-byte
	8bit register STATUS		\ 0x0C
		2 skip-bit
		2 bit speed
		2 skip-bit
		2 bit linestate
	end-register
	8bit register FSMSTATUS		\ 0x0D
	end-register
	2 skip-byte		
	16bit register FNUM			\ 0x10
		3 skip-bit
		11 bit fnum
		1 skip-bit
		1 bit fncerr
	end-register
	2 skip-byte
	16bit register INTENCLR		\ 0x14
		1 bit suspend
		1 skip-bit
		1 bit sof
		1 bit eorst
		1 bit wakeup
		1 bit eorsm
		1 bit uprsm
		1 bit ramacer
		1 bit lpmnyet
		1 bit lpmsusp
	end-register
	2 skip-byte
	16bit register INTENSET		\ 0x18
		1 bit suspend
		1 skip-bit
		1 bit sof
		1 bit eorst
		1 bit wakeup
		1 bit eorsm
		1 bit uprsm
		1 bit ramacer
		1 bit lpmnyet
		1 bit lpmsusp
	end-register
	2 skip-byte
	16bit register INTFLAG		\ 0x1C
		1 bit suspend
		1 skip-bit
		1 bit sof
		1 bit eorst
		1 bit wakeup
		1 bit eorsm
		1 bit uprsm
		1 bit ramacer
		1 bit lpmnyet
		1 bit lpmsusp
	end-register
	2 skip-byte
	16bit register EPINTSMRY	\ 0x20
	end-register
	2 skip-byte
	32bit register DESCADD		\ 0x24
	end-register
	16bit register PADCAL		\ 0x28
		5 bit transp
		1 skip-bit
		5 bit transn
		1 skip-bit
		3 bit trim
	end-register
	214 skip-byte
	\ and here at 0x100 are the device endpoint structures which I cannot embed into 
	\ register bansk atm. So I define the first 4 of 8 seperately below. I don't need
	\ all 8
end-register-bank

0x41000100 register-bank USBDevice_DeviceEndPoint0
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

0x41000120 register-bank USBDevice_DeviceEndPoint1
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

0x41000140 register-bank USBDevice_DeviceEndPoint2
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

0x41000160 register-bank USBDevice_DeviceEndPoint3
	8bit register EPCFG
		2 bit eptype0
		2 bit eptype1
	end-register
	3 skip-byte
	8bit register EPSTATUSCLR
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUSSET
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPSTATUS
		1 bit dtlgout
		1 bit dtglin
		1 bit curbk
		1 skip-bit
		1 bit stallrq0
		1 bit stallrq1
		1 bit bk0rdy
		1 bit bk1rdy
	end-register
	8bit register EPINTFLAG
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTCLR
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	8bit register EPINTSET
		1 bit trcpt0
		1 bit trcpt1
		1 bit trfail0
		1 bit trfail1
		1 bit rxstp
		1 bit stall0
		1 bit stall1
	end-register
	22 skip-byte
end-register-bank

begin-structure UsbDeviceDescBank
	4 +field uddb.addr
	4 +field uddb.pcksize		\	1:autozlp 3:size 14:multi-size 14:byte_count
	2 +field uddb.extreg
	1 +field uddb.status_bk
	5 +field uddb.reserved
end-structure

begin-structure UsbDeviceDescriptor
	UsbDeviceDescBank +field DeviceDescBank0
	UsbDeviceDescBank +field DeviceDescBank1
end-structure

