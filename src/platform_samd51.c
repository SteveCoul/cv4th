#include <stddef.h>
#include <stdint.h>

extern uint32_t __etext;
extern uint32_t __data_start__;
extern uint32_t __data_end__;
extern uint32_t __bss_start__;
extern uint32_t __bss_end__;
extern uint32_t __StackTop;

extern "C" int main( int argc, char** argv );
extern "C" void Reset_Handler( void );

#define PIN 0x20000
//#define PIN 0x8000

void wait( void ) {
	for ( int i = 0; i < 1000000; i++ ) i = i;
}

void ioclock( void ) { ((uint32_t*)0x40021014)[0] = 0x20000;}
void makeOutput( void ) { ((uint32_t*)0x41008008)[0] = PIN;}
void setHigh( void )  { ((uint32_t*)0x41008018)[0] = PIN;}
void setLow( void )  { ((uint32_t*)0x41008014)[0] = PIN;}

void Reset_Handler(void)
{
  uint32_t *pSrc, *pDest;

  /* Initialize the initialized data section */
  pSrc = &__etext;
  pDest = &__data_start__;

  if ((&__data_start__ != &__data_end__) && (pSrc != pDest)) {
    for (; pDest < &__data_end__; pDest++, pSrc++)
      *pDest = *pSrc;
  }

  /* Clear the zero section */
  if ((&__data_start__ != &__data_end__) && (pSrc != pDest)) {
    for (pDest = &__bss_start__; pDest < &__bss_end__; pDest++)
      *pDest = 0;
  }

#if defined(__FPU_USED) && defined(__SAMD51__)
	/* Enable FPU */
	SCB->CPACR |= (0xFu << 20);
	__DSB();
	__ISB();
#endif

	ioclock();
	makeOutput();

	main( 1, NULL );
	for (;;)
	{
		wait();
		setHigh();
		wait();
		setLow();
	}
}

