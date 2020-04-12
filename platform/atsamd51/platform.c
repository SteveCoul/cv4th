#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <sam.h>
#include "platform.h"

/* ************************************************************************** *
 *
 * ************************************************************************** */

#define ALIGNED __attribute__((aligned(4)))
#define MIN( a, b ) ( (a) < (b) ) ? (a) : (b)

/* ************************************************************************** *
 *
 * ************************************************************************** */

static void LEDon( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTSET.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTSET.reg |= ( 1 << 15 );
}

static void LEDoff( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTCLR.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTCLR.reg |= ( 1 << 15 );
}

/*
static void LEDtoggle( void ) {
  PORT->Group[0].DIRSET.reg |= ( 1 << 17 );
  PORT->Group[0].OUTTGL.reg |= ( 1 << 17 );
  PORT->Group[0].DIRSET.reg |= ( 1 << 15 );
  PORT->Group[0].OUTTGL.reg |= ( 1 << 15 );
}
*/

#define WAIT 500000
//#define WAIT 100000

static void wait( int l ) { for ( int i = 0; i < (l*WAIT); i++ ) i = i; }
static void dot( void ) { LEDoff(); wait(1); LEDon(); wait(1); LEDoff(); wait(1); }
static void dash( void ) { LEDoff(); wait(1); LEDon(); wait(3); LEDoff(); wait(1); }
static void hacf( void ) { for(;;) { wait(6); dot(); dot(); dot(); dash(); dash(); dash(); dot(); dot(); dot(); } }
/* ************************************************************************** *
 *
 * ************************************************************************** */

int platform_init( void ) {
	return 0;
}

void platform_term( void ) {
}

void platform_write_term( char c ) {
}

int platform_read_term( void ) {
	return -1;
}

/* ************************************************************************** *
 *
 * ************************************************************************** */

extern uint32_t __etext;
extern uint32_t __data_start__;
extern uint32_t __data_end__;
extern uint32_t __bss_start__;
extern uint32_t __bss_end__;
extern uint32_t __StackTop;

extern int main( int argc, char** argv );

void Reset_Handler(void) {
	uint32_t *pSrc, *pDest;

  	pSrc = &__etext;
  	pDest = &__data_start__;

  	if ((&__data_start__ != &__data_end__) && (pSrc != pDest)) {
    	for (; pDest < &__data_end__; pDest++, pSrc++)
      		*pDest = *pSrc;
  	}

  	if ((&__data_start__ != &__data_end__) && (pSrc != pDest)) {
    	for (pDest = &__bss_start__; pDest < &__bss_end__; pDest++)
      		*pDest = 0;
  	}
	main( 1, NULL );
}

/* ************************************************************************** *
 *
 * ************************************************************************** */

typedef void(*vfunc)(void);

__attribute__ ((section(".isr_vector"))) vfunc const exception_table[]  = {
	(vfunc)(&__StackTop), Reset_Handler, hacf, hacf, hacf, hacf,
	hacf, NULL, NULL, NULL, NULL, hacf, hacf, NULL, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, NULL, hacf, hacf, hacf, hacf, hacf,
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, NULL, NULL, hacf, hacf, hacf, hacf, NULL, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf,
	hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, hacf, 
	hacf, hacf, hacf };

