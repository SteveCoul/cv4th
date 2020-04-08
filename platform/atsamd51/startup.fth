
require platform/atsamd51/nvmctrl.fth
require platform/atsamd51/gclk.fth
require platform/atsamd51/mclk.fth
require platform/atsamd51/oscctrl.fth
require platform/atsamd51/supc.fth
require platform/atsamd51/cmcc.fth

ext-wordlist forth-wordlist 2 set-order

private-namespace

: mychipstart

  0 NVMCTRL.CTRLA.rws!
  \ TODO enable externals OSC at 32Khz, set it as source for GCLK 3 ( which will be slow clock for I2C )
  
  1 GCLK.CTRLA.swrst!
  begin GCLK.SYNCBUSY.swrst@ 0= until

  \ Main clock(0) sourced by internal 32k oscillator for a bit whilst we configure a faster clock
  GCLK_GENCTRL_SRC_OSCULP32K 0 GCLK.GENCTRLn.src!
  1 0 GCLK.GENCTRLn.oe!
  1 0 GCLK.GENCTRLn.genen!
  begin GCLK.SYNCBUSY.genctrl0@ 0= until

  \ DFLL to 48Mhz
  0 OSCCTRL.DFLLCTRLA.reg!
  1 OSCCTRL.DFLLMUL.cstep!
  1 OSCCTRL.DFLLMUL.fstep!
  0 OSCCTRL.DFLLMUL.mul!
  begin OSCCTRL.DFLLSYNC.dfllmul@ 0= until

  0 OSCCTRL.DFLLCTRLA.reg!
  begin OSCCTRL.DFLLSYNC.dfllctrlb@ 0= until

  1 OSCCTRL.DFLLCTRLA.enable!
  begin OSCCTRL.DFLLSYNC.enable@ 0= until

  OSCCTRL.DFLLVAL.reg@ OSCCTRL.DFLLVAL.reg!
  begin OSCCTRL.DFLLSYNC.dfllval@ 0= until
		
  1 OSCCTRL.DFLLCTRLB.waitlock!
  1 OSCCTRL.DFLLCTRLB.ccdis!
  1 OSCCTRL.DFLLCTRLB.usbcrm!

  begin OSCCTRL.STATUS.dfllrdy@ until

  \ Main clock(0) over to DFLL to speed things up whilst I configure the faster clocks
  \ Just doing the DFLL configu above takes a bloody long time on a 32Khz clock using
  \ interpreted FORTH :-) 
  GCLK_GENCTRL_SRC_DFLL 0 GCLK.GENCTRLn.src!
  1 0 GCLK.GENCTRLn.oe!
  1 0 GCLK.GENCTRLn.genen!
  begin GCLK.SYNCBUSY.genctrl0@ 0= until

  \ Clock 1 to 48Mhz based on DFLL
  GCLK_GENCTRL_SRC_DFLL 1 GCLK.GENCTRLn.src!
  1 1 GCLK.GENCTRLn.genen!
  begin GCLK.SYNCBUSY.genctrl1@ 0= until

  \ Clock 5 to 1Mhz ( DFLL / 48 )
  GCLK_GENCTRL_SRC_DFLL 5 GCLK.GENCTRLn.src!
  48 5 GCLK.GENCTRLn.div!
  1 5 GCLK.GENCTRLn.genen!
  begin GCLK.SYNCBUSY.genctrl1@ 0= until

  \ PLL0 to 120Mhz
  5 OSCCTRL_GCLK_ID_FDPLL0 GCLK.PCHCTRLn.gen!		\ clock 5 is source
  1 OSCCTRL_GCLK_ID_FDPLL0 GCLK.PCHCTRLn.chen!
  0 OSCCTRL.DPLL0RATIO.ldrfrac!
  119 OSCCTRL.DPLL0RATIO.ldr!
  begin OSCCTRL.DPLL0SYNCBUSY.dpllratio@ 0= until
  0 OSCCTRL.DPLL0CTRLB.refclk!
  1 OSCCTRL.DPLL0CTRLB.lbypass!
  0 OSCCTRL.DPLL0CTRLA.ondemand!
  1 OSCCTRL.DPLL0CTRLA.enable!
  begin OSCCTRL.DPLL0STATUS.clkrdy@ OSCCTRL.DPLL0STATUS.lock@ and until

  \ PLL1 to 100Mhz
  5 OSCCTRL_GCLK_ID_FDPLL1 GCLK.PCHCTRLn.gen!		\ clock 5 is source
  1 OSCCTRL_GCLK_ID_FDPLL1 GCLK.PCHCTRLn.chen!
  0 OSCCTRL.DPLL1RATIO.ldrfrac!
  99 OSCCTRL.DPLL1RATIO.ldr!
  begin OSCCTRL.DPLL1SYNCBUSY.dpllratio@ 0= until
  0 OSCCTRL.DPLL1CTRLB.refclk!
  1 OSCCTRL.DPLL1CTRLB.lbypass!
   0 OSCCTRL.DPLL1CTRLA.ondemand!
  1 OSCCTRL.DPLL1CTRLA.enable!
  begin OSCCTRL.DPLL1STATUS.clkrdy@ OSCCTRL.DPLL1STATUS.lock@ and until

  \ Switch main clock to 120Mhz
  GCLK_GENCTRL_SRC_DPLL0 0 GCLK.GENCTRLn.src!
  1 0 GCLK.GENCTRLn.oe!
  1 0 GCLK.GENCTRLn.genen!
  begin GCLK.SYNCBUSY.genctrl0@ 0= until

  \ CPU divider
  MCLK_CPUDIV_DIV_DIV1 MCLK.CPUDIV.reg!

  \ LDO
  0 SUPC.VREG.sel!

  \ CACHE
	( todo disable irqs )
  1 CMCC.CTRL.cen!
	( todo enable irqs )
;

open-namespace platform/atsamd51/atsamd51j20a.fth

' mychipstart is (chipstartup)