void isr_NMI( void ) { }
void isr_HardFault( void ) { }
void isr_MemManage( void ) { }
void isr_BusFault( void ) { }
void isr_UsageFault( void ) { }
void isr_SVC( void ) { }
void isr_DebugMon( void ) { }
void isr_PendSV( void ) { }
void isr_SysTick( void ) { }
void isr_PM( void ) { }
void isr_MCLK( void ) { }
void isr_OSCCTRL_0( void ) { }
void isr_OSCCTRL_1( void ) { }
void isr_OSCCTRL_2( void ) { }
void isr_OSCCTRL_3( void ) { }
void isr_OSCCTRL_4( void ) { }
void isr_OSC32KCTRL( void ) { }
void isr_SUPC_0( void ) { }
void isr_SUPC_1( void ) { }
void isr_WDT( void ) { }
void isr_RTC( void ) { }
void isr_EIC_0( void ) { }
void isr_EIC_1( void ) { }
void isr_EIC_2( void ) { }
void isr_EIC_3( void ) { }
void isr_EIC_4( void ) { }
void isr_EIC_5( void ) { }
void isr_EIC_6( void ) { }
void isr_EIC_7( void ) { }
void isr_EIC_8( void ) { }
void isr_EIC_9( void ) { }
void isr_EIC_10( void ) { }
void isr_EIC_11( void ) { }
void isr_EIC_12( void ) { }
void isr_EIC_13( void ) { }
void isr_EIC_14( void ) { }
void isr_EIC_15( void ) { }
void isr_FREQM( void ) { }
void isr_NVMCTRL_0( void ) { }
void isr_NVMCTRL_1( void ) { }
void isr_DMAC_0( void ) { }
void isr_DMAC_1( void ) { }
void isr_DMAC_2( void ) { }
void isr_DMAC_3( void ) { }
void isr_DMAC_4( void ) { }
void isr_EVSYS_0( void ) { }
void isr_EVSYS_1( void ) { }
void isr_EVSYS_2( void ) { }
void isr_EVSYS_3( void ) { }
void isr_EVSYS_4( void ) { }
void isr_PAC( void ) { }
void isr_TAL_0( void ) { }
void isr_TAL_1( void ) { }
void isr_RAMECC( void ) { }
void isr_SERCOM0_0( void ) { }
void isr_SERCOM0_1( void ) { }
void isr_SERCOM0_2( void ) { }
void isr_SERCOM0_3( void ) { }
void isr_SERCOM1_0( void ) { }
void isr_SERCOM1_1( void ) { }
void isr_SERCOM1_2( void ) { }
void isr_SERCOM1_3( void ) { }
void isr_SERCOM2_0( void ) { }
void isr_SERCOM2_1( void ) { }
void isr_SERCOM2_2( void ) { }
void isr_SERCOM2_3( void ) { }
void isr_SERCOM3_0( void ) { }
void isr_SERCOM3_1( void ) { }
void isr_SERCOM3_2( void ) { }
void isr_SERCOM3_3( void ) { }
void isr_SERCOM4_0( void ) { }
void isr_SERCOM4_1( void ) { }
void isr_SERCOM4_2( void ) { }
void isr_SERCOM4_3( void ) { }
void isr_SERCOM5_0( void ) { }
void isr_SERCOM5_1( void ) { }
void isr_SERCOM5_2( void ) { }
void isr_SERCOM5_3( void ) { }
void isr_SERCOM6_0( void ) { }
void isr_SERCOM6_1( void ) { }
void isr_SERCOM6_2( void ) { }
void isr_SERCOM6_3( void ) { }
void isr_SERCOM7_0( void ) { }
void isr_SERCOM7_1( void ) { }
void isr_SERCOM7_2( void ) { }
void isr_SERCOM7_3( void ) { }
void isr_USB_0( void ) { }
void isr_USB_1( void ) { }
void isr_USB_2( void ) { }
void isr_USB_3( void ) { }
void isr_TCC0_0( void ) { }
void isr_TCC0_1( void ) { }
void isr_TCC0_2( void ) { }
void isr_TCC0_3( void ) { }
void isr_TCC0_4( void ) { }
void isr_TCC0_5( void ) { }
void isr_TCC0_6( void ) { }
void isr_TCC1_0( void ) { }
void isr_TCC1_1( void ) { }
void isr_TCC1_2( void ) { }
void isr_TCC1_3( void ) { }
void isr_TCC1_4( void ) { }
void isr_TCC2_0( void ) { }
void isr_TCC2_1( void ) { }
void isr_TCC2_2( void ) { }
void isr_TCC2_3( void ) { }
void isr_TCC3_0( void ) { }
void isr_TCC3_1( void ) { }
void isr_TCC3_2( void ) { }
void isr_TCC4_0( void )  { }
void isr_TCC4_1( void )  { }
void isr_TCC4_2( void )  { }
void isr_TC0( void )  { }
void isr_TC1( void )  { }
void isr_TC2( void )  { }
void isr_TC3( void )  { }
void isr_TC4( void )  { }
void isr_TC5( void )  { }
void isr_TC6( void )  { }
void isr_TC7( void )  { }
void isr_PDEC_0( void )  { }
void isr_PDEC_1( void )  { }
void isr_PDEC_2( void )  { }
void isr_ADC0_0( void )  { }
void isr_ADC0_1( void )  { }
void isr_ADC1_0( void )  { }
void isr_ADC1_1( void )  { }
void isr_AC( void )  { }
void isr_DAC_0( void )  { }
void isr_DAC_1( void )  { }
void isr_DAC_2( void )  { }
void isr_DAC_3( void )  { }
void isr_DAC_4( void )  { }
void isr_I2S( void )  { }
void isr_PCC( void )  { }
void isr_AES( void )  { }
void isr_TRNG( void )  { }
void isr_ICM( void )  { }
void isr_PUKCC( void )  { }
void isr_QSPI( void )  { }
void isr_SDHC0( void )  { }
void isr_SDHC1( void )  { }

__attribute__ ((section(".isr_vector"))) const void* exception_table[] = {
	(&__StackTop), Reset_Handler, isr_NMI, isr_HardFault, isr_MemManage, isr_BusFault,
	isr_UsageFault, NULL, NULL, NULL, NULL, isr_SVC, isr_DebugMon, NULL, isr_PendSV,
	isr_SysTick, isr_PM, isr_MCLK, isr_OSCCTRL_0, isr_OSCCTRL_1, isr_OSCCTRL_2, 
	isr_OSCCTRL_3, isr_OSCCTRL_4, isr_OSC32KCTRL, isr_SUPC_0, isr_SUPC_1, isr_WDT,
	isr_RTC, isr_EIC_0, isr_EIC_1, isr_EIC_2, isr_EIC_3, isr_EIC_4, isr_EIC_5,
	isr_EIC_6, isr_EIC_7, isr_EIC_8, isr_EIC_9, isr_EIC_10, isr_EIC_11, isr_EIC_12,
	isr_EIC_13, isr_EIC_14, isr_EIC_15, isr_FREQM, isr_NVMCTRL_0, isr_NVMCTRL_1, 
	isr_DMAC_0, isr_DMAC_1, isr_DMAC_2, isr_DMAC_3, isr_DMAC_4, isr_EVSYS_0,
	isr_EVSYS_1, isr_EVSYS_2, isr_EVSYS_3, isr_EVSYS_4, isr_PAC, isr_TAL_0, isr_TAL_1,
	NULL, isr_RAMECC, isr_SERCOM0_0, isr_SERCOM0_1, isr_SERCOM0_2, isr_SERCOM0_3,
	isr_SERCOM1_0, isr_SERCOM1_1, isr_SERCOM1_2, isr_SERCOM1_3, isr_SERCOM2_0,
	isr_SERCOM2_1, isr_SERCOM2_2, isr_SERCOM2_3, isr_SERCOM3_0, isr_SERCOM3_1,
	isr_SERCOM3_2, isr_SERCOM3_3, isr_SERCOM4_0, isr_SERCOM4_1, isr_SERCOM4_2,
	isr_SERCOM4_3, isr_SERCOM5_0, isr_SERCOM5_1, isr_SERCOM5_2, isr_SERCOM5_3,
	isr_SERCOM6_0, isr_SERCOM6_1, isr_SERCOM6_2, isr_SERCOM6_3, isr_SERCOM7_0,
	isr_SERCOM7_1, isr_SERCOM7_2, isr_SERCOM7_3, NULL, NULL, isr_USB_0, isr_USB_1,
	isr_USB_2, isr_USB_3, NULL, isr_TCC0_0, isr_TCC0_1, isr_TCC0_2, isr_TCC0_3,
	isr_TCC0_4, isr_TCC0_5, isr_TCC0_6, isr_TCC1_0, isr_TCC1_1, isr_TCC1_2, 
	isr_TCC1_3, isr_TCC1_4, isr_TCC2_0, isr_TCC2_1, isr_TCC2_2, isr_TCC2_3,
	isr_TCC3_0, isr_TCC3_1, isr_TCC3_2, isr_TCC4_0, isr_TCC4_1, isr_TCC4_2, isr_TC0,
	isr_TC1, isr_TC2, isr_TC3, isr_TC4, isr_TC5, isr_TC6, isr_TC7, isr_PDEC_0, 
	isr_PDEC_1, isr_PDEC_2, isr_ADC0_0, isr_ADC0_1, isr_ADC1_0, isr_ADC1_1,
	isr_AC, isr_DAC_0, isr_DAC_1, isr_DAC_2, isr_DAC_3, isr_DAC_4, isr_I2S,
	isr_PCC, isr_AES, isr_TRNG, isr_ICM, isr_PUKCC, isr_QSPI, isr_SDHC0, isr_SDHC1 };


#include "platform.h"

int platform_read_term( void ) {
	return -1;
}

void platform_write_term( char c ) {
}

int platform_init( void ) {
	return 0;
}

void platform_term( void ) {
}

